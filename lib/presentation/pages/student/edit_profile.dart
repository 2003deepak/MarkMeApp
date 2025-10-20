import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
// import 'package:markmeapp/data/repositories/student_repository.dart';

class EditProfileInitial {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime? dob;
  final String rollNumber;
  final String program;
  final String department;
  final int semester;
  final int batchYear;

  EditProfileInitial({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dob,
    required this.rollNumber,
    required this.program,
    required this.department,
    required this.semester,
    required this.batchYear,
  });
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // final StudentRepository _studentRepo = StudentRepository();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _rollCtrl;
  late final TextEditingController _batchYearCtrl;

  DateTime? _dob;
  String _program = 'MCA';
  String _department = 'BTECH';
  int _semester = 1;
  String? _profilePicture;
  final List<String?> _gallery = List<String?>.filled(4, null);

  bool _isLoading = true;
  bool _hasError = false;

  // Updated design properties
  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers with empty values
    _firstNameCtrl = TextEditingController();
    _middleNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _rollCtrl = TextEditingController();
    _batchYearCtrl = TextEditingController();

    // Fetch profile data
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // final response = await _studentRepo.fetchProfile();
      final response = {};

      if (response['success'] == true && mounted) {
        final data = response['data'];

        // Populate controllers with API data
        _firstNameCtrl.text = data['first_name'] ?? '';
        _middleNameCtrl.text = data['middle_name'] ?? '';
        _lastNameCtrl.text = data['last_name'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _rollCtrl.text = data['roll_number']?.toString() ?? '';
        _program = data['program'] ?? 'MCA';
        _department = data['department'] ?? 'BTECH';
        _semester = data['semester'] ?? 1;
        _batchYearCtrl.text =
            data['batch_year']?.toString() ?? DateTime.now().year.toString();
        _profilePicture = data['profile_picture'];

        setState(() {
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Failed to load profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _rollCtrl.dispose();
    _batchYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 80);
    final lastDate = DateTime(now.year - 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );
    if (picked != null && mounted) {
      setState(() {
        _dob = picked;
        _dobCtrl.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _pickBatchYear() async {
    final now = DateTime.now();
    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempYear = int.tryParse(_batchYearCtrl.text) ?? now.year;
        return AlertDialog(
          title: const Text('Select Batch Year'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(now.year - 20, 1),
              lastDate: DateTime(now.year + 1, 1),
              selectedDate: DateTime(tempYear, 1),
              onChanged: (DateTime dateTime) {
                Navigator.of(context).pop(dateTime.year);
              },
            ),
          ),
        );
      },
    );
    if (selectedYear != null && mounted) {
      setState(() {
        _batchYearCtrl.text = selectedYear.toString();
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop<Map<String, dynamic>>({
        'firstName': _firstNameCtrl.text.trim(),
        'middleName': _middleNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'dob': _dob,
        'rollNumber': _rollCtrl.text.trim(),
        'program': _program,
        'department': _department,
        'semester': _semester,
        'batchYear':
            int.tryParse(_batchYearCtrl.text.trim()) ?? DateTime.now().year,
        'profilePicture': _profilePicture,
        'gallery': _gallery,
      });
    }
  }

  // Stub methods for image picking
  Future<void> _pickProfilePicture() async {
    // Integrate with image_picker or your uploader here.
    setState(() {
      _profilePicture = 'https://i.pravatar.cc/150?img=5';
    });
  }

  Future<void> _pickGalleryImage(int index) async {
    setState(() {
      _gallery[index] = 'https://picsum.photos/seed/${index + 11}/300/200';
    });
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _fetchProfileData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchProfileData,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Centered Profile Picture
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(50),
                            image: _profilePicture != null
                                ? DecorationImage(
                                    image: NetworkImage(_profilePicture!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profilePicture == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfilePicture,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Change Profile Photo',
                      style: TextStyle(
                        color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _sectionHeader('PERSONAL INFORMATION'),
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Name fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'First name',
                              labelStyle: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _middleNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Middle name (optional)',
                              labelStyle: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Last name',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email (read-only)
                    TextFormField(
                      controller: _emailCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        suffixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // DOB
                    TextFormField(
                      controller: _dobCtrl,
                      readOnly: true,
                      onTap: _pickDob,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        suffixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (_) => _dob == null ? 'Select a date' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Academic Information Section
              _sectionHeader('ACADEMIC INFORMATION'),
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Roll number 3-digit
                    TextFormField(
                      controller: _rollCtrl,
                      maxLength: 3,
                      decoration: InputDecoration(
                        labelText: 'Roll number (3 digits)',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.length != 3) return 'Enter exactly 3 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Program dropdown
                    DropdownButtonFormField<String>(
                      value: _program,
                      decoration: InputDecoration(
                        labelText: 'Program',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MCA', child: Text('MCA')),
                        DropdownMenuItem(value: 'AI', child: Text('AI')),
                        DropdownMenuItem(value: 'ML', child: Text('ML')),
                      ],
                      onChanged: (v) => setState(() => _program = v!),
                    ),
                    const SizedBox(height: 16),

                    // Department dropdown
                    DropdownButtonFormField<String>(
                      value: _department,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BTECH', child: Text('BTECH')),
                        DropdownMenuItem(value: 'MTECH', child: Text('MTECH')),
                      ],
                      onChanged: (v) => setState(() => _department = v!),
                    ),
                    const SizedBox(height: 16),

                    // Semester dropdown
                    DropdownButtonFormField<int>(
                      value: _semester,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      onChanged: (v) => setState(() => _semester = v!),
                    ),
                    const SizedBox(height: 16),

                    // Batch year (year-only)
                    TextFormField(
                      controller: _batchYearCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Batch year',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        suffixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                      ),
                      onTap: _pickBatchYear,
                      validator: (v) {
                        final year = int.tryParse((v ?? '').trim());
                        if (year == null || year < 2000)
                          return 'Select a valid year';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gallery Section
              _sectionHeader('GALLERY'),
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload photos (up to 4)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gallery.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemBuilder: (context, index) {
                        final url = _gallery[index];
                        return InkWell(
                          onTap: () => _pickGalleryImage(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              image: url != null
                                  ? DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: url == null
                                ? const Center(
                                    child: Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Color(0xFF4F46E5),
                                      size: 24,
                                    ),
                                  )
                                : Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      margin: const EdgeInsets.all(6),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
