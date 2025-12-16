import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TomorrowBunkSafetyCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final VoidCallback onViewDetails;
  final VoidCallback onRetry;
  final bool isDesktop;

  const TomorrowBunkSafetyCard({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.data,
    required this.onViewDetails,
    required this.onRetry,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return _buildErrorState();
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    final bool safeToBunk = data!['safe_to_bunk'] ?? false;
    final String dateStr = data!['date'] ?? '';
    final aggregate = data!['aggregate'] ?? {};
    final double attendanceIfBunk = (aggregate['if_bunk'] ?? 0).toDouble();
    final double attendanceNow = (aggregate['current'] ?? 0).toDouble();
    final int sessionCount = (data!['subjects'] as List?)?.length ?? 0;

    // Parse date
    DateTime? date;
    String formattedDate = dateStr;
    try {
      date = DateTime.parse(dateStr);
      formattedDate = DateFormat('EEEE, d MMMM').format(date);
    } catch (_) {}

    final color = safeToBunk ? Colors.green : Colors.orange;
    final icon = safeToBunk
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tomorrow\'s Bunk Safety',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        safeToBunk ? 'Safe to Bunk! 🎉' : 'Better Attend! 😅',
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        'Current',
                        '${attendanceNow.toStringAsFixed(2)}%',
                        Colors.grey[700]!,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _buildStat(
                        'If You Bunk',
                        '${attendanceIfBunk.toStringAsFixed(2)}%',
                        color,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _buildStat(
                        'Sessions',
                        '$sessionCount',
                        Colors.grey[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Weekly Calculator',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        children: [
          Text(
            errorMessage ?? 'Unknown error',
            style: const TextStyle(color: Colors.red),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
