import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../dashboard/dashboard_cards.dart';
import '../shell/page_body.dart';
import '../transactions/summary.dart';
import '../transactions/transaction.dart';
import '../transactions/transactions_provider.dart';
import 'budget.dart';
import 'budget_dialog.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, List<Budget> budgets) async {
    final taken = {for (final b in budgets) b.category};
    if (expenseCategories.every(taken.contains)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tienes un presupuesto en todas las categorías')),
      );
      return;
    }
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => BudgetDialog(takenCategories: taken),
    );
    if (result != null) {
      await ref.read(budgetsProvider.notifier).upsert(result.category, result.limitCents);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Budget budget) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => BudgetDialog(takenCategories: const {}, existing: budget),
    );
    if (result != null) {
      await ref.read(budgetsProvider.notifier).upsert(result.category, result.limitCents);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Budget budget) async {
    final ok = await confirmDialog(
      context,
      title: '¿Eliminar presupuesto?',
      message: 'Se quitará el límite de ${budget.category}. Tus gastos no se borran.',
    );
    if (ok) await ref.read(budgetsProvider.notifier).remove(budget.category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final all = ref.watch(transactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final summary = summarize(all, month);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    // Lo que más urge: la categoría más cerca de su límite.
    Budget? tightest;
    var tightestRatio = 0.0;
    for (final b in budgets) {
      final r = b.limitCents == 0
          ? 0.0
          : (summary.expenseByCategory[b.category] ?? 0) / b.limitCents;
      if (r > tightestRatio) {
        tightestRatio = r;
        tightest = b;
      }
    }

    final totalLimit = budgets.fold<int>(0, (a, b) => a + b.limitCents);
    final totalSpent = budgets.fold<int>(
      0,
      (a, b) => a + (summary.expenseByCategory[b.category] ?? 0),
    );

    return PageBody(
      title: 'Presupuestos',
      subtitle: 'Controla cuánto gastas por categoría',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _add(context, ref, budgets),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo presupuesto'),
            ),
          ),
          const SizedBox(height: 16),
          if (budgets.isEmpty)
            const AppCard(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconBadge(icon: Icons.pie_chart_outline, color: Brand.teal, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'Aún no tienes presupuestos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ponle un límite mensual a una categoría y te mostramos cuánto llevas.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presupuesto total del mes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: AnimatedMoney(
                            totalSpent,
                            cacheKey: 'bud.spent',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              fontFeatures: kTabular,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '  de ${money(totalLimit)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: muted,
                            fontFeatures: kTabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppProgress(
                    cacheKey: 'bud.total',
                    value: totalLimit == 0 ? 0 : totalSpent / totalLimit,
                    color: budgetStatusColor(
                      totalLimit == 0 ? 0 : totalSpent / totalLimit,
                    ),
                    height: 8,
                  ),
                  if (tightest != null && (tightestRatio * 100).round() >= 80) ...[
                    const SizedBox(height: 12),
                    Text(
                      tightestRatio > 1
                          ? '${tightest.category} superó su límite (${(tightestRatio * 100).round()}%).'
                          : '${tightest.category} va en ${(tightestRatio * 100).round()}% de su límite.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: budgetStatusText(context, tightestRatio),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
                final width = (c.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final b in budgets)
                      SizedBox(
                        width: width,
                        child: AppCard(
                          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: BudgetRow(
                                  category: b.category,
                                  spentCents: summary.expenseByCategory[b.category] ?? 0,
                                  limitCents: b.limitCents,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Más opciones',
                                onSelected: (v) => v == 'edit'
                                    ? _edit(context, ref, b)
                                    : _delete(context, ref, b),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Editar límite')),
                                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
