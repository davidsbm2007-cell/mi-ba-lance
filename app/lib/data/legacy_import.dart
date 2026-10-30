import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/ids.dart';
import '../features/budgets/budget.dart';
import '../features/debts/debt.dart';
import '../features/goals/goal.dart';
import '../features/transactions/transaction.dart';
import 'local_repository.dart';

const _doneKey = 'drift_import_v1';

List<Map<String, dynamic>> _readList(SharedPreferences prefs, String key) {
  final raw = prefs.getString(key);
  if (raw == null) return const [];
  try {
    return [for (final e in jsonDecode(raw) as List<dynamic>) e as Map<String, dynamic>];
  } catch (_) {
    return const [];
  }
}

/// Pasa una sola vez lo que la versión anterior guardaba como JSON en
/// SharedPreferences a la base SQLite. Los ids viejos (timestamps) se convierten
/// a UUID estables para que luego sincronicen con Supabase.
///
/// Las claves viejas se conservan como respaldo; ya no se leen.
Future<void> importLegacyPrefs(SharedPreferences prefs, LocalRepository repo) async {
  if (prefs.getBool(_doneKey) ?? false) return;

  final txs = [
    for (final j in _readList(prefs, 'transactions_v1'))
      Tx.fromJson({...j, 'id': stableId('legacy-tx-${j['id']}')}),
  ];
  final budgets = [for (final j in _readList(prefs, 'budgets_v1')) Budget.fromJson(j)];
  final goals = [
    for (final j in _readList(prefs, 'goals_v1'))
      Goal.fromJson({...j, 'id': stableId('legacy-goal-${j['id']}')}),
  ];
  final debts = [
    for (final j in _readList(prefs, 'debts_v1'))
      Debt.fromJson({...j, 'id': stableId('legacy-debt-${j['id']}')}),
  ];

  if (txs.isNotEmpty) await repo.replaceTxs(txs);
  if (budgets.isNotEmpty) await repo.replaceBudgets(budgets);
  if (goals.isNotEmpty) await repo.replaceGoals(goals);
  if (debts.isNotEmpty) await repo.replaceDebts(debts);

  await prefs.setBool(_doneKey, true);
}
