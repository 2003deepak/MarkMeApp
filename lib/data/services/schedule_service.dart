import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/schedule_model.dart';
import '../models/notification_model.dart'; // Import for PaginationInfo
import '../mock/mock_schedule_data.dart';
import 'notification_service.dart'; // Import for exception types

/// Service class for handling all schedule-related API calls
/// This class provides methods for backend communication with detailed error handling
/// 
/// Backend developers should implement the following endpoints:
/// - GET /api/schedules - Fetch schedules with date range and filters
/// - POST /api/schedules/{id}/attendance - Mark attendance for a class
/// - GET /api/schedules/today - Get today's schedule
/// - GET /api/schedules/week - Get current week's schedule
/// - PUT /api/schedules/{id} - Update schedule information
class ScheduleService {
  /// Base URL for the API
  /// Backend developers should replace this with their actual API base URL
  static const String _baseUrl = 'https://your-api-domain.com/api';
  
  /// Flag to use mock data when backend is not available
  /// Set this to false when backend is ready
  static const bool useMockData = true;
  
  /// HTTP client instance for making requests
  final http.Client _client;
  
  /// Authentication token for API requests
  /// This should be obtained from your authentication service
  String? _authToken;

  ScheduleService({http.Client? client}) : _client = client ?? http.Client();

  /// Sets the authentication token for API requests
  /// Call this method after user login to authenticate API calls
  /// 
  /// Backend developers: All API endpoints should validate this JWT token
  /// Expected header format: "Authorization: Bearer {token}"
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Gets common headers for API requests
  /// Backend developers: Expect these headers in all API calls
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  /// Fetches schedules from the backend with date range and filtering
  /// 
  /// Backend API Endpoint: GET /api/schedules
  /// 
  /// Query Parameters:
  /// - start_date: string (ISO 8601 format, e.g., "2024-01-01T00:00:00Z")
  /// - end_date: string (ISO 8601 format, e.g., "2024-01-07T23:59:59Z")
  /// - class_type: string (optional filter: 'lecture', 'practical', 'tutorial', 'exam', 'assignment')
  /// - subject_code: string (optional filter by subject code)
  /// - status: string (optional filter: 'scheduled', 'ongoing', 'completed', 'cancelled', 'rescheduled')
  /// 
  /// Expected Backend Response (200 OK):
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "schedules": [
  ///       {
  ///         "id": "schedule_id",
  ///         "subject_name": "Computer Science",
  ///         "subject_code": "CS101",
  ///         "class_type": "lecture",
  ///         "instructor_name": "Dr. John Smith",
  ///         "room_number": "Room 101",
  ///         "building": "Engineering Block",
  ///         "start_time": "2024-01-01T09:00:00Z",
  ///         "end_time": "2024-01-01T10:30:00Z",
  ///         "duration_minutes": 90,
  ///         "status": "scheduled",
  ///         "attendance_marked": false,
  ///         "description": "Introduction to Data Structures",
  ///         "metadata": {
  ///           "semester": "Fall 2024",
  ///           "credits": 3
  ///         }
  ///       }
  ///     ],
  ///     "pagination": {
  ///       "current_page": 1,
  ///       "total_pages": 1,
  ///       "total_count": 10,
  ///       "has_more": false
  ///     }
  ///   }
  /// }
  /// 
  /// Backend Error Responses:
  /// - 401 Unauthorized: Invalid or expired token
  /// - 403 Forbidden: User doesn't have permission
  /// - 500 Internal Server Error: Server-side error
  Future<ScheduleResponse> getSchedules({
    required DateTime startDate,
    required DateTime endDate,
    ClassType? classType,
    String? subjectCode,
    ScheduleStatus? status,
  }) async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock schedule data (backend not connected)');
      print('📅 Date Range: $startDate to $endDate');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      return MockScheduleData.getMockScheduleResponse(
        startDate: startDate,
        endDate: endDate,
        classType: classType,
        subjectCode: subjectCode,
        status: status,
      );
    }
    
    try {
      // Construct query parameters
      final queryParams = <String, String>{
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };
      
      if (classType != null) {
        queryParams['class_type'] = _getClassTypeString(classType);
      }
      
      if (subjectCode != null) {
        queryParams['subject_code'] = subjectCode;
      }
      
      if (status != null) {
        queryParams['status'] = _getStatusString(status);
      }
      
      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl/schedules').replace(
        queryParameters: queryParams,
      );
      
      print('🌐 API Call: GET $uri'); // Debug log for backend developers
      print('📋 Headers: $_headers'); // Debug log for backend developers
      
      // Make HTTP GET request
      final response = await _client.get(uri, headers: _headers);
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      print('📥 Response Body: ${response.body}'); // Debug log
      
      // Handle different HTTP status codes
      switch (response.statusCode) {
        case 200:
          // Success - parse response
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          
          // Backend developers: Ensure your API returns data in this structure
          if (jsonData['success'] == true && jsonData['data'] != null) {
            final data = jsonData['data'] as Map<String, dynamic>;
            
            // Parse schedules array
            final schedulesJson = data['schedules'] as List<dynamic>;
            final schedules = schedulesJson
                .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
                .toList();
            
            // Parse pagination info
            final paginationJson = data['pagination'] as Map<String, dynamic>;
            final pagination = PaginationInfo.fromJson(paginationJson);
            
            return ScheduleResponse(
              schedules: schedules,
              pagination: pagination,
              success: true,
              message: jsonData['message'] as String?,
            );
          } else {
            throw Exception('Invalid response format from server');
          }
          
        case 401:
          throw UnauthorizedException('Authentication token is invalid or expired');
          
        case 403:
          throw ForbiddenException('You don\'t have permission to access schedules');
          
        case 404:
          throw NotFoundException('Schedules endpoint not found');
          
        case 429:
          throw RateLimitException('Too many requests. Please try again later');
          
        case 500:
        case 502:
        case 503:
          throw ServerException('Server error occurred. Please try again later');
          
        default:
          throw Exception('Unexpected error: ${response.statusCode} - ${response.body}');
      }
      
    } on SocketException {
      throw NetworkException('No internet connection. Please check your network and try again');
    } on FormatException {
      throw DataException('Invalid data received from server');
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to fetch schedules: $e');
    }
  }

  /// Fetches today's schedule
  /// 
  /// Backend API Endpoint: GET /api/schedules/today
  /// 
  /// Expected Backend Response (200 OK):
  /// Same format as getSchedules but filtered for today's date
  Future<List<ScheduleModel>> getTodaySchedule() async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock today\'s schedule (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));
      
      return MockScheduleData.getTodaySchedules();
    }
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final response = await getSchedules(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      return response.schedules;
      
    } catch (e) {
      throw Exception('Failed to fetch today\'s schedule: $e');
    }
  }

  /// Fetches current week's schedule
  /// 
  /// Backend API Endpoint: GET /api/schedules/week
  /// 
  /// Expected Backend Response (200 OK):
  /// Same format as getSchedules but filtered for current week
  Future<List<ScheduleModel>> getWeekSchedule() async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock week\'s schedule (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 700));
      
      return MockScheduleData.getWeekSchedules();
    }
    
    try {
      final now = DateTime.now();
      
      // Calculate start of week (Monday)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      // Calculate end of week (Sunday)
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
      
      final response = await getSchedules(
        startDate: startDate,
        endDate: endDate,
      );
      
      return response.schedules;
      
    } catch (e) {
      throw Exception('Failed to fetch week\'s schedule: $e');
    }
  }

  /// Marks attendance for a specific class/schedule
  /// 
  /// Backend API Endpoint: POST /api/schedules/{id}/attendance
  /// 
  /// Request Body:
  /// {
  ///   "schedule_id": "class_id",
  ///   "is_present": true,
  ///   "marked_at": "2024-01-01T10:00:00Z",
  ///   "location": {
  ///     "latitude": 12.345678,
  ///     "longitude": 98.765432
  ///   }, // optional for location-based verification
  ///   "notes": "Attended full class" // optional
  /// }
  /// 
  /// Expected Backend Response (200 OK):
  /// {
  ///   "success": true,
  ///   "message": "Attendance marked successfully",
  ///   "data": {
  ///     "attendance_id": "attendance_record_id",
  ///     "marked_at": "2024-01-01T10:00:00Z",
  ///     "status": "present"
  ///   }
  /// }
  /// 
  /// Backend developers should:
  /// 1. Validate the schedule ID exists and belongs to the authenticated user
  /// 2. Check if attendance can be marked (time window, location if required)
  /// 3. Create attendance record in the database
  /// 4. Update schedule's attendance_marked status
  /// 5. Return success confirmation with attendance details
  Future<bool> markAttendance({
    required String scheduleId,
    required bool isPresent,
    Map<String, double>? location,
    String? notes,
  }) async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock attendance marking (backend not connected)');
      print('📍 Schedule ID: $scheduleId, Present: $isPresent');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      return MockScheduleData.markAttendance(
        scheduleId: scheduleId,
        isPresent: isPresent,
        location: location,
        notes: notes,
      );
    }
    
    try {
      final url = '$_baseUrl/schedules/$scheduleId/attendance';
      final requestBody = {
        'schedule_id': scheduleId,
        'is_present': isPresent,
        'marked_at': DateTime.now().toIso8601String(),
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      };
      
      print('🌐 API Call: POST $url'); // Debug log
      print('📤 Request Body: ${json.encode(requestBody)}'); // Debug log
      
      final response = await _client.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      );
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      print('📥 Response Body: ${response.body}'); // Debug log
      
      switch (response.statusCode) {
        case 200:
        case 201:
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          return jsonData['success'] == true;
          
        case 400:
          // Bad request - attendance window closed, already marked, etc.
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          throw Exception(jsonData['message'] ?? 'Cannot mark attendance at this time');
          
        case 401:
          throw UnauthorizedException('Authentication required');
          
        case 403:
          throw ForbiddenException('You don\'t have permission to mark attendance for this class');
          
        case 404:
          throw NotFoundException('Schedule not found');
          
        case 409:
          // Conflict - attendance already marked
          throw Exception('Attendance has already been marked for this class');
          
        default:
          throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
      
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to mark attendance: $e');
    }
  }

  /// Updates schedule information (for rescheduling, cancellation, etc.)
  /// 
  /// Backend API Endpoint: PUT /api/schedules/{id}
  /// 
  /// Request Body:
  /// {
  ///   "status": "cancelled|rescheduled",
  ///   "start_time": "2024-01-01T10:00:00Z", // for rescheduling
  ///   "end_time": "2024-01-01T11:30:00Z",   // for rescheduling
  ///   "room_number": "New Room 102",        // for room changes
  ///   "notes": "Class cancelled due to emergency" // optional
  /// }
  /// 
  /// Expected Backend Response (200 OK):
  /// {
  ///   "success": true,
  ///   "message": "Schedule updated successfully",
  ///   "data": {
  ///     // Updated schedule object
  ///   }
  /// }
  Future<ScheduleModel> updateSchedule({
    required String scheduleId,
    ScheduleStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? roomNumber,
    String? notes,
  }) async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock schedule update (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return MockScheduleData.updateSchedule(
        scheduleId: scheduleId,
        status: status,
        startTime: startTime,
        endTime: endTime,
        roomNumber: roomNumber,
        notes: notes,
      );
    }
    
    try {
      final url = '$_baseUrl/schedules/$scheduleId';
      final requestBody = <String, dynamic>{};
      
      if (status != null) {
        requestBody['status'] = _getStatusString(status);
      }
      
      if (startTime != null) {
        requestBody['start_time'] = startTime.toIso8601String();
      }
      
      if (endTime != null) {
        requestBody['end_time'] = endTime.toIso8601String();
      }
      
      if (roomNumber != null) {
        requestBody['room_number'] = roomNumber;
      }
      
      if (notes != null) {
        requestBody['notes'] = notes;
      }
      
      print('🌐 API Call: PUT $url'); // Debug log
      print('📤 Request Body: ${json.encode(requestBody)}'); // Debug log
      
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      );
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      print('📥 Response Body: ${response.body}'); // Debug log
      
      switch (response.statusCode) {
        case 200:
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          if (jsonData['success'] == true && jsonData['data'] != null) {
            return ScheduleModel.fromJson(jsonData['data'] as Map<String, dynamic>);
          } else {
            throw Exception('Invalid response format from server');
          }
          
        case 401:
          throw UnauthorizedException('Authentication required');
          
        case 403:
          throw ForbiddenException('You don\'t have permission to update this schedule');
          
        case 404:
          throw NotFoundException('Schedule not found');
          
        default:
          throw Exception('Failed to update schedule: ${response.statusCode}');
      }
      
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// Helper method to convert ClassType enum to string for API calls
  /// Backend developers should use these exact string values
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
  /// Backend developers should use these exact string values
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

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }
}