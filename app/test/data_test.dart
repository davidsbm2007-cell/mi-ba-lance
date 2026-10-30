import 'package:finanzas_app/features/budgets/budget.dart';
import 'package:finanzas_app/features/cards/bank_card.dart';
import 'package:finanzas_app/features/debts/debt.dart';
import 'package:finanzas_app/features/goals/goal.dart';
import 'package:finanzas_app/features/transactions/transaction.dart';
import 'package:finanzas_app/features/transactions/transactions_provider.dart';
import 'package:drift/native.dart';
import 'package:finanzas_app/data/backup/backup_service.dart';
import 'package:finanzas_app/data/database.dart';
import 'package:finanzas_app/data/local_repository.dart';
import 'package:finanzas_app/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

late AppDatabase _db;

/// Un contenedor nuevo sobre la misma base = cerrar y reabrir la app.
Future<ProviderContainer> _container() async {
  final c = ProviderContainer(overrides: await dataOverrides(_db));
  addTearDown(c.dispose);
  return c;
}

Debt _debt(String id, DebtKind kind, int total, {int paid = 0, DateTime? due}) => Debt(
      id: id,
      kind: kind,
      person: 'Persona $id',
      totalCents: total,
      paidCents: paid,
      dueDate: due,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  setUp(() => _db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => _db.close());

  test('presupuestos: crear, editar el límite, borrar y recargar', () async {
    final c = await _container();
    final n = c.read(budgetsProvider.notifier);

    await n.upsert('Hogar', 80000);
    await n.upsert('Salud', 30000);
    await n.upsert('Hogar', 90000);
    expect(c.read(budgetsProvider).length, 2);
    expect(c.read(budgetsProvider).firstWhere((b) => b.category == 'Hogar').limitCents, 90000);

    await n.remove('Salud');
    expect(c.read(budgetsProvider).map((b) => b.category), ['Hogar']);

    // Otro contenedor sobre la misma base = reabrir la app.
    final reopened = await _container();
    expect(reopened.read(budgetsProvider).single.limitCents, 90000);
  });

  test('metas: abonar acumula, se completa y persiste', () async {
    final c = await _container();
    final n = c.read(goalsProvider.notifier);

    await n.upsert(const Goal(id: 'g1', name: 'Viaje', targetCents: 100000));
    await n.contribute('g1', 25000);
    await n.contribute('g1', 25000);
    var g = c.read(goalsProvider).single;
    expect(g.savedCents, 50000);
    expect(g.progress, 0.5);
    expect(g.isComplete, isFalse);

    await n.contribute('g1', 60000);
    g = c.read(goalsProvider).single;
    expect(g.isComplete, isTrue);
    expect(g.progress, 1.0);
    expect(g.remainingCents, 0);

    final reopened = await _container();
    expect(reopened.read(goalsProvider).single.savedCents, 110000);
  });

  test('deudas: los abonos nunca superan el total y se puede marcar pagada', () async {
    final c = await _container();
    final n = c.read(debtsProvider.notifier);

    await n.upsert(_debt('a', DebtKind.owedToMe, 10000));
    await n.addPayment('a', 4000);
    expect(c.read(debtsProvider).single.pendingCents, 6000);

    await n.addPayment('a', 999999);
    expect(c.read(debtsProvider).single.paidCents, 10000);
    expect(c.read(debtsProvider).single.isPaid, isTrue);

    await n.upsert(_debt('b', DebtKind.iOwe, 5000));
    await n.markPaid('b');
    expect(c.read(debtsProvider).firstWhere((d) => d.id == 'b').isPaid, isTrue);
  });

  test('deudas: totales pendientes por tipo y vencimientos', () async {
    final c = await _container();
    final n = c.read(debtsProvider.notifier);
    await n.upsert(_debt('1', DebtKind.owedToMe, 10000, paid: 2000));
    await n.upsert(_debt('2', DebtKind.owedToMe, 5000));
    await n.upsert(_debt('3', DebtKind.iOwe, 7000, paid: 7000));
    await n.upsert(_debt('4', DebtKind.iOwe, 3000, due: DateTime(2026, 1, 10)));

    final debts = c.read(debtsProvider);
    expect(pendingTotal(debts, DebtKind.owedToMe), 13000);
    expect(pendingTotal(debts, DebtKind.iOwe), 3000);

    final now = DateTime(2026, 2, 1);
    expect(debts.firstWhere((d) => d.id == '4').isOverdue(now), isTrue);
    // Una deuda pagada nunca está vencida.
    expect(
      _debt('x', DebtKind.iOwe, 100, paid: 100, due: DateTime(2020, 1, 1)).isOverdue(now),
      isFalse,
    );

    final reopened = await _container();
    expect(reopened.read(debtsProvider).length, 4);
  });

  test('movimientos: se guardan, se borran y los datos sobreviven al reabrir', () async {
    final c = await _container();
    final n = c.read(transactionsProvider.notifier);

    await n.add(Tx(
      id: 't1', kind: TxKind.expense, amountCents: 1250,
      category: 'Alimentación', date: DateTime(2026, 3, 5, 14, 30), note: 'Almuerzo',
    ));
    await n.add(Tx(
      id: 't2', kind: TxKind.income, amountCents: 50000,
      category: 'Nómina', date: DateTime(2026, 3, 6, 9),
    ));
    await n.add(Tx(
      id: 't3', kind: TxKind.expense, amountCents: 300,
      category: 'Categoría nueva', date: DateTime(2026, 3, 7),
    ));
    await n.remove('t3');

    final reopened = await _container();
    final txs = reopened.read(transactionsProvider);
    expect(txs.map((t) => t.id), ['t2', 't1']); // más reciente primero
    final lunch = txs.last;
    expect(lunch.amountCents, 1250);
    expect(lunch.category, 'Alimentación');
    expect(lunch.note, 'Almuerzo');
    expect(lunch.date, DateTime(2026, 3, 5, 14, 30));
    expect(txs.first.note, '');
  });

  test('esquema: coincide con Supabase (borrado lógico, categorías y perfil local)', () async {
    final c = await _container();
    await c.read(transactionsProvider.notifier).add(Tx(
      id: 'x', kind: TxKind.expense, amountCents: 100,
      category: 'Hogar', date: DateTime(2026, 1, 2),
    ));
    await c.read(transactionsProvider.notifier).remove('x');

    // El borrado es lógico: la fila sigue, con deleted_at, lista para sincronizar.
    final rows = await _db.select(_db.transactions).get();
    expect(rows.single.deletedAt, isNotNull);
    expect(rows.single.occurredOn, '2026-01-02');
    expect(rows.single.currency, 'USD');

    final cats = await _db.select(_db.categories).get();
    expect(cats.where((k) => k.kind == 'expense').length, 7);
    expect(cats.where((k) => k.kind == 'income').length, 3);
    expect(rows.single.categoryId, cats.firstWhere((k) => k.name == 'Hogar').id);

    expect((await _db.select(_db.profiles).get()).single.defaultCurrency, 'USD');
    expect((await _db.select(_db.subscriptions).get()).single.status, 'trialing');
  });

  test('tarjetas: cupo, consumo, pago y datos que sobreviven al reabrir', () async {
    final c = await _container();
    final n = c.read(cardsProvider.notifier);

    await n.upsert(const BankCard(
      id: 'c1',
      name: 'Visa',
      kind: CardKind.credit,
      network: CardNetwork.visa,
      last4: '4821',
      limitCents: 100000,
      balanceCents: 20000,
      dueDay: 3,
    ));
    await n.upsert(const BankCard(
      id: 'c2',
      name: 'Cuenta',
      kind: CardKind.debit,
      balanceCents: 55000,
    ));

    await n.charge('c1', 30000);
    var visa = c.read(cardsProvider).firstWhere((k) => k.id == 'c1');
    expect(visa.usedCents, 50000);
    expect(visa.availableCents, 50000);
    expect(visa.usage, 0.5);

    // Un pago nunca deja la deuda en negativo.
    await n.pay('c1', 999999);
    visa = c.read(cardsProvider).firstWhere((k) => k.id == 'c1');
    expect(visa.usedCents, 0);

    await n.charge('c1', 25000);
    // La débito no cuenta como deuda ni como cupo.
    expect(totalUsed(c.read(cardsProvider)), 25000);
    expect(totalAvailable(c.read(cardsProvider)), 75000);

    final reopened = await _container();
    final cards = reopened.read(cardsProvider);
    expect(cards.length, 2);
    final back = cards.firstWhere((k) => k.id == 'c1');
    expect(back.usedCents, 25000);
    expect(back.last4, '4821');
    expect(back.network, CardNetwork.visa);
    expect(back.dueDay, 3);
    expect(cards.firstWhere((k) => k.id == 'c2').balanceCents, 55000);

    await n.remove('c2');
    expect((await _container()).read(cardsProvider).map((k) => k.id), ['c1']);
  });

  test('tarjetas: próxima fecha de pago', () {
    const card = BankCard(
      id: 'x',
      name: 'X',
      kind: CardKind.credit,
      limitCents: 1000,
      balanceCents: 500,
      dueDay: 31,
    );
    // Aún no pasa el día 31 de enero.
    expect(card.nextDue(DateTime(2026, 1, 10)), DateTime(2026, 1, 31));
    // Ya pasó: el siguiente pago cae en febrero, que no tiene día 31.
    expect(card.nextDue(DateTime(2026, 2, 1)), DateTime(2026, 2, 28));
    // Mismo día = hoy.
    expect(card.nextDue(DateTime(2026, 1, 31)), DateTime(2026, 1, 31));
  });

  test('archivo de datos: ida y vuelta del JSON conserva todo', () {
    final snap = LocalSnapshot(
      transactions: [
        Tx(
          id: 't1',
          kind: TxKind.expense,
          amountCents: 650,
          category: 'Alimentación',
          date: DateTime(2026, 10, 2, 13, 30),
          note: 'Almuerzo',
        ),
      ],
      budgets: const [Budget('Alimentación', 30000)],
      goals: const [Goal(id: 'g1', name: 'Viaje', targetCents: 100000, savedCents: 64000)],
      debts: [_debt('d1', DebtKind.iOwe, 5000)],
      cards: const [
        BankCard(id: 'c1', name: 'Visa', kind: CardKind.credit, limitCents: 300000, balanceCents: 1000),
      ],
    );
    final back = snapshotFromJson(snapshotToJson(snap))!;
    expect(back.transactions.single.note, 'Almuerzo');
    expect(back.transactions.single.date, DateTime(2026, 10, 2, 13, 30));
    expect(back.budgets.single.limitCents, 30000);
    expect(back.goals.single.savedCents, 64000);
    expect(back.debts.single.id, 'd1');
    expect(back.cards.single.limitCents, 300000);
    expect(snapshotFromJson('no es json'), isNull);
    expect(snapshotFromJson('{"format":"otro"}'), isNull);
    expect(snapshotIsEmpty(const LocalSnapshot()), isTrue);
  });
}
