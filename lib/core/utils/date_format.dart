import 'package:intl/intl.dart';

/// Small date-formatting helpers used by the app and admin screens.
abstract final class DateFormatX {
  const DateFormatX._();

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthsFull = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _monthsShort = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// e.g. "Sunday, 25 October".
  static String weekdayDayMonth(DateTime d) {
    final String weekday = _weekdays[d.weekday - 1];
    final String month = _monthsFull[d.month - 1];
    return '$weekday, ${d.day} $month';
  }

  /// e.g. "29 Oct".
  static String dayMonthShort(DateTime d) {
    return '${d.day} ${_monthsShort[d.month - 1]}';
  }

  /// Formats a [DateTime] in `dd-MMM-yyyy hh:mm a` format using `intl`'s [DateFormat]
  /// (e.g. "24-May-2025 02:30 PM"). Defaults to [DateTime.now()] if omitted.
  static String formatTimestamp([DateTime? dateTime]) {
    final DateTime dt = (dateTime ?? DateTime.now()).toLocal();
    return DateFormat('dd-MMM-yyyy hh:mm a').format(dt);
  }
}
