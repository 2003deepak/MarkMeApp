import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';

class AddSubjectPage extends ConsumerStatefulWidget {
  const AddSubjectPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends ConsumerState<AddSubjectPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();

  int? _selectedSemester;
  String? _selectedComponent;
  int? _selectedCredits;
  bool _isLoading = false;

  final List<String> _semesters = List.generate(10, (i) => '${i + 1}');
  final List<String> _components = ['Lecture', 'Lab'];
  final List<int> _credits = List.generate(10, (i) => i + 1);

  bool get _isFormValid {
    return _subjectNameController.text.isNotEmpty &&
        _subjectCodeController.text.isNotEmpty &&
        _selectedSemester != null &&
        _selectedComponent != null &&
        _selectedCredits != null;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _subjectNameController.addListener(_updateFormState);
    _subjectCodeController.addListener(_updateFormState);
  }

  // <CHANGE> Added animation setup for smooth page transitions
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    if (mounted) setState(() {});
  }

  void _handleBackPressed() {
    context.go("/clerk");
  }

  // <CHANGE> Extracted form field building for cleaner code
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSubjectNameField(),
        const SizedBox(height: 20),
        _buildSubjectCodeField(),
        const SizedBox(height: 20),
        _buildSemesterDropdown(),
        const SizedBox(height: 20),
        _buildComponentDropdown(),
        const SizedBox(height: 20),
        _buildCreditsDropdown(),
        const SizedBox(height: 40),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSubjectNameField() {
    return InputField(
      label: "Subject Name",
      hintText: "Enter subject name",
      controller: _subjectNameController,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter subject name';
        }
        if (value.length < 2) {
          return 'Subject name must be at least 2 characters';
        }
        if (value.length > 100) {
          return 'Subject name must be less than 100 characters';
        }
        return null;
      },
      isRequired: true,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildSubjectCodeField() {
    return InputField(
      label: "Subject Code",
      hintText: "Enter subject code (e.g., CS101)",
      controller: _subjectCodeController,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter subject code';
        }
        if (value.length < 2) {
          return 'Subject code must be at least 2 characters';
        }
        if (value.length > 20) {
          return 'Subject code must be less than 20 characters';
        }
        if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value)) {
          return 'Subject code can only contain letters and numbers';
        }
        return null;
      },
      isRequired: true,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildSemesterDropdown() {
    return _buildDropdownContainer(
      child: Dropdown<String>(
        label: "Semester",
        hint: "Select Semester",
        items: _semesters,
        value: _selectedSemester?.toString(),
        onChanged: (val) {
          setState(() => _selectedSemester = int.tryParse(val ?? ''));
          _updateFormState();
        },
        validator: (val) => val == null ? "Please select a semester" : null,
        isRequired: true,
      ),
    );
  }

  Widget _buildComponentDropdown() {
    return _buildDropdownContainer(
      child: Dropdown<String>(
        label: "Component Type",
        hint: "Select Component",
        items: _components,
        value: _selectedComponent,
        onChanged: (val) {
          setState(() => _selectedComponent = val);
          _updateFormState();
        },
        validator: (val) => val == null ? "Please select a component" : null,
        isRequired: true,
      ),
    );
  }

  Widget _buildCreditsDropdown() {
    return _buildDropdownContainer(
      child: Dropdown<int>(
        label: "Credits",
        hint: "Select Credits",
        items: _credits,
        value: _selectedCredits,
        onChanged: (val) {
          setState(() => _selectedCredits = val);
          _updateFormState();
        },
        validator: (val) => val == null ? "Please select credits" : null,
        isRequired: true,
        displayText: (val) => val.toString(),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(width: double.maxFinite, child: child);
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid && !_isLoading ? _saveSubject : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormValid && !_isLoading
              ? const Color(0xFF2563EB)
              : Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isFormValid && !_isLoading ? 4 : 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Subject',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);

      final subjectData = {
        'subject_code': _subjectCodeController.text.trim().toUpperCase(),
        'subject_name': _subjectNameController.text.trim(),
        'semester': _selectedSemester,
        'component': _selectedComponent,
        'credit': _selectedCredits,
        'department': 'BTECH',
        'program': 'MCA',
      };

      final result = await clerkRepo.createSubject(subjectData);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessSnackBar(
          result['message'] ?? 'Subject added successfully!',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/clerk');
      } else {
        _showErrorSnackBar(result['error'] ?? 'Failed to add subject');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to add subject: ${error.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // <CHANGE> Extracted snackbar methods for reusability
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF475569),
            ),
          ),
          onPressed: _isLoading ? null : _handleBackPressed,
        ),
        title: const Text(
          'Add Subject',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(key: _formKey, child: _buildFormFields()),
          ),
        ),
      ),
    );
  }
}
