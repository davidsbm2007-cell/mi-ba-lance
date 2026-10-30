import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'category_style.dart';
import 'transaction.dart';
import 'transactions_provider.dart';

class TxRow extends ConsumerWidget {
  const TxRow({
    super.key,
    required this.tx,
    this.dismissible = false,
    this.showDate = true,
  });

  final Tx tx;
  final bool dismissible;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isExpense = tx.kind == TxKind.expense;
    final style = styleFor(tx.category);
    final title = tx.note.isEmpty ? tx.category : tx.note;
    final subtitle =
        showDate ? tx.category : '${tx.category} · ${dayLabel(tx.date)}';

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconBadge(icon: style.icon, color: style.color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (showDate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                fullDate(tx.date),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: kTabular,
                ),
              ),
            ),
          // El signo lleva el significado; solo el ingreso lleva color.
          Text(
            '${isExpense ? '-' : '+'} ${money(tx.amountCents)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFeatures: kTabular,
              color: isExpense
                  ? scheme.onSurface
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Brand.income
                      : Brand.incomeText),
            ),
          ),
        ],
      ),
    );

    if (!dismissible) return row;
    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Brand.expense,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(transactionsProvider.notifier).remove(tx.id),
      child: row,
    );
  }
}
