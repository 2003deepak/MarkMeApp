import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../widgets/notification_card.dart';
import '../widgets/mock_data_banner.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

/// Main notification page that displays all user notifications
/// This page handles the complete notification experience including:
/// - Loading notifications from backend API
/// - Pull-to-refresh functionality
/// - Pagination for large notification lists
/// - Error handling and retry mechanisms
/// - Empty states when no notifications exist
/// 
/// Backend developers: This page integrates with your notification API endpoints.
/// Ensure your backend implements the following endpoints:
/// - GET /api/notifications (with pagination, filtering)
/// - PUT /api/notifications/{id}/status (mark as read)
/// - DELETE /api/notifications/{id} (dismiss notification)
/// - POST /api/notifications/mark-all-read (mark all as read)
class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with AutomaticKeepAliveClientMixin {
  
  /// Scroll controller for handling pagination and scroll-to-top
  late ScrollController _scrollController;
  
  /// Current filter applied to notifications
  NotificationType? _currentFilter;
  
  /// Whether to show only unread notifications
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Load initial notifications when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const LoadNotifications());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Keep the page alive to maintain scroll position and state
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      // App bar with title and action buttons
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        
        // Filter and mark all as read actions
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: Colors.grey.shade700,
            ),
            onSelected: _handleFilterSelection,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Text('Unread Only'),
              ),
              const PopupMenuItem(
                value: 'timetable',
                child: Text('Timetable Updates'),
              ),
              const PopupMenuItem(
                value: 'attendance',
                child: Text('Attendance'),
              ),
              const PopupMenuItem(
                value: 'alerts',
                child: Text('Critical Alerts'),
              ),
            ],
          ),
          
          // Mark all as read button
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.notifications.isNotEmpty) {
                final hasUnread = state.notifications.any((n) => !n.isRead);
                if (hasUnread) {
                  return IconButton(
                    icon: Icon(
                      Icons.done_all,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () => _markAllAsRead(context),
                    tooltip: 'Mark all as read',
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      
      // Main notification content
      body: Column(
        children: [
          // Mock data banner
          const MockDataBanner(
            showBanner: NotificationService.useMockData,
            message: 'Demo Mode - Using Mock Notifications',
          ),
          
          // Main content
          Expanded(
            child: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          // Handle error states with snackbar
          if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      LoadNotifications(
                        filterType: _currentFilter,
                        unreadOnly: _showUnreadOnly,
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
              builder: (context, state) {
                return _buildNotificationContent(context, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main notification content based on current state
  Widget _buildNotificationContent(BuildContext context, NotificationState state) {
    if (state is NotificationInitial || state is NotificationLoading) {
      return _buildLoadingState();
    }
    
    if (state is NotificationError && state.currentNotifications.isEmpty) {
      return _buildErrorState(context, state.message);
    }
    
    if (state is NotificationLoaded || 
        state is NotificationRefreshing || 
        state is NotificationLoadingMore ||
        (state is NotificationError && state.currentNotifications.isNotEmpty)) {
      
      List<NotificationModel> notifications;
      bool hasMore = false;
      bool isRefreshing = false;
      bool isLoadingMore = false;
      
      if (state is NotificationLoaded) {
        notifications = state.notifications;
        hasMore = state.hasMore;
      } else if (state is NotificationRefreshing) {
        notifications = state.currentNotifications;
        isRefreshing = true;
      } else if (state is NotificationLoadingMore) {
        notifications = state.currentNotifications;
        hasMore = state.hasMore;
        isLoadingMore = true;
      } else if (state is NotificationError) {
        notifications = state.currentNotifications;
      } else {
        notifications = [];
      }
      
      if (notifications.isEmpty) {
        return _buildEmptyState(context);
      }
      
      return _buildNotificationList(
        context,
        notifications,
        hasMore: hasMore,
        isRefreshing: isRefreshing,
        isLoadingMore: isLoadingMore,
      );
    }
    
    return _buildErrorState(context, 'Unknown state');
  }

  /// Builds loading state with shimmer effect
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error state with retry option
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationBloc>().add(
                  LoadNotifications(
                    filterType: _currentFilter,
                    unreadOnly: _showUnreadOnly,
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds empty state when no notifications exist
  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(
          LoadNotifications(
            isRefresh: true,
            filterType: _currentFilter,
            unreadOnly: _showUnreadOnly,
          ),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      LoadNotifications(
                        isRefresh: true,
                        filterType: _currentFilter,
                        unreadOnly: _showUnreadOnly,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the notification list with pull-to-refresh and pagination
  Widget _buildNotificationList(
    BuildContext context,
    List<NotificationModel> notifications, {
    bool hasMore = false,
    bool isRefreshing = false,
    bool isLoadingMore = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(
          LoadNotifications(
            isRefresh: true,
            filterType: _currentFilter,
            unreadOnly: _showUnreadOnly,
          ),
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notifications.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end if loading more
          if (index == notifications.length) {
            return _buildLoadingMoreIndicator(isLoadingMore);
          }
          
          final notification = notifications[index];
          
          return NotificationCard(
            notification: notification,
            animate: index < 5, // Animate first 5 items
            onTap: () => _markAsRead(context, notification),
            onDismiss: () => _dismissNotification(context, notification),
          );
        },
      ),
    );
  }

  /// Builds loading indicator for pagination
  Widget _buildLoadingMoreIndicator(bool isLoadingMore) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLoadingMore
          ? const CircularProgressIndicator()
          : const SizedBox.shrink(),
    );
  }

  /// Handles scroll events for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user scrolls near the bottom
      final currentState = context.read<NotificationBloc>().state;
      if (currentState is NotificationLoaded && 
          currentState.hasMore && 
          currentState is! NotificationLoadingMore) {
        context.read<NotificationBloc>().add(const LoadMoreNotifications());
      }
    }
  }

  /// Handles filter selection from popup menu
  void _handleFilterSelection(String value) {
    NotificationType? filterType;
    bool unreadOnly = false;
    
    switch (value) {
      case 'all':
        filterType = null;
        unreadOnly = false;
        break;
      case 'unread':
        filterType = null;
        unreadOnly = true;
        break;
      case 'timetable':
        filterType = NotificationType.timetableUpdate;
        break;
      case 'attendance':
        filterType = NotificationType.attendanceConfirmation;
        break;
      case 'alerts':
        filterType = NotificationType.criticalAlert;
        break;
    }
    
    setState(() {
      _currentFilter = filterType;
      _showUnreadOnly = unreadOnly;
    });
    
    // Load notifications with new filter
    context.read<NotificationBloc>().add(
      LoadNotifications(
        filterType: filterType,
        unreadOnly: unreadOnly,
      ),
    );
  }

  /// Marks a notification as read
  /// Backend developers: This calls PUT /api/notifications/{id}/status
  void _markAsRead(BuildContext context, NotificationModel notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }
  }

  /// Dismisses/deletes a notification
  /// Backend developers: This calls DELETE /api/notifications/{id}
  void _dismissNotification(BuildContext context, NotificationModel notification) {
    context.read<NotificationBloc>().add(
      DeleteNotification(notification.id),
    );
    
    // Show undo snackbar for better UX
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title} dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Reload notifications to restore dismissed item
            context.read<NotificationBloc>().add(
              LoadNotifications(
                isRefresh: true,
                filterType: _currentFilter,
                unreadOnly: _showUnreadOnly,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Marks all notifications as read
  /// Backend developers: This calls POST /api/notifications/mark-all-read
  void _markAllAsRead(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark All as Read'),
          content: const Text(
            'Are you sure you want to mark all notifications as read?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<NotificationBloc>().add(const MarkAllAsRead());
              },
              child: const Text('Mark All'),
            ),
          ],
        );
      },
    );
  }

  /// Gets empty state title based on current filter
  String _getEmptyStateTitle() {
    if (_showUnreadOnly) {
      return 'No unread notifications';
    }
    
    switch (_currentFilter) {
      case NotificationType.timetableUpdate:
        return 'No timetable updates';
      case NotificationType.attendanceConfirmation:
        return 'No attendance notifications';
      case NotificationType.criticalAlert:
        return 'No critical alerts';
      default:
        return 'No notifications yet';
    }
  }

  /// Gets empty state message based on current filter
  String _getEmptyStateMessage() {
    if (_showUnreadOnly) {
      return 'All your notifications have been read.\nPull down to refresh.';
    }
    
    switch (_currentFilter) {
      case NotificationType.timetableUpdate:
        return 'You\'ll see timetable updates here when they\'re available.';
      case NotificationType.attendanceConfirmation:
        return 'Attendance confirmations will appear here.';
      case NotificationType.criticalAlert:
        return 'Important alerts will be shown here.';
      default:
        return 'You\'ll receive notifications here when they arrive.\nPull down to refresh.';
    }
  }
}