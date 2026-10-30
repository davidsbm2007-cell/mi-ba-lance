import 'transaction.dart';

class MonthSummary {
  const MonthSummary({
    required this.incomeCents,
    required this.expenseCents,
    required this.expenseByCategory,
  });

  final int incomeCents;
  final int expenseCents;
  final Map<String, int> expenseByCategory;

  int get balanceCents => incomeCents - expenseCents;
}

List<Tx> inMonth(List<Tx> all, DateTime month) => all
    .where((t) => t.date.year == month.year && t.date.month == month.month)
    .toList();

MonthSummary summarize(List<Tx> all, DateTime month) {
  var income = 0;
  var expense = 0;
  final byCategory = <String, int>{};
  for (final t in inMonth(all, month)) {
    if (t.kind == TxKind.income) {
      income += t.amountCents;
    } else {
      expense += t.amountCents;
      byCategory.update(t.category, (v) => v + t.amountCents,
          ifAbsent: () => t.amountCents);
    }
  }
  return MonthSummary(
    incomeCents: income,
    expenseCents: expense,
    expenseByCategory: byCategory,
  );
}
