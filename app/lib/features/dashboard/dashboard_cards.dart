import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../budgets/budget.dart';
import '../transactions/transaction.dart';
import '../transactions/tx_row.dart';
import 'analytics.dart';

/// Color de estado de un presupuesto: el color dice "va bien" o "cuidado",
/// no a qué categoría pertenece.
Color budgetStatusColor(double ratio) {
  // Se decide con el porcentaje que se muestra, para que barra y cifra coincidan.
  final pct = (ratio * 100).round();
  if (pct > 100) return Brand.expense;
  if (pct >= 80) return Brand.orange;
  return Brand.teal;
}

/// Versión de [budgetStatusColor] legible como texto sobre blanco.
Color budgetStatusText(BuildContext context, double ratio) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final pct = (ratio * 100).round();
  if (pct > 100) return dark ? const Color(0xFFFF8A65) : Brand.expenseText;
  if (pct >= 80) return dark ? Brand.orange : Brand.warnText;
  return dark ? Brand.cyan : Brand.tealText;
}

/// Flecha + porcentaje de variación frente al mes anterior.
/// El color dice si el cambio es bueno o malo, no si sube o baja.
class DeltaText extends StatelessWidget {
  const DeltaText({
    super.key,
    required this.pct,
    required this.upIsGood,
    this.digits = 0,
    this.showLabel = true,
    this.onDark = false,
  });

  final double? pct;
  final bool upIsGood;
  final int digits;
  final bool showLabel;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = onDark ? Colors.white70 : scheme.onSurfaceVariant;
    final p = pct;
    final Color color;
    if (p == null || p == 0) {
      color = muted;
    } else {
      final good = (p >= 0) == upIsGood;
      if (onDark) {
        color = good ? Brand.cyan : Brand.orange;
      } else if (dark) {
        color = good ? Brand.income : const Color(0xFFFF8A65);
      } else {
        color = good ? Brand.incomeText : Brand.expenseText;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p != null && p != 0)
          Icon(
            p >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
        Text(
          p == null ? '—' : '${percentLabel(p, digits: digits)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            fontFeatures: kTabular,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'vs. mes anterior',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

/// La respuesta de la pantalla: cuánto dinero hay. Plano, sin degradado.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.data, this.compact = false});

  final DashboardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? 18 : 24),
      color: Brand.navy,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedMoney(
                    data.balance,
                    cacheKey: 'dash.balance',
                    ms: 1400,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 32 : 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.05,
                      fontFeatures: kTabular,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DeltaText(
                  pct: data.balancePct,
                  upIsGood: true,
                  digits: 1,
                  onDark: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: SizedBox(
              height: compact ? 96 : 124,
              child: _Sparkline(values: data.balanceSeries),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final ys = [for (final v in values) v / 100];
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    if (maxY - minY < 1) {
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.15;
    final last = ys.length - 1;
    final base = minY - pad;

    return GrowIn(
      cacheKey: 'dash.spark',
      replayKey: Object.hashAll(values),
      ms: 1400,
      builder: (context, t) => _line(ys, last, base, maxY + pad, t),
    );
  }

  Widget _line(List<double> ys, int last, double minY, double maxY, double t) {
    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i <= last; i++)
                FlSpot(i.toDouble(), minY + (ys[i] - minY) * t),
            ],
            isCurved: false,
            color: Brand.cyan,
            barWidth: 2.5,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => spot.x == last,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4.5,
                    color: Colors.white,
                    strokeWidth: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingresos, gastos y ahorro: una sola superficie dividida en columnas.
/// Las cifras son texto, sin íconos ni mosaicos.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key, required this.data, this.compact = false});

  final DashboardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    final cells = [
      _StatCell(
        label: 'Ingresos',
        cents: data.income,
        pct: data.incomePct,
        upIsGood: true,
        compact: compact,
      ),
      _StatCell(
        label: 'Gastos',
        cents: data.expense,
        pct: data.expensePct,
        upIsGood: false,
        compact: compact,
      ),
      _StatCell(
        label: 'Ahorro',
        cents: data.savings,
        pct: data.savingsPct,
        upIsGood: true,
        compact: compact,
      ),
    ];
    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(child: cells[i]),
              if (i < cells.length - 1) VerticalDivider(color: line, width: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.cents,
    required this.pct,
    required this.upIsGood,
    required this.compact,
  });

  final String label;
  final int cents;
  final double? pct;
  final bool upIsGood;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(
              cents,
              cacheKey: 'dash.stat.$label',
              style: TextStyle(
                fontSize: compact ? 18 : 27,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: kTabular,
              ),
            ),
          ),
          const SizedBox(height: 8),
          DeltaText(pct: pct, upIsGood: upIsGood, showLabel: !compact),
        ],
      ),
    );
  }
}

double _niceStep(double max) {
  if (max <= 0) return 25;
  final raw = max / 4;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final norm = raw / mag;
  final nice = norm <= 1 ? 1 : (norm <= 2 ? 2 : (norm <= 5 ? 5 : 10));
  return nice * mag;
}

class IncomeExpenseCard extends StatelessWidget {
  const IncomeExpenseCard({super.key, required this.months, this.fill = false});

  final List<MonthTotals> months;

  /// Ocupa toda la altura de la tarjeta (cuando el padre le da una fija).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxVal = months.fold<double>(
      0,
      (m, t) => math.max(m, math.max(t.incomeCents, t.expenseCents) / 100),
    );
    final step = _niceStep(maxVal);
    final labelStyle = TextStyle(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
      fontFeatures: kTabular,
    );

    // Segmentos rectos y sin relleno: no inventan valores entre un mes y otro.
    LineChartBarData line(List<double> ys, Color c, double t) =>
        LineChartBarData(
          spots: [
            for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i] * t),
          ],
          isCurved: false,
          color: c,
          barWidth: 2.5,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          dotData: const FlDotData(show: false),
        );

    FlLine gridLine(double _) =>
        FlLine(color: scheme.outlineVariant, strokeWidth: 1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Ingresos vs. Gastos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const _Legend(color: Brand.teal, label: 'Ingresos'),
              const _Legend(color: Brand.orange, label: 'Gastos'),
              const PillLabel('Últimos 6 meses'),
            ],
          ),
          const SizedBox(height: 16),
          _PlotBox(
            fill: fill,
            child: GrowIn(
              cacheKey: 'dash.incexp',
              replayKey: Object.hashAll([
                for (final m in months) ...[m.incomeCents, m.expenseCents],
              ]),
              builder: (context, t) => LineChart(
                duration: Duration.zero,
                LineChartData(
                  minX: -0.15,
                  maxX: months.length - 1 + 0.15,
                  minY: 0,
                  maxY: step * 4,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: gridLine,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: step,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(axisMoney(v), style: labelStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if ((v - i).abs() > 0.01 ||
                              i < 0 ||
                              i >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              monthShort(months[i].month),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    line(
                      [for (final m in months) m.incomeCents / 100],
                      Brand.teal,
                      t,
                    ),
                    line(
                      [for (final m in months) m.expenseCents / 100],
                      Brand.orange,
                      t,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlotBox extends StatelessWidget {
  const _PlotBox({required this.fill, required this.child});

  final bool fill;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      fill ? Expanded(child: child) : SizedBox(height: 220, child: child);
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// Gastos por categoría como lista ordenada con barra fina proporcional.
/// Una sola tonalidad: el color no identifica categorías, la posición sí.
class CategoryDonutCard extends StatelessWidget {
  const CategoryDonutCard({super.key, required this.byCategory});

  final Map<String, int> byCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final top = entries.isEmpty ? 1 : entries.first.value;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rest = dark ? const Color(0xFF3B556F) : const Color(0xFFB9C6D3);

    Widget body;
    if (entries.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Sin gastos registrados este mes')),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedMoney(
            total,
            cacheKey: 'dash.cat.total',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontFeatures: kTabular,
            ),
          ),
          Text(
            'gastado este mes',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < math.min(entries.length, 5); i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entries[i].key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${(entries[i].value * 100 / total).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontFeatures: kTabular,
                        ),
                      ),
                      SizedBox(
                        width: 88,
                        child: Text(
                          money(entries[i].value),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFeatures: kTabular,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppProgress(
                    cacheKey: 'dash.cat.${entries[i].key}',
                    value: entries[i].value / top,
                    color: i == 0 ? Brand.teal : rest,
                    height: 4,
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            'Gastos por categoría',
            trailing: PillLabel('Este mes'),
          ),
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
  }
}

class BudgetRow extends StatelessWidget {
  const BudgetRow({
    super.key,
    required this.category,
    required this.spentCents,
    required this.limitCents,
  });

  final String category;
  final int spentCents;
  final int limitCents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = limitCents == 0 ? 0.0 : spentCents / limitCents;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: money(spentCents),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${money(limitCents)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                style: const TextStyle(fontFeatures: kTabular),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(ratio * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: budgetStatusText(context, ratio),
                    fontFeatures: kTabular,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          AppProgress(
            cacheKey: 'dash.budget.$category',
            value: ratio,
            color: budgetStatusColor(ratio),
          ),
        ],
      ),
    );
  }
}

class BudgetsCard extends StatelessWidget {
  const BudgetsCard({
    super.key,
    required this.budgets,
    required this.spentByCategory,
  });

  final List<Budget> budgets;
  final Map<String, int> spentByCategory;

  /// Los 4 presupuestos más consumidos.
  List<Budget> _top() {
    double ratio(Budget b) => b.limitCents == 0
        ? 0
        : (spentByCategory[b.category] ?? 0) / b.limitCents;
    final sorted = [...budgets]..sort((a, b) => ratio(b).compareTo(ratio(a)));
    return sorted.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            'Presupuestos de gastos',
            trailing: TextButton(
              onPressed: () => context.go('/presupuestos'),
              child: const Text('Ver todos'),
            ),
          ),
          const SizedBox(height: 4),
          if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Aún no tienes presupuestos'),
                    TextButton(
                      onPressed: () => context.go('/presupuestos'),
                      child: const Text('Crear presupuesto'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final b in _top())
              BudgetRow(
                category: b.category,
                spentCents: spentByCategory[b.category] ?? 0,
                limitCents: b.limitCents,
              ),
        ],
      ),
    );
  }
}

class RecentCard extends StatelessWidget {
  const RecentCard({super.key, required this.items});

  final List<Tx> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            'Últimos movimientos',
            trailing: TextButton(
              onPressed: () => context.go('/movimientos'),
              child: const Text('Ver todas'),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Aún no hay movimientos este mes')),
            )
          else
            LayoutBuilder(
              builder: (context, c) => Column(
                children: [
                  for (final t in items)
                    TxRow(tx: t, showDate: c.maxWidth >= 380),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
