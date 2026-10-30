import 'package:flutter/material.dart';

/// Paleta de la app: azul marino como tinta y turquesa como único color de datos.
/// La interfaz es neutra; el color aparece en las cifras, no en el marco.
class Brand {
  static const navy = Color(0xFF0A2540);
  static const navyMid = Color(0xFF0B3556);
  static const deepTeal = Color(0xFF0B5C75);
  static const teal = Color(0xFF00A9BE);

  /// Turquesa oscuro para texto y enlaces sobre blanco (contraste 5:1).
  static const tealText = Color(0xFF0A7A90);
  static const cyan = Color(0xFF2ED3E0);
  static const orange = Color(0xFFF59A2B);

  /// Ámbar oscuro para texto de advertencia sobre blanco.
  static const warnText = Color(0xFF9A5B00);
  static const ink = Color(0xFF0F2238);
  static const gray = Color(0xFF5B6E84);
  static const bg = Color(0xFFF5F7FA);
  static const border = Color(0xFFE3E9EF);
  static const income = Color(0xFF16A06B);
  static const expense = Color(0xFFE5532C);

  /// Texto de ingreso/gasto sobre blanco con contraste suficiente.
  static const incomeText = Color(0xFF0B7D52);
  static const expenseText = Color(0xFFC2410C);
}

/// Cifras alineadas en columna.
const kTabular = [FontFeature.tabularFigures()];

const _radius = 12.0;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ground = dark ? const Color(0xFF0C1827) : Brand.bg;
  final card = dark ? const Color(0xFF132338) : Colors.white;
  final line = dark ? const Color(0xFF223850) : Brand.border;
  final ink = dark ? const Color(0xFFF1F5F9) : Brand.ink;
  final muted = dark ? const Color(0xFF9FB1C5) : Brand.gray;
  final accent = dark ? Brand.cyan : Brand.teal;
  final accentText = dark ? Brand.cyan : Brand.tealText;
  final primaryFill = dark ? Brand.teal : Brand.navy;
  final onPrimary = dark ? Brand.navy : Colors.white;

  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.teal,
    brightness: brightness,
  ).copyWith(
    primary: accentText,
    onPrimary: onPrimary,
    secondary: Brand.orange,
    onSecondary: Brand.navy,
    surface: ground,
    onSurface: ink,
    onSurfaceVariant: muted,
    outline: line,
    outlineVariant: line,
    error: dark ? const Color(0xFFFF8A65) : Brand.expenseText,
    surfaceTint: Colors.transparent,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: line),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Figtree',
    colorScheme: scheme,
    scaffoldBackgroundColor: ground,
    canvasColor: ground,
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: ground,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFFE2E8F0) : Brand.navy,
      contentTextStyle: TextStyle(
        fontFamily: 'Figtree',
        color: dark ? Brand.navy : Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: dark ? const Color(0xFF1E3550) : const Color(0xFFE9EEF3),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Figtree',
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? ink : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 24,
          color: s.contains(WidgetState.selected) ? ink : muted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryFill,
        foregroundColor: onPrimary,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(64, 44),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentText,
        textStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Brand.expense),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Brand.expense, width: 2),
      ),
      labelStyle: TextStyle(color: muted),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryFill,
      foregroundColor: onPrimary,
      elevation: 2,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: line)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (dark ? const Color(0xFF1E3550) : const Color(0xFFE9EEF3))
              : card,
        ),
        foregroundColor: WidgetStatePropertyAll(ink),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w600),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? primaryFill
            : (dark ? const Color(0xFF2B4560) : const Color(0xFFD5DDE6)),
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? onPrimary : Colors.white,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      selectedColor: dark ? const Color(0xFF1E3550) : const Color(0xFFE9EEF3),
      backgroundColor: card,
      side: BorderSide(color: line),
      labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
      checkmarkColor: ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accent,
      selectionColor: accent.withValues(alpha: 0.28),
      selectionHandleColor: accent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: 0.35)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFFE2E8F0) : Brand.navy,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 12,
        color: dark ? Brand.navy : Colors.white,
      ),
    ),
  );
}
