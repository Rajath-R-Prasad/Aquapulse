import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF0E7490);
  static const _surface = Color(0xFFF8FAFC);
  static const _background = Color(0xFFF1F5F9);
  static const _error = Color(0xFFDC2626);

  static const severityCritical = Color(0xFFDC2626);
  static const severityMajor = Color(0xFFF97316);
  static const severityModerate = Color(0xFFF59E0B);
  static const severityMinor = Color(0xFF3B82F6);
  static const severityNone = Color(0xFF6B7280);

  static const statusAssigned = Color(0xFF8B5CF6);
  static const statusAccepted = Color(0xFF3B82F6);
  static const statusEnRoute = Color(0xFFF59E0B);
  static const statusOnSite = Color(0xFF10B981);
  static const statusSubmitted = Color(0xFF6366F1);
  static const statusRework = Color(0xFFF97316);
  static const statusCompleted = Color(0xFF059669);
  static const statusCancelled = Color(0xFF6B7280);

  static Color severityColor(String severity) => switch (severity) {
        'CRITICAL' => severityCritical,
        'MAJOR' => severityMajor,
        'MODERATE' => severityModerate,
        'MINOR' => severityMinor,
        _ => severityNone,
      };

  static Color woStatusColor(String status) => switch (status) {
        'ASSIGNED' => statusAssigned,
        'ACCEPTED' => statusAccepted,
        'EN_ROUTE' => statusEnRoute,
        'ON_SITE' => statusOnSite,
        'SUBMITTED' => statusSubmitted,
        'REWORK' => statusRework,
        'COMPLETED' => statusCompleted,
        'CANCELLED' => statusCancelled,
        _ => severityNone,
      };

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _primary,
          onPrimary: Colors.white,
          surface: _surface,
          error: _error,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: _background,
          foregroundColor: Color(0xFF0F172A),
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _error),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _primary,
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _primary.withValues(alpha: 0.12),
          elevation: 10,
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              )),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
      );
}
