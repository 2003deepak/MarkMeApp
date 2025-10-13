import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/bottom_navigation.dart';
import 'package:markmeapp/presentation/widgets/dropdown.dart';

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({Key? key}) : super(key: key);

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {

  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();

  int _selectedIndex = 0;
  late PageController _pageController;

  String? _selectedSemester;
  String? _selectedComponent;
  int? _selectedCredits;

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _components = ['Lecture', 'Lab'];

  final List<int> _credits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Subject'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                CustomDropdown<String>(
                  label: "Semester",
                  hint: "Select Semester",
                  items: _semesters,
                  value: _selectedSemester,
                  onChanged: (val) => setState(() => _selectedSemester = val),
                  validator: (val) =>
                      val == null ? "Please select a semester" : null,
            ),
                const SizedBox(height: 20),
                CustomDropdown<String>(
              label: "Semester",
              hint: "Select Semester",
              items: _semesters,
              value: _selectedSemester,
              onChanged: (val) => setState(() => _selectedSemester = val),
              validator: (val) =>
                  val == null ? "Please select a semester" : null,
            ),
                const SizedBox(height: 20),
                 CustomDropdown<String>(
              label: "Semester",
              hint: "Select Semester",
              items: _semesters,
              value: _selectedSemester,
              onChanged: (val) => setState(() => _selectedSemester = val),
              validator: (val) =>
                  val == null ? "Please select a semester" : null,
            ),
                const SizedBox(height: 20),
                 CustomDropdown<String>(
              label: "Semester",
              hint: "Select Semester",
              items: _semesters,
              value: _selectedSemester,
              onChanged: (val) => setState(() => _selectedSemester = val),
              validator: (val) =>
                  val == null ? "Please select a semester" : null,
            ),
                const SizedBox(height: 40),
                 CustomDropdown<String>(
              label: "Semester",
              hint: "Select Semester",
              items: _semesters,
              value: _selectedSemester,
              onChanged: (val) => setState(() => _selectedSemester = val),
              validator: (val) =>
                  val == null ? "Please select a semester" : null,
            ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(pageController: _pageController),
    );
  }

  InputDecoration _dropdownDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSubjectNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _subjectNameController,
            decoration: InputDecoration(
              hintText: 'Enter subject name',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter subject name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _subjectCodeController,
            decoration: InputDecoration(
              hintText: 'Enter subject code',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter subject code';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSubject,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        child: const Text(
          'Save Subject',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _saveSubject() {
    if (_formKey.currentState!.validate()) {
      final subjectData = {
        'subjectName': _subjectNameController.text,
        'subjectCode': _subjectCodeController.text,
        'semester': _selectedSemester,
        'component': _selectedComponent,
        'credits': _selectedCredits,
      };

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Subject has been added successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      print('Subject Data: $subjectData');
    }
  }
}
