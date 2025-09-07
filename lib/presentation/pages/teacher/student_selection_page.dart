import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Student Selection Page - Beautiful UI for teachers to select individual students
/// This page allows teachers to:
/// - View all students with their details
/// - Select multiple students individually
/// - Search and filter students
/// - See selected count in real-time
/// 
/// Backend developers: This page will need student API integration
/// Expected endpoints:
/// - GET /api/teacher/students - Get all students for teacher
/// - GET /api/students/search - Search students by name/id
class StudentSelectionPage extends StatefulWidget {
  const StudentSelectionPage({Key? key}) : super(key: key);

  @override
  State<StudentSelectionPage> createState() => _StudentSelectionPageState();
}

class _StudentSelectionPageState extends State<StudentSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedStudentIds = {};
  List<Map<String, dynamic>> _filteredStudents = [];

  // Mock student data - will be replaced with backend data
  final List<Map<String, dynamic>> _allStudents = [
    {
      'id': 'STU2024001',
      'name': 'John Doe',
      'email': 'john.doe@university.edu',
      'roll_number': 'CSE21001',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 92.5,
    },
    {
      'id': 'STU2024002',
      'name': 'Jane Smith',
      'email': 'jane.smith@university.edu',
      'roll_number': 'CSE21002',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 88.0,
    },
    {
      'id': 'STU2024003',
      'name': 'Mike Johnson',
      'email': 'mike.johnson@university.edu',
      'roll_number': 'CSE21003',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 95.2,
    },
    {
      'id': 'STU2024004',
      'name': 'Sarah Wilson',
      'email': 'sarah.wilson@university.edu',
      'roll_number': 'CSE21004',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 78.5,
    },
    {
      'id': 'STU2024005',
      'name': 'David Brown',
      'email': 'david.brown@university.edu',
      'roll_number': 'CSE21005',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 91.8,
    },
    {
      'id': 'STU2024006',
      'name': 'Emily Davis',
      'email': 'emily.davis@university.edu',
      'roll_number': 'CSE21006',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 86.3,
    },
    {
      'id': 'STU2024007',
      'name': 'Alex Miller',
      'email': 'alex.miller@university.edu',
      'roll_number': 'CSE21007',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 93.7,
    },
    {
      'id': 'STU2024008',
      'name': 'Lisa Anderson',
      'email': 'lisa.anderson@university.edu',
      'roll_number': 'CSE21008',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 89.4,
    },
    {
      'id': 'STU2024009',
      'name': 'Chris Taylor',
      'email': 'chris.taylor@university.edu',
      'roll_number': 'CSE21009',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 84.1,
    },
    {
      'id': 'STU2024010',
      'name': 'Amanda White',
      'email': 'amanda.white@university.edu',
      'roll_number': 'CSE21010',
      'degree': 'B.Tech Computer Science',
      'year': '3rd Year',
      'section': 'A',
      'profile_image': null,
      'attendance_percentage': 96.8,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredStudents = List.from(_allStudents);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Custom App Bar
                    _buildCustomAppBar(),
                    
                    // Search Bar
                    _buildSearchBar(),
                    
                    // Selected Count Banner
                    if (_selectedStudentIds.isNotEmpty) _buildSelectedBanner(),
                    
                    // Main Content
                    Expanded(
                      child: _buildStudentsList(),
                    ),
                    
                    // Bottom Action Button
                    if (_selectedStudentIds.isNotEmpty) _buildBottomActionButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds custom app bar
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.grey.shade700,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          const Expanded(
            child: Text(
              'Select Students',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people_outline,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - animationValue)),
            child: Opacity(
              opacity: animationValue,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search students by name or roll number...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.blue.shade400,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterStudents('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: _filterStudents,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds selected count banner
  Widget _buildSelectedBanner() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Text(
                    '${_selectedStudentIds.length} student${_selectedStudentIds.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStudentIds.clear();
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.clear,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds students list
  Widget _buildStudentsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Students (${_filteredStudents.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ..._filteredStudents.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, animationValue, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - animationValue), 0),
                  child: Opacity(
                    opacity: animationValue,
                    child: _buildStudentCard(student),
                  ),
                );
              },
            );
          }).toList(),
          
          const SizedBox(height: 100), // Space for bottom button
        ],
      ),
    );
  }

  /// Builds individual student card
  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isSelected = _selectedStudentIds.contains(student['id']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedStudentIds.remove(student['id']);
            } else {
              _selectedStudentIds.add(student['id']);
            }
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.grey.shade100,
                  child: student['profile_image'] != null
                      ? ClipOval(
                          child: Image.network(
                            student['profile_image'],
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.grey.shade600,
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.blue.shade600 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student['roll_number'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student['degree']} • ${student['year']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Attendance Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAttendanceColor(student['attendance_percentage']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${student['attendance_percentage'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getAttendanceColor(student['attendance_percentage']),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Selection Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds bottom action button
  Widget _buildBottomActionButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
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
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  'Select ${_selectedStudentIds.length} Student${_selectedStudentIds.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Filters students based on search query
  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          return student['name'].toLowerCase().contains(query.toLowerCase()) ||
                 student['roll_number'].toLowerCase().contains(query.toLowerCase()) ||
                 student['email'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  /// Gets attendance color based on percentage
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green.shade600;
    } else if (percentage >= 75) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  /// Confirms student selection
  void _confirmSelection() {
    if (_selectedStudentIds.isNotEmpty) {
      final selectedStudents = _allStudents
          .where((student) => _selectedStudentIds.contains(student['id']))
          .toList();
      
      Navigator.pop(context, {
        'count': _selectedStudentIds.length,
        'students': selectedStudents,
        'student_ids': _selectedStudentIds.toList(),
      });
    }
  }
}