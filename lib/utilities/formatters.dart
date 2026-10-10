import 'package:intl/intl.dart';

String dateLabel(DateTime date) => DateFormat('d. MMM yyyy', 'de').format(date);
String shortDate(DateTime date) => DateFormat('d. MMM', 'de').format(date);
String timeLabel(DateTime date) => DateFormat('HH:mm', 'de').format(date);
String dateRange(DateTime start, DateTime end) =>
    '${shortDate(start)} – ${dateLabel(end)}';
String decimalLabel(num value, [int decimals = 1]) =>
    NumberFormat.decimalPatternDigits(
      locale: 'de',
      decimalDigits: decimals,
    ).format(value);
