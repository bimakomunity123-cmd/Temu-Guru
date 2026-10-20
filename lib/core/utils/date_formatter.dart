import 'package:intl/intl.dart';

class AppDateFormatter {
  static String format(DateTime date, [String pattern = 'dd MMMM yyyy']) {
    try {
      return DateFormat(pattern, 'id_ID').format(date);
    } catch (_) {
      try {
        return DateFormat(pattern).format(date);
      } catch (_) {
        return '${date.day}-${date.month}-${date.year}';
      }
    }
  }

  static String formatShort(DateTime date) {
    return format(date, 'dd MMM yyyy');
  }

  static String formatFull(DateTime date) {
    return format(date, 'EEEE, dd MMMM yyyy');
  }

  static String formatDateTime(DateTime date) {
    return format(date, 'dd MMM yyyy, HH:mm');
  }
}
