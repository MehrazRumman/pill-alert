import 'app_locale.dart';
import 'numerals.dart';

const List<String> bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

const List<String> enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> hiMonths = [
  'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
  'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
];

/// Spanish month names are lowercase — capitalising them is a common and visible error.
const List<String> esMonths = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Monday-first, matching `DayOfWeek.value` in the original and Dart's `DateTime.weekday`.
const List<String> bnWeekdays = [
  'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার',
];

const List<String> enWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const List<String> hiWeekdays = [
  'सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार',
];

/// Also lowercase in Spanish.
const List<String> esWeekdays = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

const List<String> bnWeekdaysShort = ['সো', 'ম', 'বু', 'বৃ', 'শু', 'শ', 'র'];
const List<String> enWeekdaysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const List<String> hiWeekdaysShort = ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'];

/// Spanish needs two letters: lunes/martes and miércoles both start with M, sábado and domingo
/// would collide with each other under a single initial too.
const List<String> esWeekdaysShort = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];

List<String> monthsFor(AppLocale l) => switch (l) {
      AppLocale.bn => bnMonths,
      AppLocale.en => enMonths,
      AppLocale.hi => hiMonths,
      AppLocale.es => esMonths,
    };

List<String> weekdaysFor(AppLocale l) => switch (l) {
      AppLocale.bn => bnWeekdays,
      AppLocale.en => enWeekdays,
      AppLocale.hi => hiWeekdays,
      AppLocale.es => esWeekdays,
    };

List<String> weekdaysShortFor(AppLocale l) => switch (l) {
      AppLocale.bn => bnWeekdaysShort,
      AppLocale.en => enWeekdaysShort,
      AppLocale.hi => hiWeekdaysShort,
      AppLocale.es => esWeekdaysShort,
    };

/// "সোমবার, ২৮ আগস্ট" / "Monday, 28 August" / "सोमवार, 28 अगस्त" / "lunes, 28 de agosto".
///
/// Spanish puts "de" between the day and the month; the other three simply juxtapose them.
String dateStringFor(DateTime d, AppLocale l) {
  final wd = weekdaysFor(l)[d.weekday - 1];
  final month = monthsFor(l)[d.month - 1];
  final day = Numerals.number(d.day, l.isBangla);
  return l == AppLocale.es ? '$wd, $day de $month' : '$wd, $day $month';
}

/// "২৮ আগস্ট" / "28 Aug" — the compact form used in record and report rows.
String shortDateFor(DateTime d, AppLocale l) {
  final day = Numerals.number(d.day, l.isBangla);
  final month = monthsFor(l)[d.month - 1];
  // Bengali and Devanagari month names do not abbreviate to three letters the way Latin ones do;
  // truncating them mid-conjunct would produce a broken cluster, so they are left whole.
  return l.isIndic ? '$day $month' : '$day ${month.substring(0, 3)}';
}

/// Retained so the many `dateString(d, context.isBangla)` call sites keep working.
String dateString(DateTime d, bool bangla) =>
    dateStringFor(d, bangla ? AppLocale.bn : AppLocale.en);

String shortDate(DateTime d, bool bangla) =>
    shortDateFor(d, bangla ? AppLocale.bn : AppLocale.en);
