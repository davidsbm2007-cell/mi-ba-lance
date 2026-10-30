import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/app_state.dart';
import '../../core/session.dart';
import '../../core/format.dart';
import '../../core/widgets.dart';
import '../budgets/budget.dart';
import '../dashboard/analytics.dart';
import '../dashboard/dashboard_cards.dart';
import '../debts/debt.dart';
import '../goals/goal.dart';
import '../shell/page_body.dart';
import '../transactions/summary.dart';
import '../transactions/transactions_provider.dart';
import 'report_pdf.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(transactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final data = DashboardData.from(all, month);

    return PageBody(
      title: 'Reportes',
      subtitle: 'Entiende en qué se va tu dinero',
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 860;
          final lineChart = IncomeExpenseCard(months: data.months, fill: wide);
          final donut = CategoryDonutCard(byCategory: data.byCategory);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PdfCard(),
              const SizedBox(height: 16),
              if (wide)
                SizedBox(
                  height: 392,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: lineChart),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: donut),
                    ],
                  ),
                )
              else ...[
                lineChart,
                const SizedBox(height: 16),
                donut,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PdfCard extends ConsumerStatefulWidget {
  const _PdfCard();

  @override
  ConsumerState<_PdfCard> createState() => _PdfCardState();
}

class _PdfCardState extends ConsumerState<_PdfCard> {
  bool _busy = false;

  ReportInput _input() {
    final month = ref.read(selectedMonthProvider);
    final all = ref.read(transactionsProvider);
    return ReportInput(
      month: month,
      userName: ref.read(sessionProvider).displayName,
      generatedAt: DateTime.now(),
      data: DashboardData.from(all, month),
      transactions: inMonth(all, month),
      budgets: ref.read(budgetsProvider),
      goals: ref.read(goalsProvider),
      debts: ref.read(debtsProvider),
    );
  }

  String _filename(DateTime month) =>
      'reporte-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';

  Future<void> _run(Future<void> Function(Uint8List bytes, String name) action) async {
    setState(() => _busy = true);
    try {
      final input = _input();
      final bytes = await buildReportPdf(input);
      await action(bytes, _filename(input.month));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el PDF. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reporte en PDF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen de ${monthLabel(month)} con categorías, presupuestos, deudas, metas y todos tus movimientos del mes.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          (bytes, name) => Printing.sharePdf(bytes: bytes, filename: name),
                        ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(_busy ? 'Generando...' : 'Descargar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          (bytes, name) => Printing.layoutPdf(
                            name: name,
                            onLayout: (_) async => bytes,
                          ),
                        ),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Imprimir / vista previa'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
