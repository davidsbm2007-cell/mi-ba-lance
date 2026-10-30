import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../budgets/budget.dart';
import '../dashboard/analytics.dart';
import '../debts/debt.dart';
import '../goals/goal.dart';
import '../transactions/transaction.dart';

const _navy = PdfColor.fromInt(0xFF0A2540);
const _gray = PdfColor.fromInt(0xFF6B7C93);
const _light = PdfColor.fromInt(0xFFF3F7FB);
const _income = PdfColor.fromInt(0xFF1FB57A);
const _expense = PdfColor.fromInt(0xFFF2653A);

class ReportInput {
  const ReportInput({
    required this.month,
    required this.userName,
    required this.generatedAt,
    required this.data,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.debts,
  });

  final DateTime month;
  final String userName;
  final DateTime generatedAt;
  final DashboardData data;

  /// Movimientos del mes del reporte.
  final List<Tx> transactions;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<Debt> debts;
}

String _pct(double? v) =>
    v == null ? 'sin datos previos' : '${v >= 0 ? '+' : '-'}${percentLabel(v)}% vs. mes anterior';

/// Genera el reporte mensual en PDF (A4).
Future<Uint8List> buildReportPdf(ReportInput r) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

  final doc = pw.Document(
    title: 'Reporte ${monthLabel(r.month)}',
    author: 'Mi Balance',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Mi Balance · Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _gray),
        ),
      ),
      build: (ctx) => [
        _header(r),
        pw.SizedBox(height: 14),
        _summary(r),
        ..._categories(r),
        ..._budgets(r),
        ..._debts(r),
        ..._goals(r),
        ..._movements(r),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(ReportInput r) => pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mi Balance',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Reporte financiero · ${monthLabel(r.month)}',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Preparado para ${r.userName} el ${fullDate(r.generatedAt)}',
            style: const pw.TextStyle(color: PdfColor.fromInt(0xFFBFD3E6), fontSize: 9),
          ),
        ],
      ),
    );

pw.Widget _box(String label, String value, String detail, PdfColor color) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 6),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _light,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _gray)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
            ),
            pw.SizedBox(height: 2),
            pw.Text(detail, style: const pw.TextStyle(fontSize: 7, color: _gray)),
          ],
        ),
      ),
    );

pw.Widget _summary(ReportInput r) {
  final d = r.data;
  return pw.Row(
    children: [
      _box('Saldo total', money(d.balance), _pct(d.balancePct), _navy),
      _box('Ingresos', money(d.income), _pct(d.incomePct), _income),
      _box('Gastos', money(d.expense), _pct(d.expensePct), _expense),
      _box('Ahorro', money(d.savings), _pct(d.savingsPct), _navy),
    ],
  );
}

pw.Widget _heading(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy),
      ),
    );

pw.Widget _note(String text) => pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 9, color: _gray),
    );

pw.Widget _table(
  List<String> headers,
  List<List<String>> rows, {
  Map<int, pw.Alignment> align = const {},
  Map<int, pw.TableColumnWidth>? widths,
}) =>
    pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _navy),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: align,
      oddRowDecoration: const pw.BoxDecoration(color: _light),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: widths,
    );

List<pw.Widget> _categories(ReportInput r) {
  final entries = r.data.byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final total = entries.fold<int>(0, (s, e) => s + e.value);
  return [
    _heading('Gastos por categoría'),
    if (entries.isEmpty)
      _note('Sin gastos registrados este mes.')
    else
      _table(
        ['Categoría', 'Monto', '% del gasto'],
        [
          for (final e in entries)
            [e.key, money(e.value), '${(e.value * 100 / total).round()}%'],
        ],
        align: const {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
      ),
  ];
}

List<pw.Widget> _budgets(ReportInput r) {
  return [
    _heading('Presupuestos'),
    if (r.budgets.isEmpty)
      _note('No hay presupuestos definidos.')
    else
      _table(
        ['Categoría', 'Gastado', 'Límite', 'Uso'],
        [
          for (final b in r.budgets)
            [
              b.category,
              money(r.data.byCategory[b.category] ?? 0),
              money(b.limitCents),
              '${b.limitCents == 0 ? 0 : ((r.data.byCategory[b.category] ?? 0) * 100 / b.limitCents).round()}%',
            ],
        ],
        align: const {
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
        },
      ),
  ];
}

List<pw.Widget> _debtTable(String title, List<Debt> debts) {
  final pending = debts.where((d) => !d.isPaid).toList()
    ..sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
  return [
    pw.SizedBox(height: 6),
    pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 3),
    if (pending.isEmpty)
      _note('Sin deudas pendientes.')
    else
      _table(
        ['Persona', 'Concepto', 'Total', 'Pendiente', 'Fecha de pago'],
        [
          for (final d in pending)
            [
              d.person,
              d.concept.isEmpty ? '-' : d.concept,
              money(d.totalCents),
              money(d.pendingCents),
              d.dueDate == null ? '-' : fullDate(d.dueDate!),
            ],
        ],
        align: const {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
      ),
  ];
}

List<pw.Widget> _debts(ReportInput r) {
  final owedToMe = pendingTotal(r.debts, DebtKind.owedToMe);
  final iOwe = pendingTotal(r.debts, DebtKind.iOwe);
  return [
    _heading('Deudas'),
    _note(
      'Me deben: ${money(owedToMe)}   ·   Debo: ${money(iOwe)}   ·   Balance neto: ${money(owedToMe - iOwe)}',
    ),
    ..._debtTable('Me deben', r.debts.where((d) => d.kind == DebtKind.owedToMe).toList()),
    ..._debtTable('Debo', r.debts.where((d) => d.kind == DebtKind.iOwe).toList()),
  ];
}

List<pw.Widget> _goals(ReportInput r) {
  return [
    _heading('Metas de ahorro'),
    if (r.goals.isEmpty)
      _note('No hay metas creadas.')
    else
      _table(
        ['Meta', 'Ahorrado', 'Objetivo', 'Avance'],
        [
          for (final g in r.goals)
            [
              g.name,
              money(g.savedCents),
              money(g.targetCents),
              '${(g.progress * 100).round()}%',
            ],
        ],
        align: const {
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
        },
      ),
  ];
}

List<pw.Widget> _movements(ReportInput r) {
  final list = [...r.transactions]..sort((a, b) => a.date.compareTo(b.date));
  return [
    _heading('Movimientos del mes (${list.length})'),
    if (list.isEmpty)
      _note('No hay movimientos en este mes.')
    else
      _table(
        ['Fecha', 'Categoría', 'Detalle', 'Tipo', 'Monto'],
        [
          for (final t in list)
            [
              fullDate(t.date),
              t.category,
              t.note.isEmpty ? '-' : t.note,
              t.kind == TxKind.expense ? 'Gasto' : 'Ingreso',
              '${t.kind == TxKind.expense ? '-' : '+'} ${money(t.amountCents)}',
            ],
        ],
        align: const {4: pw.Alignment.centerRight},
      ),
  ];
}
