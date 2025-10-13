// import 'package:flutter/material.dart';

// class AppTheme {
//   // Light Theme
//   static final ThemeData lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primarySwatch: Colors.indigo,
//     scaffoldBackgroundColor: Colors.white,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.indigo,
//       foregroundColor: Colors.white,
//       elevation: 0,
//     ),
//     textTheme: const TextTheme(
//       headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
//       bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
//       bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
//       bodySmall: TextStyle(fontSize: 14, color: Colors.black),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(12)),
//         ),
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       hintStyle: TextStyle(color: Colors.grey.shade600),
//       labelStyle: const TextStyle(color: Colors.black),
//     ),
//     textSelectionTheme: const TextSelectionThemeData(
//       cursorColor: Colors.indigo,
//       selectionColor: Colors.indigo,
//       selectionHandleColor: Colors.indigo,
//     ),
//   );

//   // Dark Theme
//   static final ThemeData darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primarySwatch: Colors.indigo,
//     scaffoldBackgroundColor: Colors.black,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.black,
//       foregroundColor: Colors.white,
//       elevation: 0,
//     ),
//     textTheme: const TextTheme(
//       headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//       bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
//       bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
//       bodySmall: TextStyle(fontSize: 14, color: Colors.white70),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(12)),
//         ),
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       hintStyle: TextStyle(color: Colors.grey.shade400),
//       labelStyle: const TextStyle(color: Colors.white70),
//     ),
//     textSelectionTheme: const TextSelectionThemeData(
//       cursorColor: Colors.indigo,
//       selectionColor: Colors.indigo,
//       selectionHandleColor: Colors.indigo,
//     ),
//   );
// }

import 'package:flutter/material.dart';

class AppTheme {
  // Palette (5 colors total)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color successGreenBg = Color(0xFFECFDF5);
  static const Color textDark = Color(0xFF111827);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: successGreen,
    ).copyWith(surface: surfaceWhite, onSurface: textDark, outline: borderGray),
    scaffoldBackgroundColor: surfaceWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: borderGray,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: textDark,
      textColor: textDark,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF9FAFB),
      selectedColor: successGreenBg,
      side: const BorderSide(color: borderGray),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}
