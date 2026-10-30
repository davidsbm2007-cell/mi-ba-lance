import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../core/session.dart';
import '../../core/format.dart';
import '../../core/widgets.dart';
import '../budgets/budget.dart';
import '../demo/demo_actions.dart';
import '../goals/goal.dart';
import '../goals/goal_card.dart';
import '../shell/page_body.dart';
import '../transactions/summary.dart';
import '../transactions/transactions_provider.dart';
import 'analytics.dart';
import 'dashboard_cards.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(transactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final data = DashboardData.from(all, month);
    final budgetList = ref.watch(budgetsProvider);
    final goals = ref.watch(goalsProvider);
    final featuredGoal = goals.isEmpty
        ? null
        : goals.firstWhere((g) => !g.isComplete, orElse: () => goals.first);
    final recent = inMonth(all, month).take(5).toList();

    // Lo primero que se lee: cómo va el mes frente a lo presupuestado.
    final budgetLimit = budgetList.fold<int>(0, (s, b) => s + b.limitCents);
    final budgetSpent = budgetList.fold<int>(
      0,
      (s, b) => s + (data.byCategory[b.category] ?? 0),
    );
    final subtitle = budgetLimit > 0
        ? 'Llevas ${money(budgetSpent)} de ${money(budgetLimit)} presupuestados este mes.'
        : 'Tu dinero, en perspectiva.';

    return PageBody(
      title: 'Hola, ${ref.watch(sessionProvider).displayName}',
      subtitle: subtitle,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          final mid = c.maxWidth >= 900;
          final compact = c.maxWidth < 600;
          const gap = SizedBox(width: 16, height: 16);

          final stats = StatsStrip(data: data, compact: compact);

          final banner = all.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _EmptyBanner(
                    onLoadDemo: () => loadDemoData(ref),
                  ),
                )
              : const SizedBox.shrink();

          final hero = HeroCard(data: data, compact: compact);
          final lineChart = IncomeExpenseCard(months: data.months, fill: mid);
          final donut = CategoryDonutCard(byCategory: data.byCategory);
          final budgets = BudgetsCard(
            budgets: budgetList,
            spentByCategory: data.byCategory,
          );
          final recents = RecentCard(items: recent);
          final Widget goal = featuredGoal == null
              ? const EmptyGoalCard()
              : GoalCard(goal: featuredGoal, showHeader: true, showButton: true);

          if (mid) {
            return Column(
              children: [
                banner,
                SizedBox(
                  height: 184,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: hero),
                      gap,
                      Expanded(flex: 6, child: stats),
                    ],
                  ),
                ),
                gap,
                SizedBox(
                  height: 392,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: lineChart),
                      gap,
                      Expanded(flex: 4, child: donut),
                    ],
                  ),
                ),
                gap,
                if (wide)
                  SizedBox(
                    height: 396,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: budgets),
                        gap,
                        Expanded(child: recents),
                        gap,
                        Expanded(child: goal),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 396,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: budgets),
                        gap,
                        Expanded(child: recents),
                      ],
                    ),
                  ),
                  gap,
                  goal,
                ],
              ],
            );
          }

          return Column(
            children: [
              banner,
              hero,
              gap,
              stats,
              gap,
              lineChart,
              gap,
              donut,
              gap,
              budgets,
              gap,
              recents,
              gap,
              goal,
            ],
          );
        },
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.onLoadDemo});

  final VoidCallback onLoadDemo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aún no tienes movimientos',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra el primero con "Nuevo movimiento", o mira cómo luce con datos de ejemplo.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onLoadDemo,
            child: const Text('Cargar datos de ejemplo'),
          ),
        ],
      ),
    );
  }
}
