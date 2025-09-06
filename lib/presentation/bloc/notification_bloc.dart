import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

/// Events that can be dispatched to the NotificationBloc
/// Backend developers: These events trigger API calls to your endpoints
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notifications (initial load or refresh)
/// Triggers API call to GET /api/notifications
class LoadNotifications extends NotificationEvent {
  final bool isRefresh;
  final NotificationType? filterType;
  final bool unreadOnly;

  const LoadNotifications({
    this.isRefresh = false,
    this.filterType,
    this.unreadOnly = false,
  });

  @override
  List<Object?> get props => [isRefresh, filterType, unreadOnly];
}

/// Event to load more notifications (pagination)
/// Triggers API call to GET /api/notifications with next page
class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}

/// Event to mark a notification as read
/// Triggers API call to PUT /api/notifications/{id}/status
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

/// Event to delete/dismiss a notification
/// Triggers API call to DELETE /api/notifications/{id}
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

/// Event to mark all notifications as read
/// Triggers API call to POST /api/notifications/mark-all-read
class MarkAllAsRead extends NotificationEvent {
  const MarkAllAsRead();
}

/// States that the NotificationBloc can be in
/// These states reflect the current status of backend API interactions
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any notifications are loaded
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// State when notifications are being loaded from backend
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// State when notifications are being refreshed (pull-to-refresh)
class NotificationRefreshing extends NotificationState {
  final List<NotificationModel> currentNotifications;

  const NotificationRefreshing(this.currentNotifications);

  @override
  List<Object> get props => [currentNotifications];
}

/// State when more notifications are being loaded (pagination)
class NotificationLoadingMore extends NotificationState {
  final List<NotificationModel> currentNotifications;
  final bool hasMore;

  const NotificationLoadingMore(this.currentNotifications, this.hasMore);

  @override
  List<Object> get props => [currentNotifications, hasMore];
}

/// State when notifications have been successfully loaded from backend
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasMore;
  final int currentPage;
  final NotificationType? currentFilter;
  final bool unreadOnly;

  const NotificationLoaded({
    required this.notifications,
    required this.hasMore,
    required this.currentPage,
    this.currentFilter,
    this.unreadOnly = false,
  });

  @override
  List<Object?> get props => [
        notifications,
        hasMore,
        currentPage,
        currentFilter,
        unreadOnly,
      ];

  /// Creates a copy of the state with updated values
  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    bool? hasMore,
    int? currentPage,
    NotificationType? currentFilter,
    bool? unreadOnly,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentFilter: currentFilter ?? this.currentFilter,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

/// State when an error occurs during backend communication
class NotificationError extends NotificationState {
  final String message;
  final List<NotificationModel> currentNotifications;

  const NotificationError(this.message, [this.currentNotifications = const []]);

  @override
  List<Object> get props => [message, currentNotifications];
}

/// BLoC for managing notification state and backend interactions
/// This class handles all communication with the NotificationService
/// and manages the UI state based on backend responses
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  
  /// Current page for pagination (starts at 1)
  int _currentPage = 1;
  
  /// Number of notifications to fetch per page
  static const int _pageSize = 20;
  
  /// Current filter applied to notifications
  NotificationType? _currentFilter;
  
  /// Whether to show only unread notifications
  bool _unreadOnly = false;

  NotificationBloc({
    required NotificationService notificationService,
  })  : _notificationService = notificationService,
        super(const NotificationInitial()) {
    
    // Register event handlers
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<MarkAllAsRead>(_onMarkAllAsRead);
  }

  /// Handles loading notifications from backend
  /// This method calls the GET /api/notifications endpoint
  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Update filter settings
      _currentFilter = event.filterType;
      _unreadOnly = event.unreadOnly;
      
      // If refreshing, show refreshing state with current notifications
      if (event.isRefresh && state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        emit(NotificationRefreshing(currentState.notifications));
      } else {
        // Show loading state for initial load
        emit(const NotificationLoading());
      }

      // Reset to first page for new load/refresh
      _currentPage = 1;

      print('🔄 Loading notifications from backend...'); // Debug log
      print('📋 Filters - Type: $_currentFilter, Unread Only: $_unreadOnly'); // Debug log

      // Call backend API to fetch notifications
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _pageSize,
        type: _currentFilter,
        unreadOnly: _unreadOnly,
      );

      print('✅ Successfully loaded ${response.notifications.length} notifications'); // Debug log
      print('📊 Pagination - Page: ${response.pagination.currentPage}, Has More: ${response.pagination.hasMore}'); // Debug log

      // Emit loaded state with fetched notifications
      emit(NotificationLoaded(
        notifications: response.notifications,
        hasMore: response.pagination.hasMore,
        currentPage: response.pagination.currentPage,
        currentFilter: _currentFilter,
        unreadOnly: _unreadOnly,
      ));

    } catch (error) {
      print('❌ Error loading notifications: $error'); // Debug log
      
      // Preserve current notifications if available during error
      final currentNotifications = state is NotificationLoaded
          ? (state as NotificationLoaded).notifications
          : <NotificationModel>[];

      // Emit error state with user-friendly message
      String errorMessage = _getErrorMessage(error);
      emit(NotificationError(errorMessage, currentNotifications));
    }
  }

  /// Handles loading more notifications for pagination
  /// This method calls the GET /api/notifications endpoint with next page
  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // Only load more if we're in a loaded state and have more pages
    if (state is! NotificationLoaded) return;
    
    final currentState = state as NotificationLoaded;
    if (!currentState.hasMore) return;

    try {
      // Show loading more state
      emit(NotificationLoadingMore(currentState.notifications, currentState.hasMore));

      // Increment page for pagination
      _currentPage = currentState.currentPage + 1;

      print('🔄 Loading more notifications - Page: $_currentPage'); // Debug log

      // Call backend API for next page
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _pageSize,
        type: _currentFilter,
        unreadOnly: _unreadOnly,
      );

      print('✅ Loaded ${response.notifications.length} more notifications'); // Debug log

      // Combine existing notifications with new ones
      final allNotifications = [
        ...currentState.notifications,
        ...response.notifications,
      ];

      // Emit updated loaded state
      emit(NotificationLoaded(
        notifications: allNotifications,
        hasMore: response.pagination.hasMore,
        currentPage: response.pagination.currentPage,
        currentFilter: _currentFilter,
        unreadOnly: _unreadOnly,
      ));

    } catch (error) {
      print('❌ Error loading more notifications: $error'); // Debug log
      
      String errorMessage = _getErrorMessage(error);
      emit(NotificationError(errorMessage, currentState.notifications));
    }
  }

  /// Handles marking a notification as read
  /// This method calls the PUT /api/notifications/{id}/status endpoint
  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationLoaded) return;

    final currentState = state as NotificationLoaded;

    try {
      print('🔄 Marking notification as read: ${event.notificationId}'); // Debug log

      // Call backend API to update notification status
      final success = await _notificationService.updateNotificationStatus(
        notificationId: event.notificationId,
        isRead: true,
      );

      if (success) {
        print('✅ Successfully marked notification as read'); // Debug log

        // Update the notification in the local list
        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        // Emit updated state
        emit(currentState.copyWith(notifications: updatedNotifications));
      } else {
        throw Exception('Failed to mark notification as read');
      }

    } catch (error) {
      print('❌ Error marking notification as read: $error'); // Debug log
      
      String errorMessage = _getErrorMessage(error);
      emit(NotificationError(errorMessage, currentState.notifications));
    }
  }

  /// Handles deleting/dismissing a notification
  /// This method calls the DELETE /api/notifications/{id} endpoint
  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationLoaded) return;

    final currentState = state as NotificationLoaded;

    try {
      print('🔄 Deleting notification: ${event.notificationId}'); // Debug log

      // Call backend API to delete notification
      final success = await _notificationService.deleteNotification(event.notificationId);

      if (success) {
        print('✅ Successfully deleted notification'); // Debug log

        // Remove the notification from the local list
        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != event.notificationId)
            .toList();

        // Emit updated state
        emit(currentState.copyWith(notifications: updatedNotifications));
      } else {
        throw Exception('Failed to delete notification');
      }

    } catch (error) {
      print('❌ Error deleting notification: $error'); // Debug log
      
      String errorMessage = _getErrorMessage(error);
      emit(NotificationError(errorMessage, currentState.notifications));
    }
  }

  /// Handles marking all notifications as read
  /// This method calls the POST /api/notifications/mark-all-read endpoint
  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationLoaded) return;

    final currentState = state as NotificationLoaded;

    try {
      print('🔄 Marking all notifications as read'); // Debug log

      // Call backend API to mark all as read
      final success = await _notificationService.markAllAsRead();

      if (success) {
        print('✅ Successfully marked all notifications as read'); // Debug log

        // Update all notifications to read status
        final updatedNotifications = currentState.notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();

        // Emit updated state
        emit(currentState.copyWith(notifications: updatedNotifications));
      } else {
        throw Exception('Failed to mark all notifications as read');
      }

    } catch (error) {
      print('❌ Error marking all notifications as read: $error'); // Debug log
      
      String errorMessage = _getErrorMessage(error);
      emit(NotificationError(errorMessage, currentState.notifications));
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
      return 'You don\'t have permission to access notifications.';
    } else if (error is NotFoundException) {
      return 'Notifications service is currently unavailable.';
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
    _notificationService.dispose();
    return super.close();
  }
}