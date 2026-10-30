import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shell/page_body.dart';
import 'debt.dart';
import 'debt_dialog.dart';

/// Pendientes primero (por fecha de pago), pagadas al final.
List<Debt> sortedDebts(List<Debt> debts, DebtKind kind) {
  final list = debts.where((d) => d.kind == kind).toList();
  list.sort((a, b) {
    if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });
  return list;
}

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    Debt? existing,
    DebtKind kind = DebtKind.owedToMe,
  }) async {
    final debt = await showDialog<Debt>(
      context: context,
      builder: (_) => DebtDialog(existing: existing, initialKind: kind),
    );
    if (debt != null) await ref.read(debtsProvider.notifier).upsert(debt);
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, Debt d) async {
    final collecting = d.kind == DebtKind.owedToMe;
    final cents = await showAmountDialog(
      context,
      title: collecting ? 'Registrar cobro de ${d.person}' : 'Registrar pago a ${d.person}',
      message: 'Pendiente: ${money(d.pendingCents)}',
      confirmLabel: 'Registrar',
      maxCents: d.pendingCents,
    );
    if (cents != null) await ref.read(debtsProvider.notifier).addPayment(d.id, cents);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Debt d) async {
    final ok = await confirmDialog(
      context,
      title: '¿Eliminar deuda?',
      message: 'Se eliminará el registro de ${d.person}.',
    );
    if (ok) await ref.read(debtsProvider.notifier).remove(d.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsProvider);
    final owedToMe = pendingTotal(debts, DebtKind.owedToMe);
    final iOwe = pendingTotal(debts, DebtKind.iOwe);

    Widget section(DebtKind kind) => _DebtSection(
          kind: kind,
          debts: sortedDebts(debts, kind),
          onAdd: () => _save(context, ref, kind: kind),
          onPay: (d) => _pay(context, ref, d),
          onMarkPaid: (d) => ref.read(debtsProvider.notifier).markPaid(d.id),
          onEdit: (d) => _save(context, ref, existing: d),
          onDelete: (d) => _delete(context, ref, d),
        );

    return PageBody(
      title: 'Deudas',
      subtitle: 'Quién te debe y a quién le debes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              final line = Theme.of(context).colorScheme.outlineVariant;
              final net = owedToMe - iOwe;
              final cells = [
                _SummaryTile(
                  label: 'Me deben',
                  cents: owedToMe,
                  detail: _count(debts, DebtKind.owedToMe),
                ),
                _SummaryTile(
                  label: 'Debo',
                  cents: iOwe,
                  detail: _count(debts, DebtKind.iOwe),
                ),
                _SummaryTile(
                  label: 'Balance neto',
                  cents: net,
                  detail: net >= 0 ? 'A tu favor' : 'En contra',
                  detailColor: net >= 0
                      ? (dark ? Brand.income : Brand.incomeText)
                      : (dark ? const Color(0xFFFF8A65) : Brand.expenseText),
                ),
              ];
              return AppCard(
                padding: EdgeInsets.zero,
                child: c.maxWidth >= 560
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < cells.length; i++) ...[
                              Expanded(child: cells[i]),
                              if (i < cells.length - 1)
                                VerticalDivider(color: line, width: 1),
                            ],
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cells.length; i++) ...[
                            cells[i],
                            if (i < cells.length - 1) Divider(color: line),
                          ],
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: section(DebtKind.owedToMe)),
                    const SizedBox(width: 16),
                    Expanded(child: section(DebtKind.iOwe)),
                  ],
                );
              }
              return Column(
                children: [
                  section(DebtKind.owedToMe),
                  const SizedBox(height: 24),
                  section(DebtKind.iOwe),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _count(List<Debt> debts, DebtKind kind) {
    final n = debts.where((d) => d.kind == kind && !d.isPaid).length;
    return n == 1 ? '1 pendiente' : '$n pendientes';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.cents,
    required this.detail,
    this.detailColor,
  });

  final String label;
  final int cents;
  final String detail;
  final Color? detailColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: muted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(
              cents,
              cacheKey: 'debts.summary.$label',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: kTabular,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: detailColor == null ? FontWeight.w400 : FontWeight.w700,
              color: detailColor ?? muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtSection extends StatelessWidget {
  const _DebtSection({
    required this.kind,
    required this.debts,
    required this.onAdd,
    required this.onPay,
    required this.onMarkPaid,
    required this.onEdit,
    required this.onDelete,
  });

  final DebtKind kind;
  final List<Debt> debts;
  final VoidCallback onAdd;
  final void Function(Debt) onPay;
  final void Function(Debt) onMarkPaid;
  final void Function(Debt) onEdit;
  final void Function(Debt) onDelete;

  @override
  Widget build(BuildContext context) {
    final owedToMe = kind == DebtKind.owedToMe;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                owedToMe ? 'Me deben' : 'Debo',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (debts.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Center(
              child: Text(
                owedToMe ? 'Nadie te debe por ahora' : 'No le debes a nadie por ahora',
                style: TextStyle(color: muted),
              ),
            ),
          )
        else
          for (final d in debts) ...[
            _DebtTile(
              debt: d,
              onPay: () => onPay(d),
              onMarkPaid: () => onMarkPaid(d),
              onEdit: () => onEdit(d),
              onDelete: () => onDelete(d),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.onPay,
    required this.onMarkPaid,
    required this.onEdit,
    required this.onDelete,
  });

  final Debt debt;
  final VoidCallback onPay;
  final VoidCallback onMarkPaid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final owedToMe = debt.kind == DebtKind.owedToMe;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final overdueColor = dark ? const Color(0xFFFF8A65) : Brand.expenseText;
    final doneColor = dark ? Brand.income : Brand.incomeText;
    final overdue = debt.isOverdue(DateTime.now());
    final due = debt.dueDate;

    final String dueLabel;
    if (debt.isPaid) {
      dueLabel = 'Pagada';
    } else if (due == null) {
      dueLabel = 'Sin fecha de pago';
    } else {
      dueLabel = '${overdue ? 'Venció' : 'Vence'} ${fullDate(due)}';
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? const Color(0xFF1E3550) : const Color(0xFFEDF1F5),
                ),
                child: Text(
                  debt.person.isEmpty ? '?' : debt.person[0].toUpperCase(),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.person,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (debt.concept.isNotEmpty)
                      Text(
                        debt.concept,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(debt.pendingCents),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      fontFeatures: kTabular,
                      color: debt.isPaid ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  Text(
                    'de ${money(debt.totalCents)}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppProgress(
              cacheKey: 'debt.${debt.id}',
              value: debt.progress,
              color: debt.isPaid ? Brand.income : Brand.teal,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                debt.isPaid ? Icons.check_circle : Icons.event,
                size: 16,
                color: debt.isPaid
                    ? doneColor
                    : (overdue ? overdueColor : scheme.onSurfaceVariant),
              ),
              Text(
                dueLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                  color: overdue ? overdueColor : scheme.onSurfaceVariant,
                ),
              ),
              if (!debt.isPaid) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onPay,
                  child: Text(owedToMe ? 'Cobrar' : 'Pagar'),
                ),
                TextButton(
                  onPressed: onMarkPaid,
                  style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                  child: const Text('Marcar pagada'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
