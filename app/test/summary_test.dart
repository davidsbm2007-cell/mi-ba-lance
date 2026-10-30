import 'package:finanzas_app/core/format.dart';
import 'package:finanzas_app/features/transactions/summary.dart';
import 'package:finanzas_app/features/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Tx _tx(TxKind kind, int cents, String cat, DateTime date) => Tx(
      id: '${date.microsecondsSinceEpoch}$cents$cat',
      kind: kind,
      amountCents: cents,
      category: cat,
      date: date,
    );

void main() {
  final may = DateTime(2026, 5, 10);
  final june = DateTime(2026, 6, 2);

  test('summarize suma ingresos, gastos y agrupa por categoría del mes', () {
    final all = [
      _tx(TxKind.income, 100000, 'Salario', may),
      _tx(TxKind.expense, 2500, 'Comida', may),
      _tx(TxKind.expense, 1500, 'Comida', may),
      _tx(TxKind.expense, 4000, 'Transporte', may),
      _tx(TxKind.expense, 9999, 'Ocio', june),
    ];
    final s = summarize(all, DateTime(2026, 5));
    expect(s.incomeCents, 100000);
    expect(s.expenseCents, 8000);
    expect(s.balanceCents, 92000);
    expect(s.expenseByCategory, {'Comida': 4000, 'Transporte': 4000});
  });

  test('mes sin movimientos da todo en cero', () {
    final s = summarize([], DateTime(2026, 5));
    expect(s.balanceCents, 0);
    expect(s.expenseByCategory, isEmpty);
  });

  test('parseAmountToCents acepta coma y punto, rechaza inválidos', () {
    expect(parseAmountToCents('12,50'), 1250);
    expect(parseAmountToCents('12.5'), 1250);
    expect(parseAmountToCents('0'), isNull);
    expect(parseAmountToCents('-3'), isNull);
    expect(parseAmountToCents('abc'), isNull);
  });

  test('Tx se serializa y deserializa sin pérdida', () {
    final t = _tx(TxKind.expense, 1234, 'Salud', may);
    final back = Tx.fromJson(t.toJson());
    expect(back.amountCents, 1234);
    expect(back.kind, TxKind.expense);
    expect(back.date, may);
  });
}
