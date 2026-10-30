import 'package:flutter/material.dart';

import '../../core/ids.dart';
import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import 'goal.dart';

/// Crea o edita una meta. Devuelve la [Goal] o null si se cancela.
class GoalDialog extends StatefulWidget {
  const GoalDialog({super.key, this.existing});

  final Goal? existing;

  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late final _target = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.targetCents / 100).toStringAsFixed(2),
  );
  late final _saved = TextEditingController(
    text: (widget.existing?.savedCents ?? 0) == 0
        ? ''
        : (widget.existing!.savedCents / 100).toStringAsFixed(2),
  );
  late String _iconKey = widget.existing?.iconKey ?? goalIcons.keys.first;
  late int _colorIndex = widget.existing?.colorIndex ?? 0;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      Goal(
        id: widget.existing?.id ?? newId(),
        name: _name.text.trim(),
        note: _note.text.trim(),
        targetCents: parseAmountToCents(_target.text)!,
        savedCents: centsOrZero(_saved.text),
        iconKey: _iconKey,
        colorIndex: _colorIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nueva meta' : 'Editar meta'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Ponle un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                moneyField(_target, label: 'Monto objetivo'),
                const SizedBox(height: 12),
                moneyField(_saved, label: 'Ya ahorrado (opcional)', required: false),
                const SizedBox(height: 16),
                Text('Ícono', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in goalIcons.entries)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _iconKey = e.key),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: e.key == _iconKey
                                ? goalColors[_colorIndex].withValues(alpha: 0.18)
                                : null,
                            border: Border.all(
                              color: e.key == _iconKey
                                  ? goalColors[_colorIndex]
                                  : scheme.outlineVariant,
                            ),
                          ),
                          child: Icon(
                            e.value,
                            color: e.key == _iconKey
                                ? goalColors[_colorIndex]
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Color', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (var i = 0; i < goalColors.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _colorIndex = i),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: goalColors[i],
                          child: i == _colorIndex
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: Brand.teal),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
