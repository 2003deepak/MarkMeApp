import 'package:json_annotation/json_annotation.dart';
import 'notification_model.dart';

part 'schedule_model.g.dart';

/// Enum for class/schedule status
/// Backend developers: Use these exact string values in your API responses
enum ScheduleStatus {
  @JsonValue('scheduled')
  scheduled,
  
  @JsonValue('ongoing')
  ongoing,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('cancelled')
  cancelled,
  
  @JsonValue('rescheduled')
  rescheduled,
}

/// Enum for class types
/// Backend developers: Use these exact string values in your API responses
enum ClassType {
  @JsonValue('lecture')
  lecture,
  
  @JsonValue('practical')
  practical,
  
  @JsonValue('tutorial')
  tutorial,
  
  @JsonValue('exam')
  exam,
  
  @JsonValue('assignment')
  assignment,
}

/// Main schedule/class data model
/// This model represents the structure expected from the backend API
/// 
/// Backend API Response Format:
/// {
///   "id": "unique_class_id",
///   "subject_name": "Computer Science",
///   "subject_code": "CS101",
///   "class_type": "lecture|practical|tutorial|exam|assignment",
///   "instructor_name": "Dr. John Smith",
///   "room_number": "Room 101",
///   "building": "Engineering Block",
///   "start_time": "2024-01-01T09:00:00Z", // ISO 8601 format
///   "end_time": "2024-01-01T10:30:00Z",   // ISO 8601 format
///   "duration_minutes": 90,
///   "status": "scheduled|ongoing|completed|cancelled|rescheduled",
///   "attendance_marked": false,
///   "attendance_percentage": 85.5, // optional, for completed classes
///   "description": "Introduction to Data Structures", // optional
///   "metadata": {
///     "semester": "Fall 2024",
///     "academic_year": "2024-25",
///     "credits": 3,
///     "is_mandatory": true
///   }
/// }
@JsonSerializable()
class ScheduleModel {
  /// Unique identifier for the class/schedule (provided by backend)
  final String id;
  
  /// Subject/course name
  /// Backend should provide full subject name (e.g., "Computer Science")
  @JsonKey(name: 'subject_name')
  final String subjectName;
  
  /// Subject/course code
  /// Backend should provide course code (e.g., "CS101")
  @JsonKey(name: 'subject_code')
  final String subjectCode;
  
  /// Type of class - determines icon and styling
  /// Backend should use exact enum values: 'lecture', 'practical', 'tutorial', 'exam', 'assignment'
  @JsonKey(name: 'class_type')
  final ClassType classType;
  
  /// Instructor/teacher name
  /// Backend should provide full instructor name
  @JsonKey(name: 'instructor_name')
  final String instructorName;
  
  /// Room number where class is held
  /// Backend should provide room identifier (e.g., "Room 101", "Lab A")
  @JsonKey(name: 'room_number')
  final String roomNumber;
  
  /// Building name or location
  /// Backend should provide building/location information
  final String? building;
  
  /// Class start time
  /// Backend should provide in ISO 8601 format (e.g., "2024-01-01T09:00:00Z")
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  
  /// Class end time
  /// Backend should provide in ISO 8601 format (e.g., "2024-01-01T10:30:00Z")
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  
  /// Duration in minutes
  /// Backend should calculate and provide duration
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  
  /// Current status of the class
  /// Backend should track and update status: 'scheduled', 'ongoing', 'completed', 'cancelled', 'rescheduled'
  final ScheduleStatus status;
  
  /// Whether attendance has been marked for this class
  /// Backend should track attendance marking status
  @JsonKey(name: 'attendance_marked')
  final bool attendanceMarked;
  
  /// Attendance percentage for completed classes
  /// Backend should provide this for completed classes only
  @JsonKey(name: 'attendance_percentage')
  final double? attendancePercentage;
  
  /// Optional description or notes about the class
  /// Backend can provide additional context
  final String? description;
  
  /// Optional additional data specific to class
  /// Backend can include context-specific information here:
  /// - semester, academic_year, credits, is_mandatory
  /// - assignment_due_date, exam_type, practical_requirements
  final Map<String, dynamic>? metadata;

  const ScheduleModel({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.classType,
    required this.instructorName,
    required this.roomNumber,
    this.building,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.status,
    this.attendanceMarked = false,
    this.attendancePercentage,
    this.description,
    this.metadata,
  });

  /// Factory constructor for creating ScheduleModel from JSON
  /// Backend developers: This handles the JSON deserialization automatically
  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  /// Converts ScheduleModel to JSON
  /// Used when sending data back to backend (e.g., for attendance updates)
  Map<String, dynamic> toJson() => _$ScheduleModelToJson(this);

  /// Creates a copy of the schedule with updated fields
  /// Useful for updating attendance status or other fields locally
  ScheduleModel copyWith({
    String? id,
    String? subjectName,
    String? subjectCode,
    ClassType? classType,
    String? instructorName,
    String? roomNumber,
    String? building,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    ScheduleStatus? status,
    bool? attendanceMarked,
    double? attendancePercentage,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      classType: classType ?? this.classType,
      instructorName: instructorName ?? this.instructorName,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      attendanceMarked: attendanceMarked ?? this.attendanceMarked,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper method to get formatted time range for display
  /// Returns user-friendly time format (e.g., "9:00 AM - 10:30 AM")
  String get formattedTimeRange {
    final startFormatted = _formatTime(startTime);
    final endFormatted = _formatTime(endTime);
    return '$startFormatted - $endFormatted';
  }

  /// Helper method to get formatted date for display
  /// Returns user-friendly date format (e.g., "Mon, Jan 15")
  String get formattedDate {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[startTime.weekday - 1];
    final month = months[startTime.month - 1];
    final day = startTime.day;
    
    return '$weekday, $month $day';
  }

  /// Helper method to check if class is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
           startTime.month == now.month &&
           startTime.day == now.day;
  }

  /// Helper method to check if class is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Helper method to check if class is upcoming (within next 30 minutes)
  bool get isUpcoming {
    final now = DateTime.now();
    final thirtyMinutesFromNow = now.add(const Duration(minutes: 30));
    return startTime.isAfter(now) && startTime.isBefore(thirtyMinutesFromNow);
  }

  /// Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}



/// Response model for paginated schedule API calls
/// Backend API should return schedules in this format for pagination support
/// 
/// Expected Backend Response Format:
/// {
///   "success": true,
///   "data": {
///     "schedules": [...], // Array of ScheduleModel objects
///     "pagination": {
///       "current_page": 1,
///       "total_pages": 10,
///       "total_count": 200,
///       "has_more": true
///     }
///   },
///   "message": "Success" // Optional success message
/// }
@JsonSerializable()
class ScheduleResponse {
  /// List of schedules for the current page/date range
  final List<ScheduleModel> schedules;
  
  /// Pagination information
  final PaginationInfo pagination;
  
  /// Success status from backend
  final bool success;
  
  /// Optional message from backend
  final String? message;

  const ScheduleResponse({
    required this.schedules,
    required this.pagination,
    this.success = true,
    this.message,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$ScheduleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleResponseToJson(this);
}

/// Request model for fetching schedules with filters
/// Used for API calls to get schedules with date range and filtering
/// 
/// Backend API Endpoint: GET /api/schedules
/// Query Parameters:
/// - start_date: string (ISO 8601 date format)
/// - end_date: string (ISO 8601 date format)
/// - class_type: string (optional) - filter by class type
/// - subject_code: string (optional) - filter by subject
/// - status: string (optional) - filter by status
@JsonSerializable()
class GetSchedulesRequest {
  /// Start date for schedule range (ISO 8601 format)
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  /// End date for schedule range (ISO 8601 format)
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  
  /// Optional filter by class type
  @JsonKey(name: 'class_type')
  final ClassType? classType;
  
  /// Optional filter by subject code
  @JsonKey(name: 'subject_code')
  final String? subjectCode;
  
  /// Optional filter by status
  final ScheduleStatus? status;

  const GetSchedulesRequest({
    required this.startDate,
    required this.endDate,
    this.classType,
    this.subjectCode,
    this.status,
  });

  factory GetSchedulesRequest.fromJson(Map<String, dynamic> json) =>
      _$GetSchedulesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetSchedulesRequestToJson(this);

  /// Converts to query parameters for HTTP GET request
  /// Backend developers can use these parameter names in their API
  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
    
    if (classType != null) {
      params['class_type'] = _getClassTypeString(classType!);
    }
    
    if (subjectCode != null) {
      params['subject_code'] = subjectCode!;
    }
    
    if (status != null) {
      params['status'] = _getStatusString(status!);
    }
    
    return params;
  }

  /// Helper method to convert ClassType enum to string for API calls
  String _getClassTypeString(ClassType type) {
    switch (type) {
      case ClassType.lecture:
        return 'lecture';
      case ClassType.practical:
        return 'practical';
      case ClassType.tutorial:
        return 'tutorial';
      case ClassType.exam:
        return 'exam';
      case ClassType.assignment:
        return 'assignment';
    }
  }

  /// Helper method to convert ScheduleStatus enum to string for API calls
  String _getStatusString(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.scheduled:
        return 'scheduled';
      case ScheduleStatus.ongoing:
        return 'ongoing';
      case ScheduleStatus.completed:
        return 'completed';
      case ScheduleStatus.cancelled:
        return 'cancelled';
      case ScheduleStatus.rescheduled:
        return 'rescheduled';
    }
  }
}

/// Request model for marking attendance
/// Used when sending attendance data to backend
/// 
/// Backend API Endpoint: POST /api/schedules/{id}/attendance
/// Request Body Format:
/// {
///   "schedule_id": "class_id",
///   "is_present": true,
///   "marked_at": "2024-01-01T10:00:00Z", // ISO 8601 format
///   "location": {
///     "latitude": 12.345678,
///     "longitude": 98.765432
///   }, // optional location verification
///   "notes": "Attended full class" // optional notes
/// }
@JsonSerializable()
class MarkAttendanceRequest {
  /// The schedule/class ID for attendance marking
  @JsonKey(name: 'schedule_id')
  final String scheduleId;
  
  /// Whether the student is present
  @JsonKey(name: 'is_present')
  final bool isPresent;
  
  /// When attendance was marked
  @JsonKey(name: 'marked_at')
  final DateTime markedAt;
  
  /// Optional location data for verification
  final Map<String, double>? location;
  
  /// Optional notes about attendance
  final String? notes;

  const MarkAttendanceRequest({
    required this.scheduleId,
    required this.isPresent,
    required this.markedAt,
    this.location,
    this.notes,
  });

  factory MarkAttendanceRequest.fromJson(Map<String, dynamic> json) =>
      _$MarkAttendanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MarkAttendanceRequestToJson(this);
}