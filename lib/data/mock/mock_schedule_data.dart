import '../models/schedule_model.dart';
import '../models/notification_model.dart';

/// Mock schedule data for UI testing when backend is not available
/// Backend developers: This shows the expected data structure for your API
class MockScheduleData {
  /// Mock schedules list with different types and statuses
  /// This demonstrates the variety of schedules your backend should support
  static List<ScheduleModel> getMockSchedules() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      // Today's classes
      
      // Ongoing class (if current time allows)
      ScheduleModel(
        id: 'schedule_001',
        subjectName: 'Computer Science',
        subjectCode: 'CS101',
        classType: ClassType.lecture,
        instructorName: 'Dr. Sarah Johnson',
        roomNumber: 'Room 101',
        building: 'Engineering Block',
        startTime: today.add(const Duration(hours: 9)),
        endTime: today.add(const Duration(hours: 10, minutes: 30)),
        durationMinutes: 90,
        status: now.hour >= 9 && now.hour < 11 ? ScheduleStatus.ongoing : ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Introduction to Data Structures and Algorithms',
        metadata: {
          'semester': 'Fall 2024',
          'academic_year': '2024-25',
          'credits': 3,
          'is_mandatory': true,
          'course_code': 'CSE101',
        },
      ),
      
      // Upcoming class today
      ScheduleModel(
        id: 'schedule_002',
        subjectName: 'Mathematics',
        subjectCode: 'MATH201',
        classType: ClassType.tutorial,
        instructorName: 'Prof. Michael Chen',
        roomNumber: 'Room 205',
        building: 'Science Block',
        startTime: today.add(const Duration(hours: 11)),
        endTime: today.add(const Duration(hours: 12)),
        durationMinutes: 60,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Calculus and Linear Algebra Tutorial',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 2,
          'tutorial_type': 'problem_solving',
        },
      ),
      
      // Practical class today
      ScheduleModel(
        id: 'schedule_003',
        subjectName: 'Database Systems',
        subjectCode: 'CS301',
        classType: ClassType.practical,
        instructorName: 'Dr. Emily Rodriguez',
        roomNumber: 'Lab A',
        building: 'Computer Lab Block',
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 16)),
        durationMinutes: 120,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'SQL Queries and Database Design Lab',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 1,
          'lab_equipment': 'MySQL Workbench',
          'group_size': 2,
        },
      ),
      
      // Completed class today (if applicable)
      if (now.hour > 8)
        ScheduleModel(
          id: 'schedule_004',
          subjectName: 'Physics',
          subjectCode: 'PHY101',
          classType: ClassType.lecture,
          instructorName: 'Dr. Robert Wilson',
          roomNumber: 'Room 301',
          building: 'Science Block',
          startTime: today.add(const Duration(hours: 8)),
          endTime: today.add(const Duration(hours: 9)),
          durationMinutes: 60,
          status: ScheduleStatus.completed,
          attendanceMarked: true,
          attendancePercentage: 92.5,
          description: 'Quantum Mechanics Fundamentals',
          metadata: {
            'semester': 'Fall 2024',
            'credits': 3,
            'attendance_status': 'present',
          },
        ),
      
      // Tomorrow's classes
      
      ScheduleModel(
        id: 'schedule_005',
        subjectName: 'Software Engineering',
        subjectCode: 'CS401',
        classType: ClassType.lecture,
        instructorName: 'Dr. Lisa Anderson',
        roomNumber: 'Room 102',
        building: 'Engineering Block',
        startTime: today.add(const Duration(days: 1, hours: 9)),
        endTime: today.add(const Duration(days: 1, hours: 10, minutes: 30)),
        durationMinutes: 90,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Agile Development Methodologies',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 3,
          'project_based': true,
        },
      ),
      
      ScheduleModel(
        id: 'schedule_006',
        subjectName: 'Data Structures',
        subjectCode: 'CS201',
        classType: ClassType.practical,
        instructorName: 'Prof. David Kim',
        roomNumber: 'Lab B',
        building: 'Computer Lab Block',
        startTime: today.add(const Duration(days: 1, hours: 11)),
        endTime: today.add(const Duration(days: 1, hours: 13)),
        durationMinutes: 120,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Trees and Graphs Implementation',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 1,
          'programming_language': 'Java',
        },
      ),
      
      // Day after tomorrow - Exam
      ScheduleModel(
        id: 'schedule_007',
        subjectName: 'Operating Systems',
        subjectCode: 'CS302',
        classType: ClassType.exam,
        instructorName: 'Dr. Jennifer Brown',
        roomNumber: 'Exam Hall 1',
        building: 'Main Block',
        startTime: today.add(const Duration(days: 2, hours: 10)),
        endTime: today.add(const Duration(days: 2, hours: 12)),
        durationMinutes: 120,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Mid-term Examination - Process Management and Memory',
        metadata: {
          'semester': 'Fall 2024',
          'exam_type': 'mid-term',
          'total_marks': 100,
          'duration': '2 hours',
        },
      ),
      
      // This week - Various classes
      
      ScheduleModel(
        id: 'schedule_008',
        subjectName: 'Web Development',
        subjectCode: 'CS501',
        classType: ClassType.practical,
        instructorName: 'Ms. Rachel Green',
        roomNumber: 'Lab C',
        building: 'Computer Lab Block',
        startTime: today.add(const Duration(days: 3, hours: 14)),
        endTime: today.add(const Duration(days: 3, hours: 16)),
        durationMinutes: 120,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'React.js and Node.js Development',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 2,
          'framework': 'React',
          'backend': 'Node.js',
        },
      ),
      
      ScheduleModel(
        id: 'schedule_009',
        subjectName: 'Machine Learning',
        subjectCode: 'CS601',
        classType: ClassType.lecture,
        instructorName: 'Dr. Alex Thompson',
        roomNumber: 'Room 401',
        building: 'Research Block',
        startTime: today.add(const Duration(days: 4, hours: 10)),
        endTime: today.add(const Duration(days: 4, hours: 11, minutes: 30)),
        durationMinutes: 90,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Neural Networks and Deep Learning',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 3,
          'prerequisites': ['Statistics', 'Linear Algebra'],
          'tools': ['Python', 'TensorFlow'],
        },
      ),
      
      // Cancelled class example
      ScheduleModel(
        id: 'schedule_010',
        subjectName: 'Network Security',
        subjectCode: 'CS701',
        classType: ClassType.lecture,
        instructorName: 'Dr. Mark Davis',
        roomNumber: 'Room 501',
        building: 'Engineering Block',
        startTime: today.add(const Duration(days: 5, hours: 9)),
        endTime: today.add(const Duration(days: 5, hours: 10, minutes: 30)),
        durationMinutes: 90,
        status: ScheduleStatus.cancelled,
        attendanceMarked: false,
        description: 'Cryptography and Security Protocols - CANCELLED',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 3,
          'cancellation_reason': 'Faculty emergency',
          'makeup_scheduled': true,
          'makeup_date': '2024-02-05T09:00:00Z',
        },
      ),
      
      // Rescheduled class example
      ScheduleModel(
        id: 'schedule_011',
        subjectName: 'Artificial Intelligence',
        subjectCode: 'CS602',
        classType: ClassType.tutorial,
        instructorName: 'Prof. Susan Miller',
        roomNumber: 'Room 302',
        building: 'Research Block',
        startTime: today.add(const Duration(days: 6, hours: 15)),
        endTime: today.add(const Duration(days: 6, hours: 16)),
        durationMinutes: 60,
        status: ScheduleStatus.rescheduled,
        attendanceMarked: false,
        description: 'AI Algorithms Tutorial - Rescheduled from morning',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 1,
          'original_time': '09:00',
          'reschedule_reason': 'Room conflict',
        },
      ),
      
      // Assignment submission
      ScheduleModel(
        id: 'schedule_012',
        subjectName: 'Software Project',
        subjectCode: 'CS801',
        classType: ClassType.assignment,
        instructorName: 'Dr. Kevin Lee',
        roomNumber: 'Online Submission',
        building: 'Virtual',
        startTime: today.add(const Duration(days: 7, hours: 23, minutes: 59)),
        endTime: today.add(const Duration(days: 7, hours: 23, minutes: 59)),
        durationMinutes: 0,
        status: ScheduleStatus.scheduled,
        attendanceMarked: false,
        description: 'Final Project Submission Deadline',
        metadata: {
          'semester': 'Fall 2024',
          'credits': 4,
          'submission_type': 'online',
          'file_format': 'ZIP',
          'max_size': '50MB',
          'late_penalty': '10% per day',
        },
      ),
    ];
  }

  /// Get schedules for a specific date range
  static List<ScheduleModel> getSchedulesForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    ClassType? classType,
    String? subjectCode,
    ScheduleStatus? status,
  }) {
    var schedules = getMockSchedules();
    
    // Filter by date range
    schedules = schedules.where((schedule) {
      return schedule.startTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
             schedule.startTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
    
    // Apply filters
    if (classType != null) {
      schedules = schedules.where((schedule) => schedule.classType == classType).toList();
    }
    
    if (subjectCode != null) {
      schedules = schedules.where((schedule) => 
          schedule.subjectCode.toLowerCase().contains(subjectCode.toLowerCase())).toList();
    }
    
    if (status != null) {
      schedules = schedules.where((schedule) => schedule.status == status).toList();
    }
    
    // Sort by start time
    schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return schedules;
  }

  /// Get today's schedules
  static List<ScheduleModel> getTodaySchedules() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getSchedulesForDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get current week's schedules
  static List<ScheduleModel> getWeekSchedules() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
    
    return getSchedulesForDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mock schedule response with pagination
  /// Backend developers: This shows the expected API response structure
  static ScheduleResponse getMockScheduleResponse({
    required DateTime startDate,
    required DateTime endDate,
    ClassType? classType,
    String? subjectCode,
    ScheduleStatus? status,
  }) {
    final schedules = getSchedulesForDateRange(
      startDate: startDate,
      endDate: endDate,
      classType: classType,
      subjectCode: subjectCode,
      status: status,
    );
    
    return ScheduleResponse(
      schedules: schedules,
      pagination: PaginationInfo(
        currentPage: 1,
        totalPages: 1,
        totalCount: schedules.length,
        hasMore: false,
      ),
      success: true,
      message: 'Mock schedules loaded successfully',
    );
  }

  /// Simulate marking attendance
  static bool markAttendance({
    required String scheduleId,
    required bool isPresent,
    Map<String, double>? location,
    String? notes,
  }) {
    // In real implementation, this would call the backend API
    // For mock, we simulate some validation
    
    final schedule = getMockSchedules().firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw Exception('Schedule not found'),
    );
    
    // Simulate attendance window validation
    final now = DateTime.now();
    final canMarkAttendance = now.isAfter(schedule.startTime.subtract(const Duration(minutes: 15))) &&
                             now.isBefore(schedule.endTime.add(const Duration(minutes: 30)));
    
    if (!canMarkAttendance) {
      throw Exception('Attendance can only be marked during class time or within 30 minutes after class ends');
    }
    
    // Simulate success
    return true;
  }

  /// Simulate updating schedule
  static ScheduleModel updateSchedule({
    required String scheduleId,
    ScheduleStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? roomNumber,
    String? notes,
  }) {
    // In real implementation, this would call the backend API
    // For mock, we just return the updated schedule
    
    final originalSchedule = getMockSchedules().firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw Exception('Schedule not found'),
    );
    
    return originalSchedule.copyWith(
      status: status,
      startTime: startTime,
      endTime: endTime,
      roomNumber: roomNumber,
    );
  }

  /// Get upcoming schedules (next 24 hours)
  static List<ScheduleModel> getUpcomingSchedules() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    return getMockSchedules().where((schedule) {
      return schedule.startTime.isAfter(now) && 
             schedule.startTime.isBefore(tomorrow) &&
             schedule.status == ScheduleStatus.scheduled;
    }).toList();
  }

  /// Get ongoing schedules
  static List<ScheduleModel> getOngoingSchedules() {
    final now = DateTime.now();
    
    return getMockSchedules().where((schedule) {
      return schedule.startTime.isBefore(now) && 
             schedule.endTime.isAfter(now) &&
             schedule.status == ScheduleStatus.ongoing;
    }).toList();
  }

  /// Get attendance statistics
  static Map<String, dynamic> getAttendanceStats() {
    final schedules = getMockSchedules();
    final completedSchedules = schedules.where((s) => s.status == ScheduleStatus.completed).toList();
    final attendedSchedules = completedSchedules.where((s) => s.attendanceMarked).toList();
    
    final totalClasses = completedSchedules.length;
    final attendedClasses = attendedSchedules.length;
    final attendancePercentage = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;
    
    return {
      'total_classes': totalClasses,
      'attended_classes': attendedClasses,
      'missed_classes': totalClasses - attendedClasses,
      'attendance_percentage': attendancePercentage,
      'status': attendancePercentage >= 75 ? 'good' : attendancePercentage >= 50 ? 'warning' : 'critical',
    };
  }
}