import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/clerk_state.dart';

class AddTeacherPage extends ConsumerStatefulWidget {
  const AddTeacherPage({super.key});

  @override
  ConsumerState<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends ConsumerState<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailIdController = TextEditingController();

  // Dynamic subject assignments (list of full subject data)
  final List<Map<String, dynamic>> _subjectAssignments = [];

  // Data from API (parsed to easily display in Bottom Sheet)
  List<Map<String, dynamic>> _assignableGroups = [];
  bool _isLoading = false;
  bool _isFetchingSubjects = false;
  String? _subjectsError;

  // Filters for fetching subjects
  String? _selectedProgram;
  int? _selectedSemester;
  int? _selectedBatch;
  
  // Available filter options (derived from clerk profile or hardcoded for now)
  List<String> _programs = [];
  List<int> _semesters = [];
  List<int> _batches = [];

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state
    _firstNameController.addListener(_updateFormState);
    _lastNameController.addListener(_updateFormState);
    _mobileNumberController.addListener(_updateFormState);
    _emailIdController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _mobileNumberController.text.isNotEmpty &&
        _emailIdController.text.isNotEmpty &&
        _subjectAssignments.isNotEmpty;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileNumberController.clear();
    _emailIdController.clear();
    setState(() {
      _subjectAssignments.clear();
    });
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isFetchingSubjects = true;
      _subjectsError = null;
    });

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);
      final result = await clerkRepo.fetchAssignableSubjects();

      if (result['success'] == true) {
        final groupsData = result['data'] as List<dynamic>;

        setState(() {
          _assignableGroups = groupsData.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _subjectsError = result['error'] ?? 'Unknown error';
        });
      }
    } catch (error) {
      setState(() {
        _subjectsError = error.toString();
      });
    } finally {
      setState(() {
        _isFetchingSubjects = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clerkState = ref.watch(clerkStoreProvider);
    final academicScopes = clerkState.profile?.academicScopes ?? [];

    if (_programs.isEmpty && academicScopes.isNotEmpty) {
      _programs = academicScopes.map((e) => e.programId).toSet().toList();
    }
    if (_semesters.isEmpty) {
      _semesters = [1, 2, 3, 4, 5, 6, 7, 8];
    }
    if (_batches.isEmpty) {
      final currentYear = DateTime.now().year;
      _batches = [currentYear - 2, currentYear - 1, currentYear, currentYear + 1];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Add Teacher',
        onBackPressed: _isLoading ? null : () => context.pop(),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0F2FE),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A3B82F6),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add New Teacher',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enter teacher details and assign subjects',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personal details and contact info',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // First Name
                            InputField(
                              label: "First Name",
                              hintText: "Enter teacher's first name",
                              controller: _firstNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter first name';
                                }
                                if (value.length < 2) {
                                  return 'Must be at least 2 characters';
                                }
                                if (value.length > 50) {
                                  return 'Must be less than 50 characters';
                                }
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return 'Only letters and spaces allowed';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Last Name
                            InputField(
                              label: "Last Name",
                              hintText: "Enter teacher's last name",
                              controller: _lastNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter last name';
                                }
                                if (value.length < 2) {
                                  return 'Must be at least 2 characters';
                                }
                                if (value.length > 50) {
                                  return 'Must be less than 50 characters';
                                }
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return 'Only letters and spaces allowed';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Mobile Number
                            InputField(
                              label: "Mobile Number",
                              hintText: "Enter mobile number",
                              controller: _mobileNumberController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                  return 'Enter a valid 10-digit number';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Email ID
                            InputField(
                              label: "Email ID",
                              hintText: "Enter teacher email",
                              controller: _emailIdController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email ID';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 32),

                            // Subject Assignment Section
                            _buildSubjectAssignmentSection(),

                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveTeacherButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subject Assignment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assign subjects to teacher',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showSubjectSelectionModal,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Select Subject'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isFetchingSubjects) _buildLoadingIndicator(),

        if (_subjectsError != null) _buildErrorWidget(),

        if (!_isFetchingSubjects && _subjectsError == null)
          _buildSubjectAssignmentsList(),
      ],
    );
  }

  void _showSubjectSelectionModal() {
    String searchQuery = '';
    String filterComponent = 'All'; // All, Lecture, Lab
    final clerkRepo = ref.read(clerkRepositoryProvider);
    final fetchFuture = clerkRepo.fetchAssignableSubjects();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchFuture,
          builder: (context, snapshot) {
            return StatefulBuilder(
              builder: (context, setModalState) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 3),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data?['success'] != true) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        snapshot.data?['error'] ?? snapshot.error?.toString() ?? 'Failed to load subjects',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final assignableGroupsList = (snapshot.data?['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                
                // Filter the assignable groups
                List<Map<String, dynamic>> filteredGroups = [];
                for (var group in assignableGroupsList) {
                  final groupName = group['group'] as String;
                  final subjects = group['subjects'] as List<dynamic>;

                  List<dynamic> filteredSubjects = subjects.where((subj) {
                    final subjName = (subj['label'] ?? '').toString().toLowerCase();
                    final component = (subj['component'] ?? '').toString();
                    
                    final matchesSearch = subjName.contains(searchQuery.toLowerCase());
                    final matchesFilter = filterComponent == 'All' || component == filterComponent;

                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredSubjects.isNotEmpty) {
                    filteredGroups.add({
                      'group': groupName,
                      'subjects': filteredSubjects,
                    });
                  }
                }

                return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Subject',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  // Search and Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search subjects...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: ['All', 'Lecture', 'Lab'].map((filter) {
                        final isSelected = filterComponent == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                filterComponent = filter;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFFEFF6FF),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFFBFDBFE) : Colors.grey.shade200,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subject List
                  Expanded(
                    child: filteredGroups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No subjects found',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredGroups.length,
                            itemBuilder: (context, groupIndex) {
                              final group = filteredGroups[groupIndex];
                              final subjects = group['subjects'] as List<dynamic>;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12, top: 16),
                                    child: Text(
                                      group['group'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF475569),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ...subjects.map((subj) {
                                    final bool assigned = subj['assigned'] == true;
                                    final teacherName = subj['teacher_name'];
                                    
                                    // Check if it's already selected in our form
                                    final isAlreadyAdded = _subjectAssignments.any((a) => a['id'] == subj['id']);

                                    final bool isDisabled = assigned || isAlreadyAdded;

                                    return InkWell(
                                      onTap: isDisabled ? null : () {
                                        setState(() {
                                          _subjectAssignments.add({
                                            'id': subj['id'],
                                            'label': subj['label'],
                                            'code': subj['code'],
                                            'group': group['group'],
                                            'component': subj['component'],
                                          });
                                        });
                                        _updateFormState();
                                        // update modal UI also (VERY IMPORTANT)
                                        setModalState(() {});   
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDisabled ? Colors.grey.shade50 : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDisabled ? Colors.grey.shade200 : const Color(0xFFE2E8F0),
                                          ),
                                          boxShadow: isDisabled ? null : const [
                                            BoxShadow(
                                              color: Color(0x05000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    subj['label'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDisabled ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                                      decoration: isDisabled ? TextDecoration.lineThrough : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        subj['code'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isDisabled ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (assigned && teacherName != null) ...[
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '• Assigned to $teacherName',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFFEF4444),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                      if (isAlreadyAdded) ...[
                                                        const SizedBox(width: 8),
                                                        const Text(
                                                          '• Added to form',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF2563EB),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              isDisabled ? Icons.lock_outline : Icons.chevron_right_rounded,
                                              color: isDisabled ? const Color(0xFFCBD5E1) : const Color(0xFFCBD5E1),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF2563EB).withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load subjects: $_subjectsError',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _fetchSubjects,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAssignmentsList() {
    if (_subjectAssignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No subjects assigned yet',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subjectAssignments.length,
      itemBuilder: (context, index) {
        final assignment = _subjectAssignments[index];
        final type = assignment['component'] ?? 'Lecture';
        final isLab = type == 'Lab';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: isLab ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['label'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment['code'] ?? ''} • ${assignment['group'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _subjectAssignments.removeAt(index);
                  });
                  _updateFormState();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red.shade400,
                tooltip: 'Remove',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveTeacherButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid && !_isLoading ? _saveTeacherDetails : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormValid && !_isLoading
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          foregroundColor: _isFormValid && !_isLoading
              ? Colors.white
              : const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: const Color(0x3D3B82F6),
          disabledBackgroundColor: const Color(0xFFF1F5F9),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 10),
                  Text(
                    'Save Teacher Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveTeacherDetails() async {
  if (_formKey.currentState!.validate() && _isFormValid) {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);

      // Get subject IDs for selected subject assignments
      final subjectsAssigned = _subjectAssignments.map((assignment) {
        return assignment['id'] as String;
      }).toList();

      final teacherData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailIdController.text.trim(),
        'mobile_number': _mobileNumberController.text.trim(),
        'subjects_assigned': subjectsAssigned,
      };

      AppLogger.info('Teacher Data: $teacherData');

      final result = await clerkRepo.createTeacher(teacherData);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success snackbar
        showSuccessSnackBar(context, 'Teacher created successfully!');

        // Reset form after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        _resetForm();

        // Clear focus
        FocusScope.of(context).requestFocus(FocusNode());
      } else {
        // Build detailed error message
        String errorMessage = '';
        
        // Check if there's a validation details field (for 422 errors)
        if (result['details'] != null && result['details'] is List) {
          final details = result['details'] as List;
          if (details.isNotEmpty) {
            errorMessage = 'Validation failed:\n';
            for (var detail in details) {
              errorMessage += '• ${detail['msg'] ?? detail['message'] ?? 'Invalid data'}\n';
            }
          } else {
            errorMessage = result['message'] ?? 'Failed to create teacher';
          }
        } 
        // Check if there's a technical error field
        else if (result['error'] != null && result['error'].toString().isNotEmpty) {
          errorMessage = result['error'].toString();
        }
        // Fallback to message field
        else {
          errorMessage = result['message'] ?? 'Failed to create teacher';
        }
        
        // Show error snackbar with detailed message
        showErrorSnackBar(context, errorMessage);
      }
    } catch (error) {
      // Show error snackbar for network/other errors
      if (mounted) {
        showErrorSnackBar(
          context,
          'Failed to save teacher: ${error.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
}
