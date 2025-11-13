import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassSelectionPage extends StatefulWidget {
  const ClassSelectionPage({Key? key}) : super(key: key);

  @override
  State<ClassSelectionPage> createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedClassId;

  // Mock class data - will be replaced with backend data
  final List<Map<String, dynamic>> _classes = [
    {
      'id': 'class_001',
      'name': 'Computer Science Engineering',
      'degree': 'B.Tech',
      'semester': '6th Semester',
      'section': 'A',
      'year': '3rd Year',
      'students_count': 45,
      'subject': 'Data Structures & Algorithms',
      'room': 'Room 101',
      'building': 'Engineering Block',
      'color': Colors.blue.shade600,
    },
    {
      'id': 'class_002',
      'name': 'Computer Science Engineering',
      'degree': 'B.Tech',
      'semester': '6th Semester',
      'section': 'B',
      'year': '3rd Year',
      'students_count': 42,
      'subject': 'Database Management Systems',
      'room': 'Room 102',
      'building': 'Engineering Block',
      'color': Colors.green.shade600,
    },
    {
      'id': 'class_003',
      'name': 'Information Technology',
      'degree': 'B.Tech',
      'semester': '4th Semester',
      'section': 'A',
      'year': '2nd Year',
      'students_count': 38,
      'subject': 'Web Development',
      'room': 'Lab C',
      'building': 'Computer Lab Block',
      'color': Colors.purple.shade600,
    },
    {
      'id': 'class_004',
      'name': 'Computer Applications',
      'degree': 'MCA',
      'semester': '2nd Semester',
      'section': 'A',
      'year': '1st Year',
      'students_count': 35,
      'subject': 'Advanced Java Programming',
      'room': 'Room 201',
      'building': 'PG Block',
      'color': Colors.orange.shade600,
    },
    {
      'id': 'class_005',
      'name': 'Computer Science Engineering',
      'degree': 'B.Tech',
      'semester': '8th Semester',
      'section': 'A',
      'year': '4th Year',
      'students_count': 40,
      'subject': 'Machine Learning',
      'room': 'Room 401',
      'building': 'Research Block',
      'color': Colors.teal.shade600,
    },
    {
      'id': 'class_006',
      'name': 'Electronics & Communication',
      'degree': 'B.Tech',
      'semester': '6th Semester',
      'section': 'A',
      'year': '3rd Year',
      'students_count': 43,
      'subject': 'Digital Signal Processing',
      'room': 'Room 301',
      'building': 'Electronics Block',
      'color': Colors.indigo.shade600,
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeaderSection(),

                            const SizedBox(height: 24),

                            // Classes List
                            _buildClassesList(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Button
                    if (_selectedClassId != null) _buildBottomActionButton(),
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
              'Select Class',
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
              Icons.class_outlined,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds header section
  Widget _buildHeaderSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select the class you want to send notifications to',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds classes list
  Widget _buildClassesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Classes (${_classes.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 16),

        ..._classes.asMap().entries.map((entry) {
          final index = entry.key;
          final classData = entry.value;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, animationValue, child) {
              return Transform.translate(
                offset: Offset(50 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue,
                  child: _buildClassCard(classData),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  /// Builds individual class card
  Widget _buildClassCard(Map<String, dynamic> classData) {
    final isSelected = _selectedClassId == classData['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedClassId = classData['id'];
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 12 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (classData['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.class_outlined,
                      color: classData['color'] as Color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${classData['degree']} ${classData['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${classData['year']} • Section ${classData['section']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSelected)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Details Row
              Row(
                children: [
                  _buildDetailChip(
                    icon: Icons.book_outlined,
                    label: classData['subject'],
                    color: classData['color'] as Color,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    icon: Icons.people_outline,
                    label: '${classData['students_count']} Students',
                    color: Colors.grey.shade600,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location Row
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${classData['room']}, ${classData['building']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds detail chip
  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
                label: const Text(
                  'Select This Class',
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
      ),
    );
  }

  /// Confirms class selection
  void _confirmSelection() {
    if (_selectedClassId != null) {
      final selectedClass = _classes.firstWhere(
        (c) => c['id'] == _selectedClassId,
      );

      Navigator.pop(context, {
        'class_id': _selectedClassId,
        'class_name': selectedClass['name'],
        'students_count': selectedClass['students_count'],
      });
    }
  }
}
