import 'package:flutter/material.dart';

import '../../core/ids.dart';
import '../../core/dialogs.dart';
import '../../core/format.dart';
import 'debt.dart';

/// Crea o edita una deuda. Devuelve la [Debt] o null si se cancela.
class DebtDialog extends StatefulWidget {
  const DebtDialog({super.key, this.existing, this.initialKind = DebtKind.owedToMe});

  final Debt? existing;
  final DebtKind initialKind;

  @override
  State<DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends State<DebtDialog> {
  final _form = GlobalKey<FormState>();
  late DebtKind _kind = widget.existing?.kind ?? widget.initialKind;
  late final _person = TextEditingController(text: widget.existing?.person ?? '');
  late final _concept = TextEditingController(text: widget.existing?.concept ?? '');
  late final _total = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.totalCents / 100).toStringAsFixed(2),
  );
  late final _paid = TextEditingController(
    text: (widget.existing?.paidCents ?? 0) == 0
        ? ''
        : (widget.existing!.paidCents / 100).toStringAsFixed(2),
  );
  late DateTime? _due = widget.existing?.dueDate;

  @override
  void dispose() {
    _person.dispose();
    _concept.dispose();
    _total.dispose();
    _paid.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) setState(() => _due = picked);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      Debt(
        id: existing?.id ?? newId(),
        kind: _kind,
        person: _person.text.trim(),
        concept: _concept.text.trim(),
        totalCents: parseAmountToCents(_total.text)!,
        paidCents: centsOrZero(_paid.text),
        dueDate: _due,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iOwe = _kind == DebtKind.iOwe;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nueva deuda' : 'Editar deuda'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<DebtKind>(
                  segments: const [
                    ButtonSegment(value: DebtKind.owedToMe, label: Text('Me deben')),
                    ButtonSegment(value: DebtKind.iOwe, label: Text('Debo')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _person,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: iOwe ? 'A quién le debo' : 'Quién me debe',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Escribe un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _concept,
                  decoration: const InputDecoration(
                    labelText: 'Concepto (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                moneyField(_total, label: 'Monto total'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paid,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ya abonado (opcional)',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return null;
                    final paid = parseAmountToCents(text);
                    if (paid == null) return 'Ingresa un monto válido';
                    final total = parseAmountToCents(_total.text);
                    if (total != null && paid > total) {
                      return 'No puede superar el total';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDue,
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(
                          _due == null ? 'Fecha de pago (opcional)' : fullDate(_due!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_due != null)
                      IconButton(
                        tooltip: 'Quitar fecha',
                        onPressed: () => setState(() => _due = null),
                        icon: const Icon(Icons.close),
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
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
