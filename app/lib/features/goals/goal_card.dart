import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    this.showHeader = false,
    this.showButton = false,
    this.onContribute,
    this.onEdit,
    this.onDelete,
  });

  final Goal goal;

  /// Título "Meta de ahorro" con enlace a todas las metas (dashboard).
  final bool showHeader;

  /// Botón "Ver detalles" que lleva a la pestaña Metas (dashboard).
  final bool showButton;

  /// Si se pasan, se muestran los botones Abonar / Editar / Eliminar.
  final VoidCallback? onContribute;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (goal.progress * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            CardHeader(
              'Meta de ahorro',
              trailing: TextButton(
                onPressed: () => context.go('/metas'),
                child: const Text('Ver todas'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: goal.icon, color: goal.color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      goal.note.isEmpty ? ' ' : goal.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: kTabular,
                  color: goal.isComplete
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? Brand.income
                          : Brand.incomeText)
                      : null,
                ),
              ),
            ],
          ),
          if (goal.isComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Meta cumplida',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Brand.income
                    : Brand.incomeText,
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppProgress(
            cacheKey: 'goal.${goal.id}',
            value: goal.progress,
            color: goal.isComplete ? Brand.income : Brand.teal,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(money(goal.savedCents), 'Ahorrado'),
              _Stat(money(goal.targetCents), 'Meta'),
              _Stat(money(goal.remainingCents), 'Falta'),
            ],
          ),
          if (showButton) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/metas'),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver detalles'),
              ),
            ),
          ],
          if (onContribute != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: goal.isComplete ? null : onContribute,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Abonar'),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (v) => v == 'edit' ? onEdit?.call() : onDelete?.call(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta del dashboard cuando todavía no hay metas.
class EmptyGoalCard extends StatelessWidget {
  const EmptyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader('Meta de ahorro'),
          const SizedBox(height: 24),
          const Center(
            child: IconBadge(icon: Icons.track_changes, color: Brand.teal, size: 56),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Aún no tienes metas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Crea tu primera meta de ahorro.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/metas'),
              child: const Text('Crear meta'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular),
            ),
          ),
          Text(
            label,
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
