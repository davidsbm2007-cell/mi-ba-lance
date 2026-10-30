import '../transactions/summary.dart';
import '../transactions/transaction.dart';

class MonthTotals {
  const MonthTotals(this.month, this.incomeCents, this.expenseCents);

  final DateTime month;
  final int incomeCents;
  final int expenseCents;
}

/// Totales de los [count] meses que terminan en [end] (el más antiguo primero).
List<MonthTotals> lastMonths(List<Tx> all, DateTime end, {int count = 6}) {
  final out = <MonthTotals>[];
  for (var i = count - 1; i >= 0; i--) {
    final month = DateTime(end.year, end.month - i);
    final s = summarize(all, month);
    out.add(MonthTotals(month, s.incomeCents, s.expenseCents));
  }
  return out;
}

/// Saldo acumulado de todo lo anterior a [limit] (exclusivo).
int balanceBefore(List<Tx> all, DateTime limit) {
  var total = 0;
  for (final t in all) {
    if (!t.date.isBefore(limit)) continue;
    total += t.kind == TxKind.income ? t.amountCents : -t.amountCents;
  }
  return total;
}

/// Variación porcentual. Null cuando no hay base para comparar.
double? pctChange(int current, int previous) =>
    previous <= 0 ? null : (current - previous) * 100 / previous;

class DashboardData {
  const DashboardData({
    required this.balance,
    required this.balancePct,
    required this.income,
    required this.incomePct,
    required this.expense,
    required this.expensePct,
    required this.savings,
    required this.savingsPct,
    required this.months,
    required this.balanceSeries,
    required this.byCategory,
  });

  final int balance;
  final double? balancePct;
  final int income;
  final double? incomePct;
  final int expense;
  final double? expensePct;
  final int savings;
  final double? savingsPct;
  final List<MonthTotals> months;

  /// Saldo al cierre de cada uno de los últimos 6 meses.
  final List<int> balanceSeries;
  final Map<String, int> byCategory;

  factory DashboardData.from(List<Tx> all, DateTime month) {
    final cur = summarize(all, month);
    final prev = summarize(all, DateTime(month.year, month.month - 1));
    final balance = balanceBefore(all, DateTime(month.year, month.month + 1));
    final prevBalance = balanceBefore(all, DateTime(month.year, month.month));
    final savings = cur.incomeCents - cur.expenseCents;
    final prevSavings = prev.incomeCents - prev.expenseCents;

    return DashboardData(
      balance: balance,
      balancePct: pctChange(balance, prevBalance),
      income: cur.incomeCents,
      incomePct: pctChange(cur.incomeCents, prev.incomeCents),
      expense: cur.expenseCents,
      expensePct: pctChange(cur.expenseCents, prev.expenseCents),
      savings: savings,
      savingsPct: pctChange(savings, prevSavings),
      months: lastMonths(all, month),
      balanceSeries: [
        for (var i = 5; i >= 0; i--)
          balanceBefore(all, DateTime(month.year, month.month - i + 1)),
      ],
      byCategory: cur.expenseByCategory,
    );
  }
}
