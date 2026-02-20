import 'package:flutter/material.dart';
import 'package:markmeapp/core/utils/snackbar_utils.dart';

/// Shows an error snackbar with a red background and error icon
void showErrorSnackBar(BuildContext context, String message) {
  showAppSnackBar(message, isError: true, context: context);
}

/// Shows a confirmation snackbar with a green background and check icon
void showSuccessSnackBar(BuildContext context, String message) {
  showAppSnackBar(message, isError: false, context: context);
}
