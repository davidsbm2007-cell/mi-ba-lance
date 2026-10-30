import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../core/widgets.dart';
import '../shell/page_body.dart';
import '../transactions/summary.dart';
import '../transactions/transaction.dart';
import '../transactions/transactions_provider.dart';
import '../transactions/tx_row.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  TxKind? _filter;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final items = inMonth(all, month)
        .where((t) => _filter == null || t.kind == _filter)
        .toList();

    return PageBody(
      title: 'Movimientos',
      subtitle: 'Todo lo que entra y sale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<TxKind?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Todos')),
              ButtonSegment(value: TxKind.expense, label: Text('Gastos')),
              ButtonSegment(value: TxKind.income, label: Text('Ingresos')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No hay movimientos para mostrar')),
                  )
                : LayoutBuilder(
                    builder: (context, c) => Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          TxRow(
                            tx: items[i],
                            dismissible: true,
                            showDate: c.maxWidth >= 380,
                          ),
                          if (i < items.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desliza un movimiento hacia la izquierda para borrarlo.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
