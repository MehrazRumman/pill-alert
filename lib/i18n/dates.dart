import 'numerals.dart';

const List<String> bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

const List<String> enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Monday-first, matching `DayOfWeek.value` in the original and Dart's `DateTime.weekday`.
const List<String> bnWeekdays = [
  'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার',
];

const List<String> enWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const List<String> bnWeekdaysShort = ['সো', 'ম', 'বু', 'বৃ', 'শু', 'শ', 'র'];
const List<String> enWeekdaysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// "সোমবার, ২৮ আগস্ট" / "Monday, 28 August".
String dateString(DateTime d, bool bangla) {
  final wd = d.weekday - 1;
  if (bangla) {
    return '${bnWeekdays[wd]}, ${Numerals.number(d.day, true)} ${bnMonths[d.month - 1]}';
  }
  return '${enWeekdays[wd]}, ${d.day} ${enMonths[d.month - 1]}';
}

/// "২৮ আগস্ট" / "28 Aug" — the compact form used in record and report rows.
String shortDate(DateTime d, bool bangla) => bangla
    ? '${Numerals.number(d.day, true)} ${bnMonths[d.month - 1]}'
    : '${d.day} ${enMonths[d.month - 1].substring(0, 3)}';
