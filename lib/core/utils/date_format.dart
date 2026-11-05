/// Small date-formatting helpers used by the admin screens.
///
/// Implemented without the `intl` package to avoid adding a dependency for the
/// two simple formats the designs need.
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
}
