import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../core/ids.dart';
import '../features/budgets/budget.dart';
import '../features/cards/bank_card.dart';
import '../features/debts/debt.dart';
import '../features/goals/goal.dart';
import '../features/transactions/transaction.dart';
import 'database.dart';

/// Copia en memoria de lo guardado, para que las pantallas lean sin esperar.
class LocalSnapshot {
  const LocalSnapshot({
    this.transactions = const [],
    this.budgets = const [],
    this.goals = const [],
    this.debts = const [],
    this.cards = const [],
  });

  final List<Tx> transactions;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<Debt> debts;
  final List<BankCard> cards;
}

final _dayFormat = DateFormat('yyyy-MM-dd');

String _debtKindToDb(DebtKind k) => k == DebtKind.owedToMe ? 'owed_to_me' : 'i_owe';
DebtKind _debtKindFromDb(String s) =>
    s == 'owed_to_me' ? DebtKind.owedToMe : DebtKind.iOwe;

/// Lee y escribe en la base local. Los borrados son lógicos (`deleted_at`) para
/// poder sincronizarlos con Supabase más adelante.
class LocalRepository {
  LocalRepository(this.db);

  final AppDatabase db;

  Future<LocalSnapshot> loadAll() async {
    final cats = await db.select(db.categories).get();
    final nameById = {for (final c in cats) c.id: c.name};

    final txs = await (db.select(db.transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    final budgets = await (db.select(db.budgets)
          ..where((b) => b.deletedAt.isNull() & b.month.isNull()))
        .get();
    final goals = await (db.select(db.goals)
          ..where((g) => g.deletedAt.isNull())
          ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
        .get();
    final debts = await (db.select(db.debts)
          ..where((d) => d.deletedAt.isNull())
          ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
        .get();

    final cardRows = await (db.select(db.cards)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();

    return LocalSnapshot(
      cards: [
        for (final c in cardRows)
          BankCard(
            id: c.id,
            name: c.name,
            kind: CardKind.values.byName(c.kind),
            network: CardNetwork.values.byName(c.network),
            last4: c.last4,
            limitCents: c.limitCents,
            balanceCents: c.balanceCents,
            cutDay: c.cutDay,
            dueDay: c.dueDay,
            colorIndex: c.colorIndex,
          ),
      ],
      transactions: [
        for (final t in txs)
          Tx(
            id: t.id,
            kind: TxKind.values.byName(t.kind),
            amountCents: t.amountCents,
            category: nameById[t.categoryId] ?? 'Otros',
            date: t.occurredAt,
            note: t.note ?? '',
          ),
      ],
      budgets: [
        for (final b in budgets)
          if (nameById[b.categoryId] != null)
            Budget(nameById[b.categoryId]!, b.limitCents),
      ],
      goals: [
        for (final g in goals)
          Goal(
            id: g.id,
            name: g.name,
            note: g.note,
            targetCents: g.targetCents,
            savedCents: g.savedCents,
            iconKey: g.iconKey,
            colorIndex: g.colorIndex,
          ),
      ],
      debts: [
        for (final d in debts)
          Debt(
            id: d.id,
            kind: _debtKindFromDb(d.kind),
            person: d.person,
            concept: d.concept,
            totalCents: d.totalCents,
            paidCents: d.paidCents,
            dueDate: d.dueDate,
            createdAt: d.createdAt,
          ),
      ],
    );
  }

  // Categorías ---------------------------------------------------------------

  /// Id de la categoría por nombre y tipo; la crea si no existe.
  Future<String> _categoryId(String name, TxKind kind) async {
    final found = await (db.select(db.categories)
          ..where((c) => c.name.equals(name) & c.kind.equals(kind.name))
          ..limit(1))
        .getSingleOrNull();
    if (found != null) {
      if (found.deletedAt != null) {
        await (db.update(db.categories)..where((c) => c.id.equals(found.id)))
            .write(CategoriesCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ));
      }
      return found.id;
    }
    final id = newId();
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          userId: kLocalUserId,
          name: name,
          kind: kind.name,
        ));
    return id;
  }

  // Transacciones ------------------------------------------------------------

  Future<void> _writeTx(Tx tx) async {
    final categoryId = await _categoryId(tx.category, tx.kind);
    await db.into(db.transactions).insertOnConflictUpdate(
          TransactionsCompanion.insert(
            id: tx.id,
            userId: kLocalUserId,
            categoryId: Value(categoryId),
            amountCents: tx.amountCents,
            kind: tx.kind.name,
            occurredOn: _dayFormat.format(tx.date),
            occurredAt: tx.date,
            note: Value(tx.note.isEmpty ? null : tx.note),
            updatedAt: Value(DateTime.now()),
            deletedAt: const Value(null),
          ),
        );
  }

  Future<void> upsertTx(Tx tx) => db.transaction(() => _writeTx(tx));

  Future<void> deleteTx(String id) {
    final now = DateTime.now();
    return (db.update(db.transactions)..where((t) => t.id.equals(id)))
        .write(TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> replaceTxs(List<Tx> all) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.transactions)..where((t) => t.deletedAt.isNull()))
            .write(TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final tx in all) {
          await _writeTx(tx);
        }
      });

  // Presupuestos -------------------------------------------------------------

  Future<void> upsertBudget(String category, int limitCents) =>
      db.transaction(() async {
        final categoryId = await _categoryId(category, TxKind.expense);
        final existing = await (db.select(db.budgets)
              ..where((b) => b.categoryId.equals(categoryId) & b.month.isNull())
              ..limit(1))
            .getSingleOrNull();
        final now = DateTime.now();
        if (existing == null) {
          await db.into(db.budgets).insert(BudgetsCompanion.insert(
                id: newId(),
                userId: kLocalUserId,
                categoryId: Value(categoryId),
                limitCents: limitCents,
              ));
        } else {
          await (db.update(db.budgets)..where((b) => b.id.equals(existing.id)))
              .write(BudgetsCompanion(
            limitCents: Value(limitCents),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ));
        }
      });

  Future<void> deleteBudget(String category) async {
    final categoryId = await _categoryId(category, TxKind.expense);
    final now = DateTime.now();
    await (db.update(db.budgets)
          ..where((b) => b.categoryId.equals(categoryId) & b.month.isNull()))
        .write(BudgetsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> replaceBudgets(List<Budget> all) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.budgets)..where((b) => b.deletedAt.isNull()))
            .write(BudgetsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final b in all) {
          await upsertBudget(b.category, b.limitCents);
        }
      });

  // Metas --------------------------------------------------------------------

  Future<void> upsertGoal(Goal g) => db.into(db.goals).insertOnConflictUpdate(
        GoalsCompanion.insert(
          id: g.id,
          userId: kLocalUserId,
          name: g.name,
          note: Value(g.note),
          targetCents: g.targetCents,
          savedCents: Value(g.savedCents),
          iconKey: Value(g.iconKey),
          colorIndex: Value(g.colorIndex),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ),
      );

  Future<void> deleteGoal(String id) {
    final now = DateTime.now();
    return (db.update(db.goals)..where((g) => g.id.equals(id)))
        .write(GoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> replaceGoals(List<Goal> all) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.goals)..where((g) => g.deletedAt.isNull()))
            .write(GoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final g in all) {
          await upsertGoal(g);
        }
      });

  // Deudas -------------------------------------------------------------------

  Future<void> upsertDebt(Debt d) => db.into(db.debts).insertOnConflictUpdate(
        DebtsCompanion.insert(
          id: d.id,
          userId: kLocalUserId,
          kind: _debtKindToDb(d.kind),
          person: d.person,
          concept: Value(d.concept),
          totalCents: d.totalCents,
          paidCents: Value(d.paidCents),
          dueDate: Value(d.dueDate),
          createdAt: Value(d.createdAt),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ),
      );

  Future<void> deleteDebt(String id) {
    final now = DateTime.now();
    return (db.update(db.debts)..where((d) => d.id.equals(id)))
        .write(DebtsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> replaceDebts(List<Debt> all) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.debts)..where((d) => d.deletedAt.isNull()))
            .write(DebtsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final d in all) {
          await upsertDebt(d);
        }
      });

  // Tarjetas -----------------------------------------------------------------

  Future<void> upsertCard(BankCard c) => db.into(db.cards).insertOnConflictUpdate(
        CardsCompanion.insert(
          id: c.id,
          userId: kLocalUserId,
          name: c.name,
          kind: c.kind.name,
          network: Value(c.network.name),
          last4: Value(c.last4),
          limitCents: Value(c.limitCents),
          balanceCents: Value(c.balanceCents),
          cutDay: Value(c.cutDay),
          dueDay: Value(c.dueDay),
          colorIndex: Value(c.colorIndex),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ),
      );

  Future<void> deleteCard(String id) {
    final now = DateTime.now();
    return (db.update(db.cards)..where((c) => c.id.equals(id)))
        .write(CardsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> replaceCards(List<BankCard> all) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.cards)..where((c) => c.deletedAt.isNull()))
            .write(CardsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final c in all) {
          await upsertCard(c);
        }
      });
}
