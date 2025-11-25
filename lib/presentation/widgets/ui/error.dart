import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final bool isDesktop;
  final bool isRetryEnabled;

  const CustomErrorWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.isDesktop,
    this.isRetryEnabled = true,
  });

  bool get _isApiError =>
      errorMessage.toLowerCase().contains('error') ||
      errorMessage.toLowerCase().contains('failed') ||
      errorMessage.toLowerCase().contains('exception');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isApiError ? Icons.error_outline : Icons.info_outline,
                  size: isDesktop ? 64 : 48,
                  color: _isApiError
                      ? Colors.red.shade400
                      : Colors.blueGrey.shade400,
                ),
                const SizedBox(height: 16),

                // Dynamic title depending on error type
                Text(
                  _isApiError ? 'Failed to load data' : errorMessage,
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                if (_isApiError)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 100 : 40,
                    ),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Retry button only for actual API errors
                if (isRetryEnabled && _isApiError)
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 24,
                        vertical: isDesktop ? 16 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
