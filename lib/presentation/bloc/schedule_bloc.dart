import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/schedule_model.dart';
import '../../data/services/schedule_service.dart';
import '../../data/services/notification_service.dart'; // Import for exception types

/// Events that can be dispatched to the ScheduleBloc
/// Backend developers: These events trigger API calls to your schedule endpoints
abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load schedules for a specific date range
/// Triggers API call to GET /api/schedules
class LoadSchedules extends ScheduleEvent {
  final DateTime startDate;
  final DateTime endDate;
  final bool isRefresh;
  final ClassType? filterType;
  final String? subjectCode;
  final ScheduleStatus? status;

  const LoadSchedules({
    required this.startDate,
    required this.endDate,
    this.isRefresh = false,
    this.filterType,
    this.subjectCode,
    this.status,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        isRefresh,
        filterType,
        subjectCode,
        status,
      ];
}

/// Event to load today's schedule
/// Triggers API call to GET /api/schedules/today
class LoadTodaySchedule extends ScheduleEvent {
  final bool isRefresh;

  const LoadTodaySchedule({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}

/// Event to load current week's schedule
/// Triggers API call to GET /api/schedules/week
class LoadWeekSchedule extends ScheduleEvent {
  final bool isRefresh;

  const LoadWeekSchedule({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}

/// Event to mark attendance for a class
/// Triggers API call to POST /api/schedules/{id}/attendance
class MarkAttendance extends ScheduleEvent {
  final String scheduleId;
  final bool isPresent;
  final Map<String, double>? location;
  final String? notes;

  const MarkAttendance({
    required this.scheduleId,
    required this.isPresent,
    this.location,
    this.notes,
  });

  @override
  List<Object?> get props => [scheduleId, isPresent, location, notes];
}

/// Event to update schedule information
/// Triggers API call to PUT /api/schedules/{id}
class UpdateSchedule extends ScheduleEvent {
  final String scheduleId;
  final ScheduleStatus? status;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? roomNumber;
  final String? notes;

  const UpdateSchedule({
    required this.scheduleId,
    this.status,
    this.startTime,
    this.endTime,
    this.roomNumber,
    this.notes,
  });

  @override
  List<Object?> get props => [
        scheduleId,
        status,
        startTime,
        endTime,
        roomNumber,
        notes,
      ];
}

/// States that the ScheduleBloc can be in
/// These states reflect the current status of backend API interactions
abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any schedules are loaded
class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

/// State when schedules are being loaded from backend
class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

/// State when schedules are being refreshed
class ScheduleRefreshing extends ScheduleState {
  final List<ScheduleModel> currentSchedules;

  const ScheduleRefreshing(this.currentSchedules);

  @override
  List<Object> get props => [currentSchedules];
}

/// State when schedules have been successfully loaded from backend
class ScheduleLoaded extends ScheduleState {
  final List<ScheduleModel> schedules;
  final DateTime startDate;
  final DateTime endDate;
  final ClassType? currentFilter;
  final String? subjectFilter;
  final ScheduleStatus? statusFilter;

  const ScheduleLoaded({
    required this.schedules,
    required this.startDate,
    required this.endDate,
    this.currentFilter,
    this.subjectFilter,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [
        schedules,
        startDate,
        endDate,
        currentFilter,
        subjectFilter,
        statusFilter,
      ];

  /// Creates a copy of the state with updated values
  ScheduleLoaded copyWith({
    List<ScheduleModel>? schedules,
    DateTime? startDate,
    DateTime? endDate,
    ClassType? currentFilter,
    String? subjectFilter,
    ScheduleStatus? statusFilter,
  }) {
    return ScheduleLoaded(
      schedules: schedules ?? this.schedules,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentFilter: currentFilter ?? this.currentFilter,
      subjectFilter: subjectFilter ?? this.subjectFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  /// Gets schedules for a specific date
  List<ScheduleModel> getSchedulesForDate(DateTime date) {
    return schedules.where((schedule) {
      return schedule.startTime.year == date.year &&
             schedule.startTime.month == date.month &&
             schedule.startTime.day == date.day;
    }).toList();
  }

  /// Gets today's schedules
  List<ScheduleModel> get todaySchedules {
    final today = DateTime.now();
    return getSchedulesForDate(today);
  }

  /// Gets upcoming schedules (next 24 hours)
  List<ScheduleModel> get upcomingSchedules {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    return schedules.where((schedule) {
      return schedule.startTime.isAfter(now) && 
             schedule.startTime.isBefore(tomorrow);
    }).toList();
  }

  /// Gets ongoing schedules
  List<ScheduleModel> get ongoingSchedules {
    final now = DateTime.now();
    
    return schedules.where((schedule) {
      return schedule.startTime.isBefore(now) && 
             schedule.endTime.isAfter(now);
    }).toList();
  }
}

/// State when an error occurs during backend communication
class ScheduleError extends ScheduleState {
  final String message;
  final List<ScheduleModel> currentSchedules;

  const ScheduleError(this.message, [this.currentSchedules = const []]);

  @override
  List<Object> get props => [message, currentSchedules];
}

/// State when attendance is being marked
class AttendanceMarking extends ScheduleState {
  final String scheduleId;
  final List<ScheduleModel> currentSchedules;

  const AttendanceMarking(this.scheduleId, this.currentSchedules);

  @override
  List<Object> get props => [scheduleId, currentSchedules];
}

/// State when attendance has been successfully marked
class AttendanceMarked extends ScheduleState {
  final String scheduleId;
  final bool isPresent;
  final List<ScheduleModel> updatedSchedules;

  const AttendanceMarked({
    required this.scheduleId,
    required this.isPresent,
    required this.updatedSchedules,
  });

  @override
  List<Object> get props => [scheduleId, isPresent, updatedSchedules];
}

/// BLoC for managing schedule state and backend interactions
/// This class handles all communication with the ScheduleService
/// and manages the UI state based on backend responses
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleService _scheduleService;

  ScheduleBloc({
    required ScheduleService scheduleService,
  })  : _scheduleService = scheduleService,
        super(const ScheduleInitial()) {
    
    // Register event handlers
    on<LoadSchedules>(_onLoadSchedules);
    on<LoadTodaySchedule>(_onLoadTodaySchedule);
    on<LoadWeekSchedule>(_onLoadWeekSchedule);
    on<MarkAttendance>(_onMarkAttendance);
    on<UpdateSchedule>(_onUpdateSchedule);
  }

  /// Handles loading schedules from backend for a date range
  /// This method calls the GET /api/schedules endpoint
  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      // If refreshing, show refreshing state with current schedules
      if (event.isRefresh && state is ScheduleLoaded) {
        final currentState = state as ScheduleLoaded;
        emit(ScheduleRefreshing(currentState.schedules));
      } else {
        // Show loading state for initial load
        emit(const ScheduleLoading());
      }

      print('🔄 Loading schedules from backend...'); // Debug log
      print('📅 Date Range: ${event.startDate} to ${event.endDate}'); // Debug log
      print('📋 Filters - Type: ${event.filterType}, Subject: ${event.subjectCode}, Status: ${event.status}'); // Debug log

      // Call backend API to fetch schedules
      final response = await _scheduleService.getSchedules(
        startDate: event.startDate,
        endDate: event.endDate,
        classType: event.filterType,
        subjectCode: event.subjectCode,
        status: event.status,
      );

      print('✅ Successfully loaded ${response.schedules.length} schedules'); // Debug log

      // Sort schedules by start time
      final sortedSchedules = response.schedules..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Emit loaded state with fetched schedules
      emit(ScheduleLoaded(
        schedules: sortedSchedules,
        startDate: event.startDate,
        endDate: event.endDate,
        currentFilter: event.filterType,
        subjectFilter: event.subjectCode,
        statusFilter: event.status,
      ));

    } catch (error) {
      print('❌ Error loading schedules: $error'); // Debug log
      
      // Preserve current schedules if available during error
      final currentSchedules = state is ScheduleLoaded
          ? (state as ScheduleLoaded).schedules
          : <ScheduleModel>[];

      // Emit error state with user-friendly message
      String errorMessage = _getErrorMessage(error);
      emit(ScheduleError(errorMessage, currentSchedules));
    }
  }

  /// Handles loading today's schedule
  /// This method calls the GET /api/schedules/today endpoint
  Future<void> _onLoadTodaySchedule(
    LoadTodaySchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      // If refreshing, show refreshing state with current schedules
      if (event.isRefresh && state is ScheduleLoaded) {
        final currentState = state as ScheduleLoaded;
        emit(ScheduleRefreshing(currentState.schedules));
      } else {
        emit(const ScheduleLoading());
      }

      print('🔄 Loading today\'s schedule from backend...'); // Debug log

      // Call backend API to fetch today's schedule
      final schedules = await _scheduleService.getTodaySchedule();

      print('✅ Successfully loaded ${schedules.length} classes for today'); // Debug log

      // Sort schedules by start time
      final sortedSchedules = schedules..sort((a, b) => a.startTime.compareTo(b.startTime));

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Emit loaded state
      emit(ScheduleLoaded(
        schedules: sortedSchedules,
        startDate: startOfDay,
        endDate: endOfDay,
      ));

    } catch (error) {
      print('❌ Error loading today\'s schedule: $error'); // Debug log
      
      final currentSchedules = state is ScheduleLoaded
          ? (state as ScheduleLoaded).schedules
          : <ScheduleModel>[];

      String errorMessage = _getErrorMessage(error);
      emit(ScheduleError(errorMessage, currentSchedules));
    }
  }

  /// Handles loading current week's schedule
  /// This method calls the GET /api/schedules/week endpoint
  Future<void> _onLoadWeekSchedule(
    LoadWeekSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      // If refreshing, show refreshing state with current schedules
      if (event.isRefresh && state is ScheduleLoaded) {
        final currentState = state as ScheduleLoaded;
        emit(ScheduleRefreshing(currentState.schedules));
      } else {
        emit(const ScheduleLoading());
      }

      print('🔄 Loading week\'s schedule from backend...'); // Debug log

      // Call backend API to fetch week's schedule
      final schedules = await _scheduleService.getWeekSchedule();

      print('✅ Successfully loaded ${schedules.length} classes for this week'); // Debug log

      // Sort schedules by start time
      final sortedSchedules = schedules..sort((a, b) => a.startTime.compareTo(b.startTime));

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

      // Emit loaded state
      emit(ScheduleLoaded(
        schedules: sortedSchedules,
        startDate: startDate,
        endDate: endDate,
      ));

    } catch (error) {
      print('❌ Error loading week\'s schedule: $error'); // Debug log
      
      final currentSchedules = state is ScheduleLoaded
          ? (state as ScheduleLoaded).schedules
          : <ScheduleModel>[];

      String errorMessage = _getErrorMessage(error);
      emit(ScheduleError(errorMessage, currentSchedules));
    }
  }

  /// Handles marking attendance for a class
  /// This method calls the POST /api/schedules/{id}/attendance endpoint
  Future<void> _onMarkAttendance(
    MarkAttendance event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is! ScheduleLoaded) return;

    final currentState = state as ScheduleLoaded;

    try {
      // Show attendance marking state
      emit(AttendanceMarking(event.scheduleId, currentState.schedules));

      print('🔄 Marking attendance for schedule: ${event.scheduleId}'); // Debug log
      print('📍 Present: ${event.isPresent}, Location: ${event.location}'); // Debug log

      // Call backend API to mark attendance
      final success = await _scheduleService.markAttendance(
        scheduleId: event.scheduleId,
        isPresent: event.isPresent,
        location: event.location,
        notes: event.notes,
      );

      if (success) {
        print('✅ Successfully marked attendance'); // Debug log

        // Update the schedule in the local list
        final updatedSchedules = currentState.schedules.map((schedule) {
          if (schedule.id == event.scheduleId) {
            return schedule.copyWith(attendanceMarked: true);
          }
          return schedule;
        }).toList();

        // Emit attendance marked state
        emit(AttendanceMarked(
          scheduleId: event.scheduleId,
          isPresent: event.isPresent,
          updatedSchedules: updatedSchedules,
        ));

        // Then emit updated loaded state
        emit(currentState.copyWith(schedules: updatedSchedules));
      } else {
        throw Exception('Failed to mark attendance');
      }

    } catch (error) {
      print('❌ Error marking attendance: $error'); // Debug log
      
      String errorMessage = _getErrorMessage(error);
      emit(ScheduleError(errorMessage, currentState.schedules));
    }
  }

  /// Handles updating schedule information
  /// This method calls the PUT /api/schedules/{id} endpoint
  Future<void> _onUpdateSchedule(
    UpdateSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is! ScheduleLoaded) return;

    final currentState = state as ScheduleLoaded;

    try {
      print('🔄 Updating schedule: ${event.scheduleId}'); // Debug log

      // Call backend API to update schedule
      final updatedSchedule = await _scheduleService.updateSchedule(
        scheduleId: event.scheduleId,
        status: event.status,
        startTime: event.startTime,
        endTime: event.endTime,
        roomNumber: event.roomNumber,
        notes: event.notes,
      );

      print('✅ Successfully updated schedule'); // Debug log

      // Update the schedule in the local list
      final updatedSchedules = currentState.schedules.map((schedule) {
        if (schedule.id == event.scheduleId) {
          return updatedSchedule;
        }
        return schedule;
      }).toList();

      // Emit updated state
      emit(currentState.copyWith(schedules: updatedSchedules));

    } catch (error) {
      print('❌ Error updating schedule: $error'); // Debug log
      
      String errorMessage = _getErrorMessage(error);
      emit(ScheduleError(errorMessage, currentState.schedules));
    }
  }

  /// Converts backend errors to user-friendly messages
  /// Backend developers: These are the error types your API should handle
  String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    } else if (error is ForbiddenException) {
      return 'You don\'t have permission to access schedules.';
    } else if (error is NotFoundException) {
      return 'Schedule service is currently unavailable.';
    } else if (error is RateLimitException) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (error is ServerException) {
      return 'Server error occurred. Please try again later.';
    } else if (error is DataException) {
      return 'Invalid data received. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _scheduleService.dispose();
    return super.close();
  }
}