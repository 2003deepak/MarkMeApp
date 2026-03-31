import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/admin_state.dart';

class ClerkDetailsPage extends ConsumerStatefulWidget {
  final String clerkId;

  const ClerkDetailsPage({super.key, required this.clerkId});

  @override
  ConsumerState<ClerkDetailsPage> createState() => _ClerkDetailsPageState();
}

class _ClerkDetailsPageState extends ConsumerState<ClerkDetailsPage> {
  late final AdminRepository _adminRepo;
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  
  Map<String, dynamic>? _clerkData;
  List<Map<String, String>> _currentScopes = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _adminRepo = ref.read(adminRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _adminRepo.fetchClerkDetails(widget.clerkId);
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _clerkData = data;
          _isLoading = false;
          _currentScopes = [];
          if (data['academic_scopes'] != null) {
            final List scopes = data['academic_scopes'];
            for (var scope in scopes) {
              _currentScopes.add({
                'program_id': scope['program_id'].toString(),
                'department_id': scope['department_id'].toString(),
              });
            }
          }
          _hasChanges = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Failed to load details';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _saveScopes() async {
    setState(() => _isSaving = true);
    try {
      final result = await _adminRepo.updateClerkScopes(widget.clerkId, _currentScopes);
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Academic scopes updated successfully'), backgroundColor: Colors.green),
          );
          setState(() => _hasChanges = false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Update failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removeScope(int index) {
    setState(() {
      _currentScopes.removeAt(index);
      _hasChanges = true;
    });
  }

  void _showAddScopeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddScopeBottomSheet(
          onAdd: (program, department) {
            // Check if already exists
            final exists = _currentScopes.any(
              (s) => s['program_id'] == program && s['department_id'] == department
            );
            if (exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scope already assigned')),
              );
              return;
            }
            setState(() {
              _currentScopes.add({
                'program_id': program,
                'department_id': department,
              });
              _hasChanges = true;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Clerk Profile',
        onBackPressed: () => context.pop(),
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: _hasChanges ? _buildSaveFooter(isDark) : null,
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty && _clerkData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_clerkData == null) {
      return const Center(child: Text('No data found'));
    }

    final clerk = _clerkData!;
    final fullName = '${clerk['first_name']} ${clerk['middle_name'] ?? ''} ${clerk['last_name']}'.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return RefreshIndicator(
      onRefresh: _fetchDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252542) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF3B5BDB).withValues(alpha: 0.1),
                    backgroundImage: clerk['profile_picture'] != null ? NetworkImage(clerk['profile_picture']) : null,
                    child: clerk['profile_picture'] == null ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B5BDB)),
                    ) : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4)
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact Details
            const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252542) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.email_outlined, title: 'Email', value: clerk['email'] ?? 'N/A', isDark: isDark),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.phone_outlined, title: 'Phone', value: clerk['phone']?.toString() ?? 'N/A', isDark: isDark),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.calendar_today_outlined, title: 'Joined', value: clerk['created_at'] != null ? clerk['created_at'].toString().split('T').first : 'N/A', isDark: isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Academic Scopes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Academic Scopes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _showAddScopeBottomSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Scope'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B5BDB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_currentScopes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: isDark ? Colors.white30 : Colors.grey),
                    const SizedBox(height: 12),
                    Text('No academic scopes assigned', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700])),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentScopes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final scope = _currentScopes[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252542) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0CA678).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_tree_outlined, color: Color(0xFF0CA678)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Program: ${scope['program_id']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Department: ${scope['department_id']}',
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeScope(index),
                          tooltip: 'Remove Scope',
                        ),
                      ],
                    ),
                  );
                },
              ),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E36) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveScopes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B5BDB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
                    'Save Scopes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.grey[500]),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _AddScopeBottomSheet extends ConsumerStatefulWidget {
  final Function(String program, String department) onAdd;

  const _AddScopeBottomSheet({required this.onAdd});

  @override
  ConsumerState<_AddScopeBottomSheet> createState() => _AddScopeBottomSheetState();
}

class _AddScopeBottomSheetState extends ConsumerState<_AddScopeBottomSheet> {
  String? _selectedProgram;
  String? _selectedDepartment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminState = ref.watch(adminStoreProvider);
    final metadata = adminState.hierarchyMetadata ?? {};

    final programs = metadata.keys.toList();

    List<String> departments = [];
    if (_selectedProgram != null && metadata[_selectedProgram] != null) {
      if (metadata[_selectedProgram] is Map) {
        departments = (metadata[_selectedProgram] as Map<String, dynamic>).keys.toList();
      }
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Academic Scope', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Program', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedProgram,
            items: programs,
            hint: 'Select a program',
            onChanged: (val) => setState(() {
              _selectedProgram = val;
              _selectedDepartment = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          const Text('Department', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedDepartment,
            items: departments,
            hint: 'Select a department',
            onChanged: (val) => setState(() => _selectedDepartment = val),
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedProgram != null && _selectedDepartment != null)
                  ? () => widget.onAdd(_selectedProgram!, _selectedDepartment!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5BDB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Scope', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])),
          dropdownColor: isDark ? const Color(0xFF252542) : Colors.white,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
