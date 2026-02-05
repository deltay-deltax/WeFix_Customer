import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(
    0xFF4285F4,
  ); // Main blue (buttons, highlights, icons)
  static const Color onPrimary = Colors.white; // Text/icons on blue
  static const Color primary2 = Color(0xffff5b38); // Accent orange requested

  static const Color accent = Color(
    0xFF5B77E3,
  ); // Secondary/Accent blue from login/signup

  // Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFFF7F8FA); // App BG (pages)
  static const Color cardBackground = Colors.white; // Card/dialog bg
  static const Color inputFill = Color(0xFFF5F7FB); // Input fields bg
  static const Color surface = Colors.white;

  // Navigation Bar
  static const Color navSelected = primary;
  static const Color navUnselected = Color(0xFFB8BBC6);

  // Text Colors
  static const Color textPrimary = Color(0xFF222B45); // Main headings
  static const Color textSecondary = Color(0xFF6B6E75); // Sub/label/placeholder
  static const Color textInverse = Colors.white; // On dark

  // Divider/Border
  static const Color divider = Color(0xFFE6E9EC); // Dividers

  // Status Colors
  static const Color success = Color(0xFF039855);
  static const Color warning = Color(0xFFFFB500);
  static const Color error = Color(0xFFEB5685);
  static const Color info = Color(0xFF4285F4);

  // Status backgrounds (badges, chips)
  static const Color chipInProgressBg = Color(0xFFD1B7FF);
  static const Color chipPendingBg = Color(0xFFFFE6B0);
  static const Color chipPaidBg = Color(0xFFCFF6DF);
  static const Color chipPaymentBg = Color(0xFFFBD7DF);
  static const Color chipDeclinedBg = Color(0xFFFBD7DF);

  // Status text (badges)
  static const Color chipInProgress = Color(0xFF914DFF);
  static const Color chipPending = Color(0xFFFFB500);
  static const Color chipPaid = Color(0xFF039855);
  static const Color chipPayment = Color(0xFFEB5685);
  static const Color chipDeclined = Color(0xFFEB5685);

  // Notification backgrounds
  static const Color notifSuccessBg = Color(0xFFD4F7D3);
  static const Color notifInfoBg = Color(0xFFE5F0FF);
  static const Color notifErrorBg = Color(0xFFFDE9EA);
  static const Color notifWarningBg = Color(0xFFFFF4D6);

  // Misc
  static const Color highlight = Color(0xFF2F74F9); // Some badges/buttons
  static const Color textButtonBlue = Colors.blue; // Text links, e.g. "Sign up"
  static const Color chipSelected = Color(0xFFE0EDFF); // Tabs BG (selected)
  static const Color chipUnselected = Colors.white; // Tabs BG (not selected)

  // Placeholder/Disabled
  static const Color disabled = Color(0xFFDCDFE6);

  // Icon, hint, etc.
  static const Color iconGrey = Color(0xFF8E94A3);
}
