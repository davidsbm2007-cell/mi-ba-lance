import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shell/app_shell.dart' show BrandMark;

/// Guía de bienvenida: cuatro pantallas que muestran cómo usar la app.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_PageData>[
    _PageData(
      title: 'Tu dinero, claro',
      body:
          'Mira cuánto tienes, cuánto gastaste y cuánto te queda este mes, '
          'todo en una sola pantalla.',
      preview: _BalancePreview(),
    ),
    _PageData(
      title: 'Registra en segundos',
      body:
          'Toca el botón + para anotar un gasto o un ingreso. '
          'Elige la categoría y listo.',
      preview: _AddPreview(),
    ),
    _PageData(
      title: 'Pon límites y cumple metas',
      body:
          'Define un presupuesto por categoría y crea metas de ahorro. '
          'Las barras te avisan cuando te acercas al límite.',
      preview: _LimitsPreview(),
    ),
    _PageData(
      title: 'Tarjetas, deudas y reportes',
      body:
          'Controla tu cupo y fechas de pago, lo que debes y lo que te deben, '
          'y descarga un reporte en PDF.',
      preview: _CardsPreview(),
    ),
  ];

  bool get _last => _page == _pages.length - 1;

  Future<void> _finish() =>
      ref.read(sessionProvider.notifier).finishOnboarding();

  void _next() {
    if (_last) {
      _finish();
    } else {
      _controller.nextPage(
        duration: motionDuration(context, 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                  child: Row(
                    children: [
                      const BrandMark(size: 30),
                      const SizedBox(width: 10),
                      const Text(
                        'Mi Balance',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _last ? null : _finish,
                        child: const Text('Omitir'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) =>
                        _OnboardingPage(data: _pages[i]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: motionDuration(context, 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Brand.teal
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_last ? 'Empezar' : 'Siguiente'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.title,
    required this.body,
    required this.preview,
  });

  final String title;
  final String body;
  final Widget preview;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              data.preview,
              const SizedBox(height: 28),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.body,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Vistas previas dibujadas con los mismos componentes de la app ---------------

class _BalancePreview extends StatelessWidget {
  const _BalancePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Brand.navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance del mes',
            style: TextStyle(
              color: Color(0xFFB7C6D6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const AnimatedMoney(
            184250,
            ms: 1300,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontFeatures: kTabular,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _MiniStat('Ingresos', r'$1.250,00', Brand.cyan)),
              Expanded(
                child: _MiniStat('Gastos', r'$1.065,75', Color(0xFFFFB38F)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB7C6D6), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFeatures: kTabular,
          ),
        ),
      ],
    );
  }
}

class _AddPreview extends StatelessWidget {
  const _AddPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(
      IconData icon,
      String title,
      String when,
      String amount,
      Color color,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    when,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: kTabular,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Stack(
        children: [
          Column(
            children: [
              row(
                Icons.restaurant_outlined,
                'Almuerzo',
                'Hoy · Alimentación',
                r'-$6,50',
                Brand.expenseText,
              ),
              const Divider(height: 1),
              row(
                Icons.directions_bus_outlined,
                'Transporte',
                'Ayer · Transporte',
                r'-$1,20',
                Brand.expenseText,
              ),
              const Divider(height: 1),
              row(
                Icons.payments_outlined,
                'Sueldo',
                'Lunes · Nómina',
                r'+$850,00',
                Brand.incomeText,
              ),
              const SizedBox(height: 40),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Brand.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitsPreview extends StatelessWidget {
  const _LimitsPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar(String label, String detail, double value, Color color) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: kTabular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              AppProgress(value: value, color: color, height: 7),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          bar('Alimentación', r'$180 de $300', 0.6, Brand.teal),
          bar('Transporte', r'$92 de $100', 0.92, Brand.orange),
          bar('Meta: viaje', r'$640 de $1.000', 0.64, Brand.income),
        ],
      ),
    );
  }
}

class _CardsPreview extends StatelessWidget {
  const _CardsPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Brand.deepTeal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Visa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Spacer(),
              Icon(Icons.credit_card, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            '•••• •••• •••• 4821',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 1.5,
              fontFeatures: kTabular,
            ),
          ),
          const SizedBox(height: 18),
          const AppProgress(value: 0.38, color: Brand.cyan, height: 6),
          const SizedBox(height: 8),
          const Text(
            r'Disponible $1.860 · Pago en 9 días',
            style: TextStyle(color: Color(0xFFD3E6EE), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
