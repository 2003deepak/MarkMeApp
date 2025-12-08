import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  // Singleton
  static final AppPermissions _instance = AppPermissions._internal();
  factory AppPermissions() => _instance;
  AppPermissions._internal();

  /// Cache
  final Map<Permission, PermissionStatus> _cache = {};

  /// Platform-aware required permissions
  List<Permission> get requiredPermissions {
    if (Platform.isAndroid) {
      return [
        Permission.camera,
        if (_supportsNotificationPermission()) Permission.notification,
        // Use manageExternalStorage for Android 11+ if you need broad file access
        // Otherwise, remove storage permission entirely for scoped storage
        if (_needsStoragePermission()) Permission.storage,
      ];
    } else {
      return [Permission.camera, Permission.photos, Permission.notification];
    }
  }

  /// Check if we actually need to request storage permission
  bool _needsStoragePermission() {
    if (!Platform.isAndroid) return true;

    // On Android 11+, scoped storage is used by default
    // Only request storage permission if you need legacy broad access
    // For most apps, you don't need this permission anymore
    return false; // Set to true only if you need broad file system access
  }

  /// notification permission required
  bool _supportsNotificationPermission() {
    if (!Platform.isAndroid) return true;
    return true;
  }

  /// Read fresh status from OS
  Future<PermissionStatus> _refresh(Permission permission) async {
    final status = await permission.status;
    _cache[permission] = status;
    debugPrint('🔄 [AppPermissions] Refreshed ${_name(permission)}: $status');
    return status;
  }

  /// Cached read OR refresh
  Future<PermissionStatus> _status(Permission permission) async {
    if (_cache.containsKey(permission)) {
      debugPrint(
        '📦 [AppPermissions] Using cached ${_name(permission)}: ${_cache[permission]}',
      );
      return _cache[permission]!;
    }
    return await _refresh(permission);
  }

  /// Request permission with system popup
  Future<PermissionStatus> _request(Permission permission) async {
    debugPrint('🎯 [AppPermissions] Requesting ${_name(permission)}...');
    final status = await permission.request();
    _cache[permission] = status;
    debugPrint(
      '✅ [AppPermissions] ${_name(permission)} request result: $status',
    );
    return status;
  }

  /// Public: is granted?
  Future<bool> isGranted(Permission permission) async {
    final granted = (await _status(permission)).isGranted;
    debugPrint('🔍 [AppPermissions] ${_name(permission)} granted: $granted');
    return granted;
  }

  /// Force request
  Future<bool> request(Permission permission) async {
    return (await _request(permission)).isGranted;
  }

  /// Automatically request everything on first app load
  Future<void> initialize(BuildContext context) async {
    debugPrint('🚀 [AppPermissions] Initializing permissions...');
    debugPrint(
      '📋 [AppPermissions] Required permissions: ${requiredPermissions.map((p) => _name(p)).toList()}',
    );
    debugPrint(
      '🤖 [AppPermissions] Android SDK: ${Platform.isAndroid ? _getAndroidSdkVersion() : "N/A"}',
    );

    for (final permission in requiredPermissions) {
      final status = await _status(permission);
      if (!context.mounted) return;
      final permissionName = _name(permission);

      debugPrint('🔍 [AppPermissions] Checking $permissionName: $status');

      if (status.isGranted) {
        debugPrint(
          '✅ [AppPermissions] $permissionName already granted, skipping',
        );
        continue;
      }

      if (status.isPermanentlyDenied) {
        debugPrint(
          '🚫 [AppPermissions] $permissionName permanently denied, showing settings dialog',
        );
        await _showPermanentDialog(context, permission);
        continue;
      }

      if (status.isDenied) {
        debugPrint(
          '📝 [AppPermissions] $permissionName denied, requesting permission...',
        );

        // For storage permission on newer Android, don't show rationale
        if (permission == Permission.storage && Platform.isAndroid) {
          debugPrint(
            '💾 [AppPermissions] Storage permission on Android - system may not show dialog',
          );
        }

        // First attempt to request
        final result = await _request(permission);
        if (!context.mounted) return;

        if (!result.isGranted) {
          debugPrint(
            '❌ [AppPermissions] $permissionName not granted after first request: $result',
          );

          // Only show rationale if it's denied AND the system actually showed a dialog
          // For storage on newer Android, the system won't show a dialog, so don't show rationale
          if (result.isDenied && _shouldShowRationale(permission, result)) {
            debugPrint(
              '💡 [AppPermissions] Showing rationale for $permissionName',
            );
            await _showRationaleDialog(context, permission);

            // Try again after dialog
            debugPrint(
              '🔄 [AppPermissions] Retrying $permissionName after rationale...',
            );
            final retryResult = await _request(permission);
            if (!context.mounted) return;

            if (retryResult.isGranted) {
              debugPrint(
                '🎉 [AppPermissions] $permissionName granted after rationale!',
              );
            } else {
              debugPrint(
                '😞 [AppPermissions] $permissionName still not granted after rationale: $retryResult',
              );
            }
          } else if (result.isPermanentlyDenied) {
            debugPrint(
              '🚫 [AppPermissions] $permissionName permanently denied after request',
            );
            await _showPermanentDialog(context, permission);
          } else {
            debugPrint(
              'ℹ️ [AppPermissions] $permissionName - no rationale needed (system didn\'t show dialog)',
            );
          }
        } else {
          debugPrint(
            '🎉 [AppPermissions] $permissionName granted on first request!',
          );
        }
      } else {
        debugPrint('ℹ️ [AppPermissions] $permissionName status: $status');
      }
    }

    // Log final status of all permissions
    debugPrint('📊 [AppPermissions] Final permission status:');
    for (final permission in requiredPermissions) {
      final status = await _status(permission);
      debugPrint('   ${_name(permission)}: $status');
    }
  }

  /// Determine if we should show rationale dialog
  bool _shouldShowRationale(Permission permission, PermissionStatus status) {
    // Don't show rationale for storage permission on newer Android
    // because the system won't show a permission dialog for it
    if (permission == Permission.storage && Platform.isAndroid) {
      return false;
    }

    // For other permissions, show rationale if denied (not permanently denied)
    return status.isDenied;
  }

  // Get Android SDK version (approximate)
  String _getAndroidSdkVersion() {
    try {
      final version = Platform.version;
      final match = RegExp(r'\((\d+)\)').firstMatch(version);
      if (match != null) {
        final sdk = int.tryParse(match.group(1)!);
        if (sdk != null) {
          if (sdk >= 30) return '$sdk (Android 11+) - Scoped Storage';
          if (sdk >= 29) return '$sdk (Android 10) - Scoped Storage';
          return '$sdk (Android 9 or below) - Legacy Storage';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // =============================================================
  // DIALOGS
  // =============================================================

  Future<void> _showRationaleDialog(
    BuildContext context,
    Permission permission,
  ) async {
    debugPrint(
      '💬 [AppPermissions] Showing rationale dialog for ${_name(permission)}',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("${_name(permission)} Access Needed"),
        content: Text(
          "This feature requires ${_name(permission)} access to function properly. Please allow it.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint(
                '👌 [AppPermissions] User acknowledged ${_name(permission)} rationale',
              );
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermanentDialog(
    BuildContext context,
    Permission permission,
  ) async {
    debugPrint(
      '⚙️ [AppPermissions] Showing permanent denial dialog for ${_name(permission)}',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("${_name(permission)} Permission Blocked"),
        content: Text(
          "You have permanently denied ${_name(permission)} access. Please enable it from app settings.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint(
                '❌ [AppPermissions] User cancelled settings for ${_name(permission)}',
              );
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              debugPrint(
                '🔧 [AppPermissions] Opening settings for ${_name(permission)}',
              );
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // PERMISSION HELPERS
  // =============================================================

  String _name(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return "Camera";
      case Permission.photos:
        return "Photos";
      case Permission.storage:
        return "Storage";
      case Permission.notification:
        return "Notifications";
      default:
        return "Permission";
    }
  }

  Future<void> refreshAll() async {
    debugPrint('🔄 [AppPermissions] Refreshing all permissions...');
    for (final permission in requiredPermissions) {
      await _refresh(permission);
    }
  }

  void clearCache() {
    debugPrint('🗑️ [AppPermissions] Clearing permission cache');
    _cache.clear();
  }

  Future<void> openSettings() {
    debugPrint('🔧 [AppPermissions] Opening app settings');
    return openAppSettings();
  }

  /// Debug method to print current status
  Future<void> debugPrintStatus() async {
    debugPrint('📊 [AppPermissions] Current permission status:');
    for (final permission in requiredPermissions) {
      final status = await _status(permission);
      debugPrint('   ${_name(permission)}: $status');
    }
  }
}

final appPermissions = AppPermissions();
