import 'package:flutter/material.dart';

abstract final class TripColors {
  static const ink = Color(0xff173b38);
  static const primary = Color(0xff126b5e);
  static const mint = Color(0xffe5f2eb);
  static const background = Color(0xfff5f7f3);
  static const muted = Color(0xff62766e);
  static const line = Color(0xffe0e8e1);
  static const accent = Color(0xfff4ab6d);
}

ThemeData buildTripTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: TripColors.primary).copyWith(
    primary: TripColors.primary,
    onPrimary: Colors.white,
    primaryContainer: TripColors.mint,
    onPrimaryContainer: TripColors.ink,
    secondary: const Color(0xff99501e),
    secondaryContainer: const Color(0xffffe8d5),
    surface: Colors.white,
    onSurface: TripColors.ink,
    onSurfaceVariant: TripColors.muted,
    outline: const Color(0xffbdccc1),
    outlineVariant: TripColors.line,
    error: const Color(0xffb13f46),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'NotoSansThai',
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  return base.copyWith(
    scaffoldBackgroundColor: TripColors.background,
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 30,
        height: 1.35,
        fontWeight: FontWeight.w800,
        color: TripColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 26,
        height: 1.4,
        fontWeight: FontWeight.w800,
        color: TripColors.ink,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 23,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: TripColors.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 20,
        height: 1.45,
        fontWeight: FontWeight.w700,
        color: TripColors.ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: TripColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 15,
        height: 1.55,
        color: TripColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 14,
        height: 1.55,
        color: TripColors.ink,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 12,
        height: 1.5,
        color: TripColors.muted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TripColors.background,
      foregroundColor: TripColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansThai',
        color: TripColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: TripColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: const TextStyle(color: TripColors.muted),
      hintStyle: const TextStyle(color: Color(0xff879b90)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TripColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TripColors.primary, width: 2),
      ),
      errorMaxLines: 3,
      helperMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: rounded,
        textStyle: const TextStyle(
          fontFamily: 'NotoSansThai',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: rounded,
        side: const BorderSide(color: TripColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: rounded,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: TripColors.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: TripColors.mint,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      labelStyle: const TextStyle(
        fontFamily: 'NotoSansThai',
        color: TripColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: TripColors.mint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'NotoSansThai',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? TripColors.primary
              : TripColors.muted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Color(0xffcbd8ce),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: TripColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: TripColors.line, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TripColors.primary,
      linearTrackColor: TripColors.mint,
    ),
  );
}

String prettyDate(String date, {bool year = false}) {
  final d = DateTime.parse(date);
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  return '${d.day} ${months[d.month - 1]}${year ? ' ${d.year + 543}' : ''}';
}

class SoftBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const SoftBadge(this.text, {super.key, this.icon, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: (color ?? TripColors.primary).withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color ?? TripColors.primary),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? TripColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: TripColors.line),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TripColors.mint,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(icon, size: 34, color: TripColors.primary),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class FormIntro extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const FormIntro(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.edit_location_alt_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TripColors.mint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: TripColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class RouteMotif extends CustomPainter {
  const RouteMotif();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * .57, size.height)
      ..cubicTo(
        size.width * .92,
        size.height * .6,
        size.width * .38,
        size.height * .1,
        size.width,
        size.height * .15,
      );
    canvas.drawPath(path, paint);
    for (final p in [
      Offset(size.width * .7, size.height * .65),
      Offset(size.width * .85, size.height * .17),
    ]) {
      canvas.drawCircle(p, 12, paint);
      canvas.drawCircle(
        p,
        4,
        Paint()..color = TripColors.accent.withValues(alpha: .8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RouteMotif oldDelegate) => false;
}
