import 'package:intl/intl.dart';
import 'currency_helper.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _yearMonthKeyFormat = DateFormat('yyyy-MM');

  static String formatDisplay(DateTime? date) {
    if (date == null) return 'N/A';
    return _displayFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String formatShortMonthYear(DateTime date) {
    return _shortMonthYearFormat.format(date);
  }

  static String toMonthKey(DateTime date) {
    return _yearMonthKeyFormat.format(date);
  }

  static DateTime fromMonthKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length == 2) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      }
    } catch (_) {}
    return DateTime.now();
  }

  static String formatCurrency(double amount, [String currencyCode = 'USD']) {
    return CurrencyHelper.format(amount, currencyCode: currencyCode);
  }

  static String formatVolumeNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toString();
  }
}
