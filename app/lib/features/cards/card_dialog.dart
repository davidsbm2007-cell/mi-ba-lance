import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../../core/ids.dart';
import 'bank_card.dart';

/// Crea o edita una tarjeta. Devuelve la [BankCard] o null si se cancela.
class CardDialog extends StatefulWidget {
  const CardDialog({super.key, this.existing});

  final BankCard? existing;

  @override
  State<CardDialog> createState() => _CardDialogState();
}

String _centsText(int? cents) =>
    cents == null || cents == 0 ? '' : (cents / 100).toStringAsFixed(2);

class _CardDialogState extends State<CardDialog> {
  final _form = GlobalKey<FormState>();
  late CardKind _kind = widget.existing?.kind ?? CardKind.credit;
  late CardNetwork _network = widget.existing?.network ?? CardNetwork.visa;
  late int _color = widget.existing?.colorIndex ?? 0;
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _last4 = TextEditingController(text: widget.existing?.last4 ?? '');
  late final _limit = TextEditingController(text: _centsText(widget.existing?.limitCents));
  late final _balance = TextEditingController(text: _centsText(widget.existing?.balanceCents));
  late final _cut = TextEditingController(text: '${widget.existing?.cutDay ?? ''}');
  late final _due = TextEditingController(text: '${widget.existing?.dueDay ?? ''}');

  @override
  void dispose() {
    for (final c in [_name, _last4, _limit, _balance, _cut, _due]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _dayValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return n == null || n < 1 || n > 31 ? 'Entre 1 y 31' : null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final credit = _kind == CardKind.credit;
    final last4 = _last4.text.trim();
    Navigator.pop(
      context,
      BankCard(
        id: widget.existing?.id ?? newId(),
        name: _name.text.trim(),
        kind: _kind,
        network: _network,
        last4: last4.isEmpty ? null : last4,
        limitCents: credit ? parseAmountToCents(_limit.text) : null,
        balanceCents: centsOrZero(_balance.text),
        cutDay: credit ? int.tryParse(_cut.text.trim()) : null,
        dueDay: credit ? int.tryParse(_due.text.trim()) : null,
        colorIndex: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credit = _kind == CardKind.credit;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nueva tarjeta' : 'Editar tarjeta'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<CardKind>(
                  segments: const [
                    ButtonSegment(value: CardKind.credit, label: Text('Crédito')),
                    ButtonSegment(value: CardKind.debit, label: Text('Débito')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la tarjeta',
                    hintText: 'Visa Pichincha',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe un nombre' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<CardNetwork>(
                        initialValue: _network,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Red'),
                        items: [
                          for (final n in CardNetwork.values)
                            DropdownMenuItem(value: n, child: Text(n.label)),
                        ],
                        onChanged: (v) => setState(() => _network = v ?? _network),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _last4,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Últimos 4',
                          counterText: '',
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          return t.isEmpty || t.length == 4 ? null : 'Son 4 dígitos';
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (credit) ...[
                  moneyField(_limit, label: 'Cupo total'),
                  const SizedBox(height: 12),
                  moneyField(_balance, label: 'Usado hasta hoy (opcional)', required: false),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cut,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Día de corte'),
                          validator: _dayValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _due,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Día de pago'),
                          validator: _dayValidator,
                        ),
                      ),
                    ],
                  ),
                ] else
                  moneyField(_balance, label: 'Saldo disponible (opcional)', required: false),
                const SizedBox(height: 16),
                Text('Color', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (var i = 0; i < cardColors.length; i++)
                      Semantics(
                        button: true,
                        selected: i == _color,
                        label: 'Color ${i + 1}',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = i),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cardColors[i],
                              shape: BoxShape.circle,
                              border: i == _color
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: i == _color
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
