// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../../data/models/schedule_model.dart';

// class AttendanceMarkingPage extends StatefulWidget {
//   final ScheduleModel lecture;
  
//   const AttendanceMarkingPage({
//     Key? key,
//     required this.lecture,
//   }) : super(key: key);

//   @override
//   State<AttendanceMarkingPage> createState() => _AttendanceMarkingPageState();
// }

// class _AttendanceMarkingPageState extends State<AttendanceMarkingPage>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late AnimationController _headerController;
//   late AnimationController _submitController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _headerScaleAnimation;
//   late Animation<double> _submitScaleAnimation;

//   final TextEditingController _searchController = TextEditingController();
//   final Map<String, bool> _attendanceMap = {};
//   List<Map<String, dynamic>> _allStudents = [];
//   List<Map<String, dynamic>> _filteredStudents = [];
//   bool _isSubmitting = false;
//   String _selectedFilter = 'all';

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
    
//     _headerController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
    
//     _submitController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.2),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutCubic,
//     ));

//     _headerScaleAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _headerController,
//       curve: Curves.elasticOut,
//     ));

//     _submitScaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.95,
//     ).animate(CurvedAnimation(
//       parent: _submitController,
//       curve: Curves.easeInOut,
//     ));

//     _loadStudents();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _headerController.dispose();
//     _submitController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _loadStudents() async {
//     _allStudents = [
//       {
//         'id': 'STU2024001',
//         'name': 'John Doe',
//         'roll_number': 'CSE21001',
//         'profile_image': null,
//         'attendance_percentage': 92.5,
//       },
//       {
//         'id': 'STU2024002',
//         'name': 'Jane Smith',
//         'roll_number': 'CSE21002',
//         'profile_image': null,
//         'attendance_percentage': 88.0,
//       },
//       {
//         'id': 'STU2024003',
//         'name': 'Mike Johnson',
//         'roll_number': 'CSE21003',
//         'profile_image': null,
//         'attendance_percentage': 95.2,
//       },
//       {
//         'id': 'STU2024004',
//         'name': 'Sarah Wilson',
//         'roll_number': 'CSE21004',
//         'profile_image': null,
//         'attendance_percentage': 78.5,
//       },
//       {
//         'id': 'STU2024005',
//         'name': 'David Brown',
//         'roll_number': 'CSE21005',
//         'profile_image': null,
//         'attendance_percentage': 91.8,
//       },
//       {
//         'id': 'STU2024006',
//         'name': 'Emily Davis',
//         'roll_number': 'CSE21006',
//         'profile_image': null,
//         'attendance_percentage': 86.3,
//       },
//       {
//         'id': 'STU2024007',
//         'name': 'Alex Miller',
//         'roll_number': 'CSE21007',
//         'profile_image': null,
//         'attendance_percentage': 93.7,
//       },
//       {
//         'id': 'STU2024008',
//         'name': 'Lisa Anderson',
//         'roll_number': 'CSE21008',
//         'profile_image': null,
//         'attendance_percentage': 89.4,
//       },
//     ];

//     for (var student in _allStudents) {
//       _attendanceMap[student['id']] = false;
//     }

//     setState(() {
//       _filteredStudents = List.from(_allStudents);
//     });

//     _animationController.forward();
//     _headerController.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: SafeArea(
//         child: AnimatedBuilder(
//           animation: _animationController,
//           builder: (context, child) {
//             return FadeTransition(
//               opacity: _fadeAnimation,
//               child: SlideTransition(
//                 position: _slideAnimation,
//                 child: Column(
//                   children: [
//                     _buildCustomAppBar(),
//                     _buildLectureHeader(),
//                     _buildSearchAndFilterBar(),
//                     _buildAttendanceStats(),
//                     Expanded(child: _buildStudentsList()),
//                     _buildSubmitButton(),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomAppBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () => Navigator.pop(context),
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 Icons.arrow_back_ios_new,
//                 color: Colors.grey.shade700,
//                 size: 20,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           const Expanded(
//             child: Text(
//               'Mark Attendance',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               Icons.how_to_reg,
//               color: Colors.green.shade600,
//               size: 20,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLectureHeader() {
//     return AnimatedBuilder(
//       animation: _headerController,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _headerScaleAnimation.value,
//           child: Container(
//             margin: const EdgeInsets.all(20),
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.grey.shade200),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.book,
//                       color: Colors.blue.shade600,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         widget.lecture.subjectName,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildHeaderDetail(
//                       icon: Icons.access_time,
//                       text: _formatTimeRange(),
//                       color: Colors.blue.shade600,
//                     ),
//                     const SizedBox(width: 16),
//                     _buildHeaderDetail(
//                       icon: Icons.location_on,
//                       text: widget.lecture.roomNumber,
//                       color: Colors.green.shade600,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeaderDetail({
//     required IconData icon,
//     required String text,
//     required Color color,
//   }) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16, color: color),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey.shade700,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchAndFilterBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: TextField(
//               controller: _searchController,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//               decoration: InputDecoration(
//                 hintText: 'Search students...',
//                 hintStyle: TextStyle(color: Colors.grey.shade400),
//                 prefixIcon: Icon(
//                   Icons.search,
//                   color: Colors.blue.shade400,
//                   size: 20,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 16,
//                 ),
//               ),
//               onChanged: (value) => _filterStudents(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               _buildFilterChip('all', 'All Students'),
//               const SizedBox(width: 8),
//               _buildFilterChip('present', 'Present'),
//               const SizedBox(width: 8),
//               _buildFilterChip('absent', 'Absent'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }  
// Widget _buildFilterChip(String filter, String label) {
//     final isSelected = _selectedFilter == filter;
    
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedFilter = filter;
//         });
//         _filterStudents();
//         HapticFeedback.lightImpact();
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue.shade600 : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: isSelected ? Colors.white : Colors.grey.shade700,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceStats() {
//     final presentCount = _attendanceMap.values.where((present) => present).length;
//     final totalCount = _attendanceMap.length;
//     final absentCount = totalCount - presentCount;
    
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade600, Colors.blue.shade700],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(child: _buildStatItem('Total', totalCount.toString(), Icons.people)),
//           Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
//           Expanded(child: _buildStatItem('Present', presentCount.toString(), Icons.check_circle)),
//           Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
//           Expanded(child: _buildStatItem('Absent', absentCount.toString(), Icons.cancel)),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.white, size: 20),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.white.withOpacity(0.8),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStudentsList() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       child: ListView.builder(
//         itemCount: _filteredStudents.length,
//         itemBuilder: (context, index) {
//           final student = _filteredStudents[index];
          
//           return TweenAnimationBuilder<double>(
//             duration: Duration(milliseconds: 300 + (index * 50)),
//             tween: Tween(begin: 0.0, end: 1.0),
//             curve: Curves.easeOutBack,
//             builder: (context, animationValue, child) {
//               return Transform.translate(
//                 offset: Offset(30 * (1 - animationValue), 0),
//                 child: Opacity(
//                   opacity: animationValue.clamp(0.0, 1.0),
//                   child: _buildStudentCard(student),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildStudentCard(Map<String, dynamic> student) {
//     final isPresent = _attendanceMap[student['id']] ?? false;
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: GestureDetector(
//         onTap: () => _toggleAttendance(student['id']),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isPresent ? Colors.green.shade300 : Colors.grey.shade200,
//               width: isPresent ? 2 : 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: isPresent 
//                     ? Colors.green.withOpacity(0.1)
//                     : Colors.black.withOpacity(0.05),
//                 blurRadius: isPresent ? 8 : 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: isPresent ? Colors.green.shade600 : Colors.grey.shade300,
//                     width: 2,
//                   ),
//                 ),
//                 child: CircleAvatar(
//                   radius: 23,
//                   backgroundColor: Colors.grey.shade100,
//                   child: Icon(
//                     Icons.person,
//                     size: 24,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       student['name'],
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: isPresent ? Colors.green.shade700 : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       student['roll_number'],
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () => _toggleAttendance(student['id']),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: 60,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: isPresent ? Colors.green.shade600 : Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Stack(
//                     children: [
//                       AnimatedPositioned(
//                         duration: const Duration(milliseconds: 200),
//                         curve: Curves.easeInOut,
//                         left: isPresent ? 30 : 2,
//                         top: 2,
//                         child: Container(
//                           width: 28,
//                           height: 28,
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             isPresent ? Icons.check : Icons.close,
//                             size: 16,
//                             color: isPresent ? Colors.green.shade600 : Colors.grey.shade600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSubmitButton() {
//     final presentCount = _attendanceMap.values.where((present) => present).length;
//     final hasMarkedAttendance = presentCount > 0;
    
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: AnimatedBuilder(
//         animation: _submitController,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: _submitScaleAnimation.value,
//             child: Container(
//               width: double.infinity,
//               height: 50,
//               decoration: BoxDecoration(
//                 gradient: hasMarkedAttendance
//                     ? LinearGradient(
//                         colors: [Colors.green.shade600, Colors.green.shade700],
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                       )
//                     : null,
//                 color: hasMarkedAttendance ? null : Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: hasMarkedAttendance ? [
//                   BoxShadow(
//                     color: Colors.green.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ] : null,
//               ),
//               child: ElevatedButton.icon(
//                 onPressed: hasMarkedAttendance ? _submitAttendance : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 icon: _isSubmitting
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : Icon(
//                         Icons.check,
//                         color: hasMarkedAttendance ? Colors.white : Colors.grey.shade600,
//                         size: 20,
//                       ),
//                 label: Text(
//                   _isSubmitting ? 'Submitting...' : 'Submit Attendance',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: hasMarkedAttendance ? Colors.white : Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _toggleAttendance(String studentId) {
//     setState(() {
//       _attendanceMap[studentId] = !(_attendanceMap[studentId] ?? false);
//     });
    
//     HapticFeedback.lightImpact();
//     _filterStudents();
//   }

//   void _filterStudents() {
//     setState(() {
//       _filteredStudents = _allStudents.where((student) {
//         final searchQuery = _searchController.text.toLowerCase();
//         final matchesSearch = searchQuery.isEmpty ||
//             student['name'].toLowerCase().contains(searchQuery) ||
//             student['roll_number'].toLowerCase().contains(searchQuery);
        
//         final isPresent = _attendanceMap[student['id']] ?? false;
//         final matchesFilter = _selectedFilter == 'all' ||
//             (_selectedFilter == 'present' && isPresent) ||
//             (_selectedFilter == 'absent' && !isPresent);
        
//         return matchesSearch && matchesFilter;
//       }).toList();
//     });
//   }

//   void _submitAttendance() async {
//     if (_isSubmitting) return;
    
//     _submitController.forward().then((_) => _submitController.reverse());
    
//     setState(() {
//       _isSubmitting = true;
//     });
    
//     HapticFeedback.mediumImpact();
    
//     await Future.delayed(const Duration(milliseconds: 2000));
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(
//                 Icons.check_circle,
//                 color: Colors.white,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               const Text('Attendance submitted successfully!'),
//             ],
//           ),
//           backgroundColor: Colors.green.shade600,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           duration: const Duration(seconds: 3),
//         ),
//       );
      
//       Future.delayed(const Duration(milliseconds: 1500), () {
//         if (mounted) {
//           Navigator.of(context).popUntil((route) => route.isFirst);
//         }
//       });
//     }
//   }

//   String _formatTimeRange() {
//     return '${_formatTime(widget.lecture.startTime)} - ${_formatTime(widget.lecture.endTime)}';
//   }

//   String _formatTime(DateTime dateTime) {
//     final hour = dateTime.hour;
//     final minute = dateTime.minute.toString().padLeft(2, '0');
//     final period = hour >= 12 ? 'PM' : 'AM';
//     final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//     return '$displayHour:$minute $period';
//   }
// }