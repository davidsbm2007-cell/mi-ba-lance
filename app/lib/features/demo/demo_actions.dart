import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budgets/budget.dart';
import '../cards/bank_card.dart';
import '../debts/debt.dart';
import '../goals/goal.dart';
import '../transactions/transactions_provider.dart';
import 'demo_data.dart';

/// Reemplaza todos los datos por el conjunto de ejemplo.
Future<void> loadDemoData(WidgetRef ref) async {
  final now = DateTime.now();
  await ref.read(transactionsProvider.notifier).replaceAll(generateDemoTransactions(now));
  await ref.read(budgetsProvider.notifier).replaceAll(demoBudgetList());
  await ref.read(goalsProvider.notifier).replaceAll(demoGoalList());
  await ref.read(debtsProvider.notifier).replaceAll(demoDebtList(now));
  await ref.read(cardsProvider.notifier).replaceAll(demoCardList());
}

Future<void> wipeAllData(WidgetRef ref) async {
  await ref.read(transactionsProvider.notifier).clear();
  await ref.read(budgetsProvider.notifier).clear();
  await ref.read(goalsProvider.notifier).clear();
  await ref.read(debtsProvider.notifier).clear();
  await ref.read(cardsProvider.notifier).clear();
}
