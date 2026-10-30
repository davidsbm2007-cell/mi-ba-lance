import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../dashboard/dashboard_cards.dart' show budgetStatusColor, budgetStatusText;
import '../shell/page_body.dart';
import 'bank_card.dart';
import 'card_dialog.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref, {BankCard? existing}) async {
    final result = await showDialog<BankCard>(
      context: context,
      builder: (_) => CardDialog(existing: existing),
    );
    if (result != null) await ref.read(cardsProvider.notifier).upsert(result);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, BankCard c) async {
    final ok = await confirmDialog(
      context,
      title: '¿Eliminar tarjeta?',
      message: 'Se quitará ${c.name} de tu lista. Tus movimientos no se borran.',
    );
    if (ok) await ref.read(cardsProvider.notifier).remove(c.id);
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, BankCard c) async {
    final cents = await showAmountDialog(
      context,
      title: 'Registrar pago',
      message: 'Debes ${money(c.usedCents)} en ${c.name}.',
      confirmLabel: 'Registrar',
      maxCents: c.usedCents,
    );
    if (cents != null) await ref.read(cardsProvider.notifier).pay(c.id, cents);
  }

  Future<void> _charge(BuildContext context, WidgetRef ref, BankCard c) async {
    final cents = await showAmountDialog(
      context,
      title: 'Agregar consumo',
      message: 'Se suma a lo usado de ${c.name}.',
      confirmLabel: 'Agregar',
    );
    if (cents != null) await ref.read(cardsProvider.notifier).charge(c.id, cents);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);
    final now = DateTime.now();
    final next = nextDueCard(cards, now);
    final nextDate = next?.nextDue(now);
    final used = totalUsed(cards);

    final String subtitle;
    if (cards.isEmpty) {
      subtitle = 'Registra tus tarjetas y controla cuánto usas.';
    } else if (next != null && nextDate != null) {
      subtitle =
          'Debes ${money(used)} en tarjetas. Pagas ${next.name} el ${dayLabel(nextDate)}.';
    } else if (used > 0) {
      subtitle = 'Debes ${money(used)} en tarjetas.';
    } else {
      subtitle = 'No tienes saldo pendiente en tus tarjetas.';
    }

    return PageBody(
      title: 'Tarjetas',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cards.isNotEmpty) ...[
            _Summary(cards: cards, next: next, nextDate: nextDate),
            const SizedBox(height: 16),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _save(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva tarjeta'),
            ),
          ),
          const SizedBox(height: 16),
          if (cards.isEmpty)
            const AppCard(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconBadge(icon: Icons.credit_card, color: Brand.teal, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'Aún no tienes tarjetas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Agrega una tarjeta de crédito o débito para ver tu cupo y tus fechas de pago.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
                final width = (c.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: width,
                        child: _CardTile(
                          card: card,
                          onPay: () => _pay(context, ref, card),
                          onCharge: () => _charge(context, ref, card),
                          onEdit: () => _save(context, ref, existing: card),
                          onDelete: () => _delete(context, ref, card),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Deuda, cupo disponible y próximo pago, en una sola superficie.
class _Summary extends StatelessWidget {
  const _Summary({required this.cards, required this.next, required this.nextDate});

  final List<BankCard> cards;
  final BankCard? next;
  final DateTime? nextDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outlineVariant;

    Widget cell(String label, Widget value, String detail) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
              const SizedBox(height: 6),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );

    const big = TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      fontFeatures: kTabular,
    );
    final credit = cards.where((c) => c.isCredit).length;
    final cells = [
      cell('Deuda en tarjetas', AnimatedMoney(totalUsed(cards), cacheKey: 'cards.used', style: big),
          credit == 1 ? '1 tarjeta de crédito' : '$credit tarjetas de crédito'),
      cell('Cupo disponible', AnimatedMoney(totalAvailable(cards), cacheKey: 'cards.avail', style: big),
          'Para seguir usando'),
      cell(
        'Próximo pago',
        Text(nextDate == null ? '—' : dayLabel(nextDate!), style: big),
        next == null ? 'Sin pagos pendientes' : '${next!.name} · ${money(next!.usedCents)}',
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 640
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      Expanded(child: cells[i]),
                      if (i < cells.length - 1) VerticalDivider(color: line, width: 1),
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
      ),
    );
  }
}

String _dueText(DateTime due, DateTime now) {
  final days = due.difference(DateTime(now.year, now.month, now.day)).inDays;
  final when = days == 0 ? 'hoy' : (days == 1 ? 'mañana' : 'en $days días');
  return 'Pago el ${dayLabel(due)} · $when';
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.onPay,
    required this.onCharge,
    required this.onEdit,
    required this.onDelete,
  });

  final BankCard card;
  final VoidCallback onPay;
  final VoidCallback onCharge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final now = DateTime.now();
    final due = card.nextDue(now);
    final ratio = card.usage;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardFace(card: card),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: card.isCredit
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedMoney(
                            card.usedCents,
                            cacheKey: 'card.used.${card.id}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontFeatures: kTabular,
                            ),
                          ),
                          Text(
                            '  de ${money(card.limitCents ?? 0)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: muted,
                              fontFeatures: kTabular,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(ratio * 100).round()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: budgetStatusText(context, ratio),
                              fontFeatures: kTabular,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppProgress(
                        cacheKey: 'card.usage.${card.id}',
                        value: ratio,
                        color: budgetStatusColor(ratio),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Disponible ${money(card.availableCents)}',
                        style: TextStyle(fontSize: 13, color: muted, fontFeatures: kTabular),
                      ),
                      if (due != null || card.cutDay != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          [
                            if (due != null && card.usedCents > 0) _dueText(due, now),
                            if (card.cutDay != null) 'Corte el día ${card.cutDay}',
                          ].join(' · '),
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedMoney(
                        card.balanceCents,
                        cacheKey: 'card.balance.${card.id}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFeatures: kTabular,
                        ),
                      ),
                      Text('  de saldo', style: TextStyle(fontSize: 13, color: muted)),
                    ],
                  ),
          ),
          Row(
            children: [
              if (card.isCredit) ...[
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: card.usedCents == 0 ? null : onPay,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('Registrar pago'),
                ),
                const SizedBox(width: 4),
                TextButton(onPressed: onCharge, child: const Text('Consumo')),
              ],
              const Spacer(),
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
        ],
      ),
    );
  }
}

/// La tarjeta como objeto: color plano, nombre, red y últimos dígitos.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.card});

  final BankCard card;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.75,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: card.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  card.network == CardNetwork.other ? '' : card.network.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '••••  ${card.last4 ?? '••••'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontFeatures: kTabular,
                    ),
                  ),
                ),
                Text(
                  card.isCredit ? 'Crédito' : 'Débito',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
