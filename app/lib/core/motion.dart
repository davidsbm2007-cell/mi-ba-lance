import 'package:flutter/material.dart';

import 'anim_cache.dart';
import 'format.dart';

/// Duración de las animaciones de carga. Respeta "reducir movimiento" del sistema.
Duration motionDuration(BuildContext context, [int ms = 1100]) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duration(milliseconds: ms);

const kMotionCurve = Curves.easeOutCubic;

/// Cifra de dinero que sube desde $0,00 hasta su valor al aparecer, y que
/// viaja del valor anterior al nuevo cuando cambia (por ejemplo, al cambiar de mes).
/// Con [cacheKey], una cifra ya vista no vuelve a subir desde cero al regresar
/// a la pantalla: parte del último valor mostrado (ver [AnimCache]).
class AnimatedMoney extends StatefulWidget {
  const AnimatedMoney(this.cents, {super.key, this.style, this.ms = 1100, this.cacheKey});

  final int cents;
  final TextStyle? style;
  final int ms;
  final String? cacheKey;

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney> {
  late final double _from;

  @override
  void initState() {
    super.initState();
    _from = AnimCache.valueOf(widget.cacheKey) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    AnimCache.remember(widget.cacheKey, widget.cents.toDouble());
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from, end: widget.cents.toDouble()),
      duration: motionDuration(context, widget.ms),
      curve: kMotionCurve,
      builder: (context, v, _) => Text(
        money(v.round()),
        maxLines: 1,
        style: widget.style,
      ),
    );
  }
}

/// Anima de 0 a 1 al aparecer y vuelve a empezar cuando cambia [replayKey]
/// (los datos del gráfico). Sirve para que líneas y barras "crezcan".
/// Con [cacheKey], los mismos datos ya vistos aparecen completos sin repetir.
class GrowIn extends StatelessWidget {
  const GrowIn({
    super.key,
    required this.replayKey,
    required this.builder,
    this.ms = 1200,
    this.cacheKey,
  });

  final Object replayKey;
  final Widget Function(BuildContext context, double t) builder;
  final int ms;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    final signature = replayKey.hashCode.toDouble();
    final seen = AnimCache.valueOf(cacheKey) == signature;
    AnimCache.remember(cacheKey, signature);
    return TweenAnimationBuilder<double>(
      key: ValueKey(replayKey),
      tween: Tween(begin: seen ? 1 : 0, end: 1),
      duration: motionDuration(context, ms),
      curve: kMotionCurve,
      builder: (context, t, _) => builder(context, t),
    );
  }
}
