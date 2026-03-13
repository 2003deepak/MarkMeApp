import 'package:intl/intl.dart';

class TimeUtils {
  /// Converts 24-hour time string (HH:mm) to 12-hour format (h:mm a)
  static String formatTime12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  /// Converts 12-hour time string (h:mm a) to 24-hour format (HH:mm)
  static String convertTo24HourFormat(String time12Hour) {
    try {
      final parts = time12Hour.split(' ');
      if (parts.length < 2) return '00:00';
      
      final timePart = parts[0];
      final period = parts[1].toUpperCase();

      final timeComponents = timePart.split(':');
      int hour = int.parse(timeComponents[0]);
      final minute = timeComponents[1];

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      return '00:00';
    }
  }

  /// Parse 24-hour time string (HH:mm) to minutes since midnight
  static int timeToMinutes(String time24Hour) {
    try {
      final parts = time24Hour.split(':');
      if (parts.length < 2) return 0;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }
}
