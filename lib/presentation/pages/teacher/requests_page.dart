import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/teacher_request_model.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/presentation/widgets/ui/multi_select_dropdown.dart';

class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({super.key});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TeacherRequestSummary> _allRequestSummaries = [];
  List<TeacherRequestSummary> _filteredRequestSummaries = [];

  // Filter State
  String? _selectedYear; // Defaults to null (All Years)
  List<String> _selectedTypes = []; // 'Created By Me', 'Received'
  List<String> _selectedStatuses = []; // 'Pending', 'Approved', 'Rejected'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRequests();
    });
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(teacherRepositoryProvider);

      String? requestType;
      // Map selection to API constants
      if (_selectedTypes.contains('Created By Me') &&
          !_selectedTypes.contains('Received')) {
        requestType = 'created_by_me';
      } else if (_selectedTypes.contains('Received') &&
          !_selectedTypes.contains('Created By Me')) {
        requestType = 'recieved_to_me';
      }
      // If both or neither are selected, requestType remains null (ALL)

      String? status;
      if (_selectedStatuses.isNotEmpty) {
        status = _selectedStatuses.first.toLowerCase();
      }

      final response = await repo.fetchRequests(
        year: _selectedYear != null ? int.tryParse(_selectedYear!) : null,
        requestType: requestType,
        status: status,
        page: 1,
        limit: 10, // Or higher if needed, fixed to 10 for now as per req
      );

      if (response['success'] == true) {
        final List data = response['data'] ?? [];
        _allRequestSummaries = data
            .map((e) => TeacherRequestSummary.fromJson(e))
            .toList();
        _applyFilters(); // Apply sort logic (Status filtering removed as it is now backend)
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load requests';
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

  void _applyFilters() {
    List<TeacherRequestSummary> temp = List.from(_allRequestSummaries);

    // Filter by Status
    if (_selectedStatuses.isNotEmpty) {
      temp = temp.where((req) {
        String status = req.status;
        return _selectedStatuses.contains(status.toUpperCase()) ||
            // Handle case sensitivity loosely
            _selectedStatuses
                .map((e) => e.toUpperCase())
                .contains(status.toUpperCase());
      }).toList();
    }

    // Sort by Date Descending
    temp.sort((a, b) {
      return b.dateRaised.compareTo(a.dateRaised);
    });

    setState(() {
      _filteredRequestSummaries = temp;
      _isLoading = false;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestsFilterBottomSheet(
        initialYear: _selectedYear,
        initialTypes: _selectedTypes,
        initialStatuses: _selectedStatuses,
        onApply: (year, types, statuses) {
          setState(() {
            _selectedYear = year;
            _selectedTypes = types;
            _selectedStatuses = statuses;
          });
          _fetchRequests(); // Fetch from API with new filters
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: MarkMeAppBar(
        title: 'Requests',
        onBackPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterBottomSheet,
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text('Filter', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildActiveFilterSummary(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRequestSummaries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _filteredRequestSummaries.length,
                      itemBuilder: (context, index) {
                        return _buildRequestCard(
                          _filteredRequestSummaries[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> chips = [];

    if (_selectedYear != null) {
      chips.add(
        FilterChipWidget(
          label: 'Year: $_selectedYear',
          onRemove: () {
            setState(() => _selectedYear = null);
            _fetchRequests();
          },
          isDark: isDark,
        ),
      );
    }

    if (_selectedTypes.isNotEmpty) {
      chips.add(
        FilterChipWidget(
          label:
              'Type: ${_selectedTypes.length > 1 ? "${_selectedTypes.length} selected" : _selectedTypes.first}',
          onRemove: () {
            setState(() => _selectedTypes = []);
            _fetchRequests();
          },
          isDark: isDark,
        ),
      );
    }

    if (_selectedStatuses.isNotEmpty) {
      chips.add(
        FilterChipWidget(
          label:
              'Status: ${_selectedStatuses.length > 1 ? "${_selectedStatuses.length} selected" : _selectedStatuses.first}',
          onRemove: () {
            setState(() => _selectedStatuses = []);
            _applyFilters();
          },
          isDark: isDark,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No requests found",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(TeacherRequestSummary request) {
    bool isReceivedSwap = request.receivedByMe;

    // Status Logic
    String status = request.status;
    Color statusColor = Colors.green;
    if (status == 'PENDING') statusColor = Colors.orange;
    if (status == 'REJECTED') statusColor = Colors.red;

    return GestureDetector(
      onTap: () {
        context.push('/teacher/request/${request.requestId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Action + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.requestType,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Body: Subject & Date
            Text(
              request.subjectName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  "${request.dateRaised.toString().split(' ')[0]}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),

            // Simplified Card - Details are now on next page
            if (isReceivedSwap) ...[
              const SizedBox(height: 8),
              Text(
                "Received Request",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RequestsFilterBottomSheet extends StatefulWidget {
  final String? initialYear;
  final List<String> initialTypes;
  final List<String> initialStatuses;
  final Function(String?, List<String>, List<String>) onApply;

  const RequestsFilterBottomSheet({
    super.key,
    required this.initialYear,
    required this.initialTypes,
    required this.initialStatuses,
    required this.onApply,
  });

  @override
  State<RequestsFilterBottomSheet> createState() =>
      _RequestsFilterBottomSheetState();
}

class _RequestsFilterBottomSheetState extends State<RequestsFilterBottomSheet> {
  String? _year;
  late List<String> _types;
  late List<String> _statuses;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _types = List.from(widget.initialTypes);
    _statuses = List.from(widget.initialStatuses);
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetLayout(
      title: 'Filter Requests',
      onReset: () {
        setState(() {
          _year = null;
          _types = [];
          _statuses = [];
        });
        widget.onApply(null, [], []);
        Navigator.pop(context);
      },
      onApply: () {
        widget.onApply(_year, _types, _statuses);
        Navigator.pop(context);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year Selector (Dropdown)
          const Text(
            "Year",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _year,
                items:
                    List.generate(
                          5,
                          (index) => (DateTime.now().year - index).toString(),
                        )
                        .map(
                          (y) => DropdownMenuItem<String>(
                            value: y,
                            child: Text(y),
                          ),
                        )
                        .toList()
                      ..insert(
                        0,
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Years"),
                        ),
                      ),
                onChanged: (val) {
                  setState(() => _year = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          MultiSelectDropdown<String>(
            label: 'Request Type',
            hint: 'Select Types',
            items: const ['Created By Me', 'Received'],
            selectedValues: _types,
            onChanged: (v) => setState(() => _types = v),
          ),
          const SizedBox(height: 20),

          MultiSelectDropdown<String>(
            label: 'Status',
            hint: 'Select Status',
            items: const ['PENDING', 'APPROVED', 'REJECTED'],
            selectedValues: _statuses,
            onChanged: (v) => setState(() => _statuses = v),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
