import 'dart:convert';

import 'package:finanzas_app/features/dashboard/analytics.dart';
import 'package:finanzas_app/features/demo/demo_data.dart';
import 'package:finanzas_app/features/reports/report_pdf.dart';
import 'package:finanzas_app/features/transactions/summary.dart';
import 'package:finanzas_app/features/transactions/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ReportInput _input({bool empty = false}) {
  final now = DateTime(2026, 10, 27);
  final month = DateTime(2026, 10);
  final txs = empty ? <Tx>[] : generateDemoTransactions(now);
  return ReportInput(
    month: month,
    userName: 'David',
    generatedAt: now,
    data: DashboardData.from(txs, month),
    transactions: inMonth(txs, month),
    budgets: empty ? const [] : demoBudgetList(),
    goals: empty ? const [] : demoGoalList(),
    debts: empty ? const [] : demoDebtList(now),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('es'));

  test('genera un PDF válido con todas las secciones', () async {
    final bytes = await buildReportPdf(_input());

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
    expect(ascii.decode(bytes.sublist(bytes.length - 6), allowInvalid: true), contains('%%EOF'));
  });

  test('genera un PDF aunque no haya datos', () async {
    final bytes = await buildReportPdf(_input(empty: true));

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
