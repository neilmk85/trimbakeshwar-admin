import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryMedium = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color navyDeep = Color(0xFF1A237E);

  static const Color white = Colors.white;
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  // Blue gradient — dark navy → bright blue
  static const Color gradientDark = Color(0xFF0D47A1);   // deep navy blue
  static const Color gradientLight = Color(0xFF1E88E5);  // bright blue

  static const List<Color> gradientColors = [gradientDark, gradientLight];

  static const LinearGradient appBarGradient = LinearGradient(
    colors: gradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
