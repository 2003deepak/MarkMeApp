import 'package:flutter/material.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({Key? key}) : super(key: key);

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _emailIdController = TextEditingController();

  // Dynamic subject assignments
  List<Map<String, String?>> _subjectAssignments = [
    {'year': null, 'subject': null},
  ];

  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'English',
    'Computer Science',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileNumberController.dispose();
    _teacherIdController.dispose();
    _emailIdController.dispose();
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
        title: const Text('Add Teacher'),
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
                _buildFullNameField(),
                const SizedBox(height: 20),
                _buildMobileNumberField(),
                const SizedBox(height: 20),
                _buildTeacherIdField(),
                const SizedBox(height: 20),
                _buildEmailIdField(),
                const SizedBox(height: 30),
                _buildSubjectAssignmentSection(),
                const SizedBox(height: 40),
                _buildSaveTeacherButton(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  InputDecoration _textFieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Name',
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
            controller: _fullNameController,
            decoration: _textFieldDecoration(
              hint: 'Enter teacher\'s full name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter full name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
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
            controller: _mobileNumberController,
            decoration: _textFieldDecoration(hint: 'Enter mobile number'),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter mobile number';
              }
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                return 'Enter a valid 10-digit number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teacher ID',
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
            controller: _teacherIdController,
            decoration: _textFieldDecoration(hint: 'Enter teacher ID'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Teacher ID';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email ID',
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
            controller: _emailIdController,
            decoration: _textFieldDecoration(hint: 'Enter teacher email'),
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
          ),
        ),
      ],
    );
  }

// Section builder
Widget _buildSubjectAssignmentSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Subject Assignment',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 12),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _subjectAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _subjectAssignments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _subjectDropdown(
                    value: assignment['subject'],
                    onChanged: (newValue) {
                      setState(() {
                        assignment['subject'] = newValue;
                      });
                    },
                  ),
                ),
                if (_subjectAssignments.length > 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _subjectAssignments.removeAt(index);
                      });
                    },
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400),
                  ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () {
          setState(() {
            _subjectAssignments.add({'year': null, 'subject': null});
          });
        },
        icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
        label: const Text(
          'Add More Subjects',
          style: TextStyle(color: Color(0xFF2563EB)),
        ),
      ),
    ],
  );
}

Widget _subjectDropdown({
  String? value,
  required Function(String?) onChanged,
}) {
  return Container(
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
    child: DropdownButtonFormField<String>(
      value: value,
      hint: const Text('Select Subject'),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _subjects.map((String subject) {
        return DropdownMenuItem<String>(
          value: subject,
          child: Text(subject),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) =>
          val == null || val.isEmpty ? 'Please select subject' : null,
    ),
  );
}
  Widget _buildSaveTeacherButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveTeacherDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        child: const Text(
          'Save Teacher Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomAppBar(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.calendar_today_outlined, 'Schedule', false),
            _buildNavItem(Icons.notifications_outlined, 'Notifications', false),
            _buildNavItem(Icons.person_outline, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade600,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _saveTeacherDetails() {
    if (_formKey.currentState!.validate()) {
      // Validate all subject assignments
      for (var assignment in _subjectAssignments) {
        if (assignment['year'] == null || assignment['year']!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select year for all assignments'),
            ),
          );
          return;
        }
        if (assignment['subject'] == null || assignment['subject']!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select subject for all assignments'),
            ),
          );
          return;
        }
      }

      final teacherData = {
        'fullName': _fullNameController.text,
        'mobileNumber': _mobileNumberController.text,
        'teacherId': _teacherIdController.text,
        'emailId': _emailIdController.text,
        'subjectAssignments': _subjectAssignments,
      };

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Teacher details saved successfully!'),
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

      print('Teacher Data: $teacherData');
    }
  }
}
