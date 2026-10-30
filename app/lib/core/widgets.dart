import 'package:flutter/material.dart';

import 'anim_cache.dart';
import 'motion.dart';

/// Superficie plana: un tono sobre el fondo y una línea de 1px. Sin sombra.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Relleno propio (por ejemplo, la tarjeta de saldo en azul marino).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: color == null
            ? Border.all(color: theme.colorScheme.outlineVariant)
            : null,
      ),
      child: child,
    );
  }
}

/// Identidad de una categoría o persona: cuadrado suave con su ícono.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
    this.square = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.28) : null,
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Barra de avance fina sobre una pista neutra.
class AppProgress extends StatefulWidget {
  const AppProgress({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.cacheKey,
  });

  final double value;
  final Color color;
  final double height;
  final String? cacheKey;

  @override
  State<AppProgress> createState() => _AppProgressState();
}

class _AppProgressState extends State<AppProgress> {
  late final double _from;

  @override
  void initState() {
    super.initState();
    _from = AnimCache.valueOf(widget.cacheKey) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final color = widget.color;
    final height = widget.height;
    final end = value.clamp(0.0, 1.0);
    AnimCache.remember(widget.cacheKey, end);
    final track = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF223850)
        : const Color(0xFFE8EDF2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _from, end: end),
        duration: motionDuration(context, 900),
        curve: kMotionCurve,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: track,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  const CardHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Control con forma de selector (por ahora solo visual).
class PillLabel extends StatelessWidget {
  const PillLabel(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
