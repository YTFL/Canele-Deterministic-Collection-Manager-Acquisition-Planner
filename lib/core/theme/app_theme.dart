import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.custardCream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.caramelizedAmber,
        onPrimary: Colors.white,
        primaryContainer: AppColors.warmPastryCrust,
        onPrimaryContainer: AppColors.deepCaramel,
        secondary: AppColors.caramelizedAmber,
        onSecondary: Colors.white,
        surface: AppColors.custardCream,
        onSurface: AppColors.deepCaramel,
        outline: AppColors.pastryCrustBorder,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.deepCaramel,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.deepCaramel,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.deepCaramelMuted,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: AppColors.deepCaramelMuted,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.warmPastryCrust.withValues(alpha: 0.4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.pastryCrustBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.custardCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.deepCaramel),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.custardCream,
        indicatorColor: AppColors.warmPastryCrust,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.caramelizedAmber);
          }
          return const IconThemeData(color: AppColors.deepCaramelMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              color: AppColors.caramelizedAmber,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return GoogleFonts.plusJakartaSans(
            color: AppColors.deepCaramelMuted,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pastryCrustBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pastryCrustBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.caramelizedAmber, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.caramelizedAmber,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.caramelizedAmber,
          side: const BorderSide(color: AppColors.caramelizedAmber),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.caramelizedAmber,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.caramelizedAmber,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.deepCaramel,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepCaramel,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.custardCream,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.custardCream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.deepCaramel,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.deepCaramel,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.caramelizedAmber;
          }
          return AppColors.pastryCrustBorder;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.warmPastryCrust;
          }
          return AppColors.pastryCrustLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.caramelizedAmber;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: AppColors.pastryCrustBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.caramelizedAmber,
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: AppColors.pastryCrustLight,
        selectedColor: AppColors.caramelizedAmber.withValues(alpha: 0.18),
        side: const BorderSide(color: AppColors.pastryCrustBorder, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.deepCaramel,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.pastryCrustBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepCaramelBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.caramelizedAmberLight,
        onPrimary: AppColors.deepCaramelBlack,
        primaryContainer: AppColors.darkPastryCardElevated,
        onPrimaryContainer: AppColors.darkTextPrimary,
        secondary: AppColors.caramelizedAmberLight,
        onSecondary: AppColors.deepCaramelBlack,
        surface: AppColors.deepCaramelBlack,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkPastryBorder,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextMuted,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextMuted,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkPastryCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkPastryBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepCaramelBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.deepCaramelBlack,
        indicatorColor: AppColors.darkPastryCardElevated,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.caramelizedAmberLight);
          }
          return const IconThemeData(color: AppColors.darkTextMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              color: AppColors.caramelizedAmberLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return GoogleFonts.plusJakartaSans(
            color: AppColors.darkTextMuted,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkPastryCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPastryBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPastryBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.caramelizedAmberLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.caramelizedAmberLight,
          foregroundColor: AppColors.deepCaramelBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.caramelizedAmberLight,
          side: const BorderSide(color: AppColors.caramelizedAmberLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.caramelizedAmberLight,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.caramelizedAmberLight,
        foregroundColor: AppColors.deepCaramelBlack,
        elevation: 2,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkPastryCardElevated,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkPastryCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.caramelizedAmberLight;
          }
          return AppColors.darkPastryBorder;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkPastryCardElevated;
          }
          return AppColors.deepCaramelBlack;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.caramelizedAmberLight;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.deepCaramelBlack),
        side: const BorderSide(color: AppColors.darkPastryBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.caramelizedAmberLight,
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: AppColors.darkPastryCardElevated,
        selectedColor: AppColors.caramelizedAmber.withValues(alpha: 0.25),
        side: const BorderSide(color: AppColors.darkPastryBorder, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkPastryBorder,
        thickness: 1,
      ),
    );
  }
}
