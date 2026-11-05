/// Returns the time-of-day greeting shown on the admin Dashboard header.
///
/// The returned string is exactly one of "Good morning", "Good afternoon",
/// "Good evening", or "Good night", chosen from [time]'s hour:
///
/// | hour range   | greeting        |
/// |--------------|-----------------|
/// | 05:00–11:59  | Good morning    |
/// | 12:00–16:59  | Good afternoon  |
/// | 17:00–20:59  | Good evening    |
/// | 21:00–04:59  | Good night      |
///
/// The function is total: every possible [DateTime] maps to exactly one
/// greeting.
String greetingFor(DateTime time) {
  final int hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 21) return 'Good evening';
  return 'Good night';
}
