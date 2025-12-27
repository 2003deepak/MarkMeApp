import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/teacher_request_model.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/swap_confirmation_alert.dart';
import 'package:intl/intl.dart';

class RequestDetailsPage extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailsPage({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends ConsumerState<RequestDetailsPage> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  TeacherRequestDetail? _requestDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRequestDetail();
    });
  }

  Future<void> _fetchRequestDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(teacherRepositoryProvider);
      final response = await repo.fetchRequestDetail(widget.requestId);

      if (response['success'] == true) {
        setState(() {
          _requestDetail = TeacherRequestDetail.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSwapAction(String action) async {
    if (_requestDetail == null || _requestDetail!.swap == null) return;

    // Show confirmation for approval
    if (action == 'APPROVE') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => SwapConfirmationAlert(
          onConfirm: () => context.pop(true),
          onCancel: () => context.pop(false),
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isActionLoading = true);

    try {
      final repo = ref.read(teacherRepositoryProvider);
      final result = await repo.respondToSwap(
        swapId: _requestDetail!.swap!.swapId,
        action: action,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Swap ${action == 'APPROVE' ? 'approved' : 'rejected'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Action failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: MarkMeAppBar(
        title: 'Request Details',
        onBackPressed: () => context.pop(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_requestDetail == null) {
      return const Center(child: Text("Request not found"));
    }

    final request = _requestDetail!;
    final bool showActions = request.canTakeAction;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(request),
              const SizedBox(height: 24),
              _buildInfoCard(
                title: "Session Information",
                children: [
                  _buildInfoRow(
                    Icons.book,
                    "Subject",
                    request.subject.subjectName,
                  ),
                  _buildInfoRow(
                    Icons.category,
                    "Component",
                    request.subject.component,
                  ),
                  _buildInfoRow(
                    Icons.event,
                    "Date",
                    request.date.toString().split(' ')[0],
                  ),
                  _buildInfoRow(
                    Icons.access_time,
                    "Time",
                    "${request.startTime} - ${request.endTime}",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: "Request Details",
                children: [
                  _buildInfoRow(Icons.label, "Type", request.requestType),
                  _buildInfoRow(Icons.notes, "Reason", request.reason),
                  _buildInfoRow(
                    Icons.history,
                    "Created At",
                    DateFormat('MMM d, y HH:mm').format(request.createdAt),
                  ),
                  _buildInfoRow(
                    Icons.person,
                    "Created By",
                    request.createdBy.name,
                  ),
                ],
              ),
              if (request.swap != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: "Swap Information",
                  children: [
                    _buildInfoRow(
                      Icons.person,
                      "Requested By",
                      request.swap!.requestedBy.name,
                    ),
                    if (request.swap!.approvedBy != null)
                      _buildInfoRow(
                        Icons.check_circle_outline,
                        "Approved By",
                        request.swap!.approvedBy!.name,
                      ),

                    _buildInfoRow(Icons.info, "Status", request.swap!.status),

                    if (request.swap!.respondedAt != null)
                      _buildInfoRow(
                        Icons.done_all,
                        "Responded At",
                        DateFormat(
                          'MMM d, y HH:mm',
                        ).format(request.swap!.respondedAt!),
                      ),
                  ],
                ),
              ],

              if (showActions) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isActionLoading
                            ? null
                            : () => _handleSwapAction('REJECT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isActionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Reject Request"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isActionLoading
                            ? null
                            : () => _handleSwapAction('APPROVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isActionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Approve Request"),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
        if (_isActionLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(TeacherRequestDetail request) {
    String status = 'Approved';
    Color color = Colors.green;

    if (request.swap != null) {
      status = request.swap!.status; // PENDING, APPROVED, REJECTED
      if (status == 'PENDING') color = Colors.orange;
      if (status == 'REJECTED') color = Colors.red;
    } else {
      status = request.status;
      if (status == 'PENDING') color = Colors.orange;
      if (status == 'REJECTED') color = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            status == 'APPROVED'
                ? Icons.check_circle_outline
                : status == 'REJECTED'
                ? Icons.highlight_off
                : Icons.access_time,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
