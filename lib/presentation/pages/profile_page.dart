import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_schedule_data.dart';

/// Profile page for student information and settings
/// This page displays student details, attendance statistics, and app settings
/// Following the same design theme as login/signup pages with blue color scheme
/// 
/// Backend developers: This page will need student profile API integration
/// Expected endpoints:
/// - GET /api/student/profile - Get student information
/// - PUT /api/student/profile - Update changeable fields
/// - GET /api/student/statistics - Get attendance and academic stats
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _profileAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _profileImageAnimation;
  
  // Mock student data - will be replaced with backend data
  final Map<String, dynamic> _studentData = {
    'student_id': 'STU2024001',
    'first_name': 'John',
    'last_name': 'Doe',
    'email': 'john.doe@university.edu',
    'phone': '+1 (555) 123-4567',
    'course': 'Computer Science Engineering',
    'semester': 'Fall 2024',
    'year': '3rd Year',
    'section': 'A',
    'roll_number': 'CSE21001',
    'admission_date': '2022-08-15',
    'profile_image': null, // Will be URL from backend
    'address': {
      'street': '123 University Street',
      'city': 'Tech City',
      'state': 'California',
      'zip_code': '90210',
      'country': 'USA',
    },
    'emergency_contact': {
      'name': 'Jane Doe',
      'relationship': 'Mother',
      'phone': '+1 (555) 987-6543',
    },
    'academic_advisor': {
      'name': 'Dr. Smith Johnson',
      'email': 'smith.johnson@university.edu',
      'office': 'Room 301, Faculty Block',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
    
    _profileImageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.bounceOut,
    ));
    
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _profileAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Same background as login/signup
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                    child: Column(
                      children: [
                        // Profile Header Section
                        _buildProfileHeader(isDesktop),
                        
                        const SizedBox(height: 24),
                        
                        // Quick Stats Cards
                        _buildQuickStats(),
                        
                        const SizedBox(height: 24),
                        
                        // Personal Information Section
                        _buildPersonalInfoSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Academic Information Section
                        _buildAcademicInfoSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Contact Information Section
                        _buildContactInfoSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Emergency Contact Section
                        _buildEmergencyContactSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Settings Section
                        _buildSettingsSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Logout Button
                        _buildLogoutButton(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the profile header with avatar and basic info
  Widget _buildProfileHeader(bool isDesktop) {
    return AnimatedBuilder(
      animation: _profileImageAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile Avatar with animation
              Transform.scale(
                scale: _profileImageAnimation.value,
                child: Stack(
                  children: [
                    Container(
                      width: isDesktop ? 120 : 100,
                      height: isDesktop ? 120 : 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isDesktop ? 56 : 46,
                        backgroundColor: Colors.white,
                        child: _studentData['profile_image'] != null
                            ? ClipOval(
                                child: Image.network(
                                  _studentData['profile_image'],
                                  width: isDesktop ? 112 : 92,
                                  height: isDesktop ? 112 : 92,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: isDesktop ? 60 : 50,
                                color: Colors.blue.shade600,
                              ),
                      ),
                    ),
                    
                    // Online status indicator with pulse animation
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Student Name with fade-in animation
              AnimatedOpacity(
                opacity: _profileImageAnimation.value,
                duration: const Duration(milliseconds: 600),
                child: Text(
                  '${_studentData['first_name']} ${_studentData['last_name']}',
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Student ID with slide animation
              AnimatedSlide(
                offset: Offset(0, 1 - _profileImageAnimation.value),
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${_studentData['student_id']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Course and Year
              AnimatedOpacity(
                opacity: _profileImageAnimation.value,
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  '${_studentData['course']} • ${_studentData['year']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds quick statistics cards with staggered animation
  Widget _buildQuickStats() {
    final stats = MockScheduleData.getAttendanceStats();
    
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 600 + (0 * 100)),
            curve: Curves.easeOutBack,
            child: _buildStatCard(
              title: 'Attendance',
              value: '${stats['attendance_percentage']?.toStringAsFixed(1) ?? '0.0'}%',
              icon: Icons.check_circle_outline,
              color: _getAttendanceColor(stats['attendance_percentage'] ?? 0.0),
              delay: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 600 + (1 * 100)),
            curve: Curves.easeOutBack,
            child: _buildStatCard(
              title: 'Total Classes',
              value: '${stats['total_classes'] ?? 0}',
              icon: Icons.school_outlined,
              color: Colors.blue.shade600,
              delay: 100,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 600 + (2 * 100)),
            curve: Curves.easeOutBack,
            child: _buildStatCard(
              title: 'Present',
              value: '${stats['attended_classes'] ?? 0}',
              icon: Icons.event_available,
              color: Colors.green.shade600,
              delay: 200,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds individual stat card with animation
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + delay),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.bounceOut,
                  builder: (context, iconAnimation, child) {
                    return Transform.scale(
                      scale: iconAnimation,
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 400 + delay),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  child: Text(value),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 600 + delay),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds personal information section
  Widget _buildPersonalInfoSection() {
    return _buildInfoSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Full Name', '${_studentData['first_name']} ${_studentData['last_name']}'),
        _buildInfoRow('Email', _studentData['email']),
        _buildInfoRow('Phone', _studentData['phone']),
        _buildInfoRow('Address', 
          '${_studentData['address']['street']}, ${_studentData['address']['city']}, ${_studentData['address']['state']} ${_studentData['address']['zip_code']}'),
      ],
    );
  }

  /// Builds academic information section
  Widget _buildAcademicInfoSection() {
    return _buildInfoSection(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      children: [
        _buildInfoRow('Course', _studentData['course']),
        _buildInfoRow('Roll Number', _studentData['roll_number']),
        _buildInfoRow('Year & Semester', '${_studentData['year']} - ${_studentData['semester']}'),
        _buildInfoRow('Section', _studentData['section']),
        _buildInfoRow('Admission Date', _formatDate(_studentData['admission_date'])),
        _buildInfoRow('Academic Advisor', 
          '${_studentData['academic_advisor']['name']}\n${_studentData['academic_advisor']['email']}\n${_studentData['academic_advisor']['office']}'),
      ],
    );
  }

  /// Builds contact information section
  Widget _buildContactInfoSection() {
    return _buildInfoSection(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildInfoRow('Email', _studentData['email'], copyable: true),
        _buildInfoRow('Phone', _studentData['phone'], copyable: true),
        _buildInfoRow('Address', 
          '${_studentData['address']['street']}\n${_studentData['address']['city']}, ${_studentData['address']['state']} ${_studentData['address']['zip_code']}\n${_studentData['address']['country']}'),
      ],
    );
  }

  /// Builds emergency contact section
  Widget _buildEmergencyContactSection() {
    return _buildInfoSection(
      title: 'Emergency Contact',
      icon: Icons.emergency_outlined,
      children: [
        _buildInfoRow('Name', _studentData['emergency_contact']['name']),
        _buildInfoRow('Relationship', _studentData['emergency_contact']['relationship']),
        _buildInfoRow('Phone', _studentData['emergency_contact']['phone'], copyable: true),
      ],
    );
  }

  /// Builds settings section with animated tiles
  Widget _buildSettingsSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Section Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Settings Options with staggered animation
                  ...List.generate(4, (index) {
                    final settingsData = [
                      {
                        'icon': Icons.notifications_outlined,
                        'title': 'Notifications',
                        'subtitle': 'Manage notification preferences',
                      },
                      {
                        'icon': Icons.security_outlined,
                        'title': 'Privacy & Security',
                        'subtitle': 'Manage your privacy settings',
                      },
                      {
                        'icon': Icons.help_outline,
                        'title': 'Help & Support',
                        'subtitle': 'Get help and contact support',
                      },
                      {
                        'icon': Icons.info_outline,
                        'title': 'About',
                        'subtitle': 'App version and information',
                      },
                    ];
                    
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, tileAnimation, child) {
                        return Transform.translate(
                          offset: Offset(100 * (1 - tileAnimation), 0),
                          child: Opacity(
                            opacity: tileAnimation,
                            child: _buildSettingsTile(
                              icon: settingsData[index]['icon'] as IconData,
                              title: settingsData[index]['title'] as String,
                              subtitle: settingsData[index]['subtitle'] as String,
                              onTap: () {
                                // TODO: Navigate to respective settings
                              },
                              showDivider: index < 3,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds logout button with hover animation
  Widget _buildLogoutButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade500, Colors.red.shade600],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a generic information section with animation
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Section Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Section Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds an information row with animation
  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (copyable)
                          GestureDetector(
                            onTap: () => _copyToClipboard(value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.blue.shade400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a settings tile with hover effect
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.grey.shade200,
            indent: 56,
          ),
      ],
    );
  }

  /// Shows logout confirmation dialog with animation
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, animationValue, child) {
            return Transform.scale(
              scale: animationValue,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Are you sure you want to logout from your account?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Handles logout functionality
  void _handleLogout() {
    // TODO: Implement actual logout logic
    // - Clear user session
    // - Clear cached data
    // - Navigate to login page
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logged out successfully'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    
    // Navigate to login page
    context.go('/login');
  }

  /// Copies text to clipboard with feedback
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Formats date string for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Gets color for attendance percentage
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green.shade600;
    } else if (percentage >= 50) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }
}