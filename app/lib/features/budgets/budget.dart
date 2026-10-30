import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Límite mensual de gasto para una categoría.
class Budget {
  const Budget(this.category, this.limitCents);

  final String category;
  final int limitCents;

  Map<String, dynamic> toJson() => {'category': category, 'limitCents': limitCents};

  factory Budget.fromJson(Map<String, dynamic> json) =>
      Budget(json['category'] as String, json['limitCents'] as int);
}

class BudgetsNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() => ref.watch(snapshotProvider).budgets;

  Future<void> upsert(String category, int limitCents) async {
    state = [
      for (final b in state)
        if (b.category != category) b,
      Budget(category, limitCents),
    ];
    await ref.read(repositoryProvider).upsertBudget(category, limitCents);
  }

  Future<void> remove(String category) async {
    state = [for (final b in state) if (b.category != category) b];
    await ref.read(repositoryProvider).deleteBudget(category);
  }

  Future<void> replaceAll(List<Budget> list) async {
    state = list;
    await ref.read(repositoryProvider).replaceBudgets(list);
  }

  Future<void> clear() => replaceAll(const []);
}

final budgetsProvider =
    NotifierProvider<BudgetsNotifier, List<Budget>>(BudgetsNotifier.new);
