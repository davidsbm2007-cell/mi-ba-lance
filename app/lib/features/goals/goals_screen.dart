import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shell/page_body.dart';
import 'goal.dart';
import 'goal_card.dart';
import 'goal_dialog.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref, {Goal? existing}) async {
    final goal = await showDialog<Goal>(
      context: context,
      builder: (_) => GoalDialog(existing: existing),
    );
    if (goal != null) await ref.read(goalsProvider.notifier).upsert(goal);
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref, Goal goal) async {
    final cents = await showAmountDialog(
      context,
      title: 'Abonar a "${goal.name}"',
      message: 'Te faltan ${money(goal.remainingCents)} para la meta.',
      confirmLabel: 'Abonar',
    );
    if (cents != null) await ref.read(goalsProvider.notifier).contribute(goal.id, cents);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Goal goal) async {
    final ok = await confirmDialog(
      context,
      title: '¿Eliminar meta?',
      message: 'Se eliminará "${goal.name}" y lo que llevabas ahorrado en ella.',
    );
    if (ok) await ref.read(goalsProvider.notifier).remove(goal.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final totalSaved = goals.fold<int>(0, (a, g) => a + g.savedCents);

    return PageBody(
      title: 'Metas',
      subtitle: 'Tus sueños, con plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goals.isEmpty ? '' : 'Llevas ${money(totalSaved)} ahorrados en ${goals.length} ${goals.length == 1 ? 'meta' : 'metas'}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _save(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva meta'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty)
            const AppCard(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconBadge(icon: Icons.track_changes, color: Brand.teal, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'Aún no tienes metas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crea una meta, como un viaje o un fondo de emergencia, y ve cómo avanzas.',
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
                    for (final g in goals)
                      SizedBox(
                        width: width,
                        child: GoalCard(
                          goal: g,
                          onContribute: () => _contribute(context, ref, g),
                          onEdit: () => _save(context, ref, existing: g),
                          onDelete: () => _delete(context, ref, g),
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
