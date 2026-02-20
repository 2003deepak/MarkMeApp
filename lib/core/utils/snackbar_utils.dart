import 'package:flutter/material.dart';
import 'package:markmeapp/main.dart'; 


void showAppSnackBar(String message, {bool isError = false, BuildContext? context}) {
  ScaffoldMessengerState? messengerState;

  // 1. Try to get messenger from context if provided and mounted
  if (context != null && context.mounted) {
    try {
      messengerState = ScaffoldMessenger.of(context);
    } catch (e) {
      // Fallback to global key if context lookup fails
    }
  }

  // 2. Fallback to global key
  messengerState ??= rootScaffoldMessengerKey.currentState;

  if (messengerState == null) {
    debugPrint(
      '⚠️ Warning: Could not find ScaffoldMessengerState. Cannot show SnackBar: $message',
    );
    return;
  }

  // Remove current SnackBar instantly to avoid animation overlaps
  messengerState.removeCurrentSnackBar();

  messengerState.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
      dismissDirection: DismissDirection.horizontal,
      showCloseIcon: true,
      closeIconColor: Colors.white,
    ),
  );
}
