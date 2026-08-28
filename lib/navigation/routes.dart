import 'package:flutter/material.dart';

import '../ui/components/scaffold.dart';

/// Route table. Main tabs keep the bottom nav; everything else is pushed full-screen (no nav bar).
class Routes {
  Routes._();

  // Main tabs
  static const today = 'today'; // Home timeline (2j/2b) — also empty (4d) / day-complete (6f)
  static const meds = 'meds'; // Medicine cabinet (2s/2e)
  static const record = 'record'; // Adherence record (2t/2f)
  static const more = 'more'; // More hub (6a)

  // Onboarding / priming
  static const onboarding = '/onboarding'; // 2q/2a
  static const permissionPriming = '/priming'; // 5b

  // Pushed screens
  static const alarmPreview = '/alarm_preview'; // 2k/2c (in-app preview)
  static const alarmFullScreen = '/alarm'; // the real alarm, opened by a reminder
  static const inbox = '/inbox'; // 6b notification inbox
  static const refill = '/refill'; // 2u/2g refill & stock
  static const family = '/family'; // 2v/2h family & caregivers
  static const caregiverNotify = '/caregiver_notify'; // 4a
  static const caregiverCode = '/caregiver_code'; // 6d
  static const doctorReport = '/doctor_report'; // 6c
  static const settings = '/settings'; // 2l/2i
  static const help = '/help';
  static const medicineDetail = '/medicine'; // 5e — argument is the medicine id

  // Add-medicine flow (3a → …)
  static const addRoute = '/add/route'; // 3a route chooser
  static const addScan = '/add/scan'; // 3b scan & confirm
  static const addSearch = '/add/search'; // 3g search fallback
  static const addTiming = '/add/timing'; // 3c when to take
  static const addQuantity = '/add/quantity'; // 3d how many
  static const addReview = '/add/review'; // 3e review

  static const mainTabs = {today, meds, record, more};
}

/// The four bottom-nav tabs (আজ / ওষুধ / রেকর্ড / আরও).
const List<NavTab> navTabs = [
  NavTab(Routes.today, Icons.wb_sunny, 'আজ', 'Today'),
  NavTab(Routes.meds, Icons.medication, 'ওষুধ', 'Meds'),
  NavTab(Routes.record, Icons.bar_chart, 'রেকর্ড', 'Record'),
  NavTab(Routes.more, Icons.more_horiz, 'আরও', 'More'),
];
