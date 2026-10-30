import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show TableUpdate;

import '../../features/budgets/budget.dart';
import '../../features/cards/bank_card.dart';
import '../../features/debts/debt.dart';
import '../../features/goals/goal.dart';
import '../../features/transactions/transaction.dart';
import '../database.dart';
import '../local_repository.dart';
import 'backup_file_stub.dart' if (dart.library.io) 'backup_file_io.dart';

export 'backup_file_stub.dart' if (dart.library.io) 'backup_file_io.dart'
    show backupFilePath;

const _format = 'mi-balance-datos';
const _version = 1;

bool snapshotIsEmpty(LocalSnapshot s) =>
    s.transactions.isEmpty &&
    s.budgets.isEmpty &&
    s.goals.isEmpty &&
    s.debts.isEmpty &&
    s.cards.isEmpty;

/// Los datos financieros como un documento JSON legible.
String snapshotToJson(LocalSnapshot s) => const JsonEncoder.withIndent('  ').convert({
      'format': _format,
      'version': _version,
      'savedAt': DateTime.now().toIso8601String(),
      'transactions': [for (final t in s.transactions) t.toJson()],
      'budgets': [for (final b in s.budgets) b.toJson()],
      'goals': [for (final g in s.goals) g.toJson()],
      'debts': [for (final d in s.debts) d.toJson()],
      'cards': [for (final c in s.cards) c.toJson()],
    });

/// Lee un documento escrito por [snapshotToJson]; null si no es válido.
LocalSnapshot? snapshotFromJson(String text) {
  try {
    final map = jsonDecode(text) as Map<String, dynamic>;
    if (map['format'] != _format) return null;
    List<T> read<T>(String key, T Function(Map<String, dynamic>) from) => [
          for (final e in (map[key] as List? ?? const []))
            from(e as Map<String, dynamic>),
        ];
    return LocalSnapshot(
      transactions: read('transactions', Tx.fromJson),
      budgets: read('budgets', Budget.fromJson),
      goals: read('goals', Goal.fromJson),
      debts: read('debts', Debt.fromJson),
      cards: read('cards', BankCard.fromJson),
    );
  } catch (_) {
    return null;
  }
}

/// Mantiene `mi_balance_datos.json` al día: cada cambio en la base local se
/// vuelca al archivo (con una pequeña espera para juntar varios cambios).
class AutoBackup {
  AutoBackup(this.db) : _repo = LocalRepository(db);

  final AppDatabase db;
  final LocalRepository _repo;
  StreamSubscription<Set<TableUpdate>>? _sub;
  Timer? _timer;

  /// Si la base está vacía pero hay un archivo con datos, los recupera.
  Future<bool> restoreIfEmpty() async {
    try {
      final current = await _repo.loadAll();
      if (!snapshotIsEmpty(current)) return false;
      final text = await readBackupFile();
      if (text == null) return false;
      final saved = snapshotFromJson(text);
      if (saved == null || snapshotIsEmpty(saved)) return false;
      await _repo.replaceTxs(saved.transactions);
      await _repo.replaceBudgets(saved.budgets);
      await _repo.replaceGoals(saved.goals);
      await _repo.replaceDebts(saved.debts);
      await _repo.replaceCards(saved.cards);
      return true;
    } catch (_) {
      return false;
    }
  }

  void start() {
    _sub = db.tableUpdates().listen((_) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 700), flush);
    });
  }

  Future<void> flush() async {
    try {
      await writeBackupFile(snapshotToJson(await _repo.loadAll()));
    } catch (_) {
      // El archivo es una copia extra; si falla no se interrumpe la app.
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _sub?.cancel();
  }
}
