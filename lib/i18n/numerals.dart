/// Locale-level numeral + time formatting (README > Fidelity > Numerals). The Bangla locale uses
/// Bengali numerals (০১২৩৪৫৬৭৮৯) everywhere — times, doses, counts, percentages, phone numbers —
/// and 12-hour times with a period word. The English locale uses Western numerals and (by default)
/// 24-hour times. This is a locale-level rule, not a per-string one.
class Numerals {
  Numerals._();

  static const List<String> _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  /// Converts every ASCII digit in [text] to Bengali when [bangla] is true; otherwise returns as-is.
  static String digits(String text, bool bangla) {
    if (!bangla) return text;
    final sb = StringBuffer();
    for (final c in text.codeUnits) {
      if (c >= 0x30 && c <= 0x39) {
        sb.write(_bnDigits[c - 0x30]);
      } else {
        sb.writeCharCode(c);
      }
    }
    return sb.toString();
  }

  static String number(int value, bool bangla) => digits(value.toString(), bangla);

  /// Formats whole and half quantities without truncating values such as 1.5 to 1.
  static String quantity(double value, bool bangla) {
    final roundedHalf = (value * 2).round() / 2;
    final text = roundedHalf % 1 == 0 ? roundedHalf.toInt().toString() : '${roundedHalf.toInt()}.5';
    return digits(text, bangla);
  }

  static String percent(int value, bool bangla) =>
      bangla ? '${digits(value.toString(), true)}%' : '$value%';

  /// Bangla time-of-day period word for a 24-hour [hour].
  static String banglaPeriod(int hour) {
    if (hour <= 3) return 'রাত';
    if (hour <= 5) return 'ভোর';
    if (hour <= 11) return 'সকাল';
    if (hour <= 14) return 'দুপুর';
    if (hour <= 17) return 'বিকাল';
    if (hour <= 19) return 'সন্ধ্যা';
    return 'রাত';
  }

  /// Formats a clock time. Bangla: "সকাল ৮:০০" (period word + 12h + Bengali digits).
  /// English 24h: "08:00". English 12h: "8:00 AM".
  static String time(int hour, int minute, bool bangla, bool is24) {
    final mm = minute.toString().padLeft(2, '0');
    if (bangla) {
      final period = banglaPeriod(hour);
      final h12 = ((hour + 11) % 12) + 1;
      return '$period ${digits('$h12:$mm', true)}';
    }
    if (is24) return '${hour.toString().padLeft(2, '0')}:$mm';
    final h12 = ((hour + 11) % 12) + 1;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h12:$mm $ampm';
  }
}
