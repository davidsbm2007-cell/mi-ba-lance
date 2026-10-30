import 'package:finanzas_app/core/format.dart';
import 'package:finanzas_app/features/dashboard/analytics.dart';
import 'package:finanzas_app/features/demo/demo_data.dart';
import 'package:finanzas_app/features/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Tx _tx(TxKind kind, int cents, DateTime date, [String cat = 'Otros']) => Tx(
      id: '${date.microsecondsSinceEpoch}-$cents-${kind.name}',
      kind: kind,
      amountCents: cents,
      category: cat,
      date: date,
    );

void main() {
  test('DashboardData compara el mes con el anterior', () {
    final all = [
      _tx(TxKind.income, 100000, DateTime(2026, 9, 1)),
      _tx(TxKind.expense, 40000, DateTime(2026, 9, 10)),
      _tx(TxKind.income, 120000, DateTime(2026, 10, 1)),
      _tx(TxKind.expense, 30000, DateTime(2026, 10, 10), 'Hogar'),
    ];
    final d = DashboardData.from(all, DateTime(2026, 10));

    expect(d.income, 120000);
    expect(d.incomePct, 20);
    expect(d.expense, 30000);
    expect(d.expensePct, -25);
    expect(d.savings, 90000);
    expect(d.savingsPct, 50);
    expect(d.balance, 150000);
    expect(d.balancePct, 150);
    expect(d.byCategory, {'Hogar': 30000});
    expect(d.months.length, 6);
    expect(d.months.last.month, DateTime(2026, 10));
    expect(d.balanceSeries.length, 6);
    expect(d.balanceSeries.last, d.balance);
  });

  test('sin mes anterior no hay variación porcentual', () {
    final d = DashboardData.from(
      [_tx(TxKind.income, 5000, DateTime(2026, 10, 2))],
      DateTime(2026, 10),
    );
    expect(d.incomePct, isNull);
    expect(d.balancePct, isNull);
  });

  test('los datos de ejemplo cubren seis meses y no tienen fechas futuras', () {
    final now = DateTime(2026, 10, 27);
    final demo = generateDemoTransactions(now);

    expect(demo.every((t) => !t.date.isAfter(now)), isTrue);
    expect(demo.map((t) => t.id).toSet().length, demo.length);
    final months = demo.map((t) => (t.date.year, t.date.month)).toSet();
    expect(months.length, 6);
    final d = DashboardData.from(demo, DateTime(2026, 10));
    expect(d.income, greaterThan(d.expense));
  });

  test('money usa formato en español', () {
    expect(money(845075), r'$8.450,75');
    expect(money(1250), r'$12,50');
    expect(money(-500), r'-$5,00');
  });
}
