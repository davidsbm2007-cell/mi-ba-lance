import '../../core/ids.dart';
import '../budgets/budget.dart';
import '../cards/bank_card.dart';
import '../debts/debt.dart';
import '../goals/goal.dart';
import '../transactions/transaction.dart';

const _demoBudgetLimits = <String, int>{
  'Alimentación': 100000,
  'Hogar': 80000,
  'Transporte': 40000,
  'Salud': 30000,
  'Entretenimiento': 25000,
  'Educación': 30000,
  'Otros': 15000,
};

List<Budget> demoBudgetList() => [
      for (final e in _demoBudgetLimits.entries) Budget(e.key, e.value),
    ];

List<Goal> demoGoalList() => [
      Goal(
        id: stableId('demo-goal-1'),
        name: 'Viaje familiar',
        note: 'Explorar juntos nuevos lugares',
        savedCents: 136000,
        targetCents: 200000,
        iconKey: 'flight',
        colorIndex: 0,
      ),
      Goal(
        id: stableId('demo-goal-2'),
        name: 'Fondo de emergencia',
        note: 'Tres meses de gastos cubiertos',
        savedCents: 210000,
        targetCents: 600000,
        iconKey: 'shield',
        colorIndex: 1,
      ),
      Goal(
        id: stableId('demo-goal-3'),
        name: 'Laptop nueva',
        note: 'Para trabajar y crear',
        savedCents: 45000,
        targetCents: 120000,
        iconKey: 'laptop',
        colorIndex: 2,
      ),
    ];

List<Debt> demoDebtList(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime inDays(int d) => today.add(Duration(days: d));

  return [
    Debt(
      id: stableId('demo-debt-1'),
      kind: DebtKind.owedToMe,
      person: 'Carlos Mendoza',
      concept: 'Préstamo personal',
      totalCents: 15000,
      paidCents: 5000,
      dueDate: inDays(10),
      createdAt: inDays(-40),
    ),
    Debt(
      id: stableId('demo-debt-2'),
      kind: DebtKind.owedToMe,
      person: 'María Torres',
      concept: 'Venta a crédito',
      totalCents: 8500,
      dueDate: inDays(25),
      createdAt: inDays(-12),
    ),
    Debt(
      id: stableId('demo-debt-3'),
      kind: DebtKind.owedToMe,
      person: 'Andrés Salazar',
      concept: 'Cena compartida',
      totalCents: 3200,
      dueDate: inDays(-6),
      createdAt: inDays(-20),
    ),
    Debt(
      id: stableId('demo-debt-4'),
      kind: DebtKind.iOwe,
      person: 'Banco Pichincha',
      concept: 'Tarjeta de crédito',
      totalCents: 42000,
      paidCents: 12000,
      dueDate: inDays(5),
      createdAt: inDays(-60),
    ),
    Debt(
      id: stableId('demo-debt-5'),
      kind: DebtKind.iOwe,
      person: 'Papá',
      concept: 'Préstamo para el carro',
      totalCents: 30000,
      paidCents: 10000,
      createdAt: inDays(-90),
    ),
    Debt(
      id: stableId('demo-debt-6'),
      kind: DebtKind.iOwe,
      person: 'Mi Comisariato',
      concept: 'Electrodoméstico a cuotas',
      totalCents: 18000,
      paidCents: 6000,
      dueDate: inDays(18),
      createdAt: inDays(-30),
    ),
  ];
}

// (día, categoría, detalle, centavos)
const _monthlyExpenses = <(int, String, String, int)>[
  (2, 'Hogar', 'Arriendo', 45000),
  (5, 'Alimentación', 'Supermaxi', 21000),
  (6, 'Transporte', 'Gasolina Primax', 4500),
  (8, 'Hogar', 'Luz y agua', 6800),
  (9, 'Entretenimiento', 'Netflix', 1299),
  (10, 'Hogar', 'Internet', 4500),
  (11, 'Educación', 'Curso en línea', 4900),
  (12, 'Alimentación', 'Tía', 14500),
  (14, 'Transporte', 'Gasolina Primax', 4500),
  (16, 'Entretenimiento', 'Cine', 2400),
  (19, 'Alimentación', 'Supermaxi', 18500),
  (20, 'Salud', 'Farmacias SanaSana', 2870),
  (20, 'Transporte', 'Uber', 2400),
  (22, 'Transporte', 'Mantenimiento', 9800),
  (24, 'Otros', 'Regalo', 6500),
  (26, 'Alimentación', 'Mercado', 9800),
];

const _growth = [0.9, 0.95, 1.05, 1.0, 1.15, 1.25];

/// Seis meses de movimientos de ejemplo que terminan en [now].
List<Tx> generateDemoTransactions(DateTime now) {
  final out = <Tx>[];

  void add(DateTime month, int day, TxKind kind, String category, String note,
      int cents) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final date = DateTime(month.year, month.month, day > lastDay ? lastDay : day);
    if (date.isAfter(now)) return;
    out.add(Tx(
      id: stableId('demo-tx-${out.length}'),
      kind: kind,
      amountCents: cents,
      category: category,
      date: date,
      note: note,
    ));
  }

  for (var i = 0; i < 6; i++) {
    final month = DateTime(now.year, now.month - 5 + i);
    add(month, 1, TxKind.income, 'Nómina', 'Nómina', 240000 + i * 5000);
    if (i.isOdd) {
      add(month, 15, TxKind.income, 'Negocio', 'Proyecto freelance',
          20000 + i * 8000);
    }
    for (final e in _monthlyExpenses) {
      add(month, e.$1, TxKind.expense, e.$2, e.$3, (e.$4 * _growth[i]).round());
    }
  }

  out.sort((a, b) => b.date.compareTo(a.date));
  return out;
}

/// Tarjetas de ejemplo: dos de crédito (una cerca de su cupo) y una de débito.
List<BankCard> demoCardList() => [
      BankCard(
        id: stableId('demo-card-1'),
        name: 'Visa Pichincha',
        kind: CardKind.credit,
        network: CardNetwork.visa,
        last4: '4821',
        limitCents: 300000,
        balanceCents: 126500,
        cutDay: 15,
        dueDay: 3,
        colorIndex: 0,
      ),
      BankCard(
        id: stableId('demo-card-2'),
        name: 'Diners Club',
        kind: CardKind.credit,
        network: CardNetwork.diners,
        last4: '0937',
        limitCents: 150000,
        balanceCents: 138000,
        cutDay: 25,
        dueDay: 12,
        colorIndex: 3,
      ),
      BankCard(
        id: stableId('demo-card-3'),
        name: 'Cuenta Produbanco',
        kind: CardKind.debit,
        network: CardNetwork.mastercard,
        last4: '2204',
        balanceCents: 245000,
        colorIndex: 1,
      ),
    ];
