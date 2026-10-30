import 'package:flutter/material.dart';

import 'format.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

TextFormField moneyField(
  TextEditingController controller, {
  String label = 'Monto',
  bool required = true,
  bool autofocus = false,
}) {
  return TextFormField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      prefixText: r'$ ',
      border: const OutlineInputBorder(),
    ),
    validator: (v) {
      final text = (v ?? '').trim();
      if (text.isEmpty) return required ? 'Ingresa un monto mayor a 0' : null;
      return parseAmountToCents(text) == null ? 'Ingresa un monto mayor a 0' : null;
    },
  );
}

/// Convierte el texto de un campo opcional a centavos (vacío = 0).
int centsOrZero(String text) =>
    text.trim().isEmpty ? 0 : (parseAmountToCents(text) ?? 0);

/// Pide un monto. Devuelve centavos, o null si se cancela.
Future<int?> showAmountDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Guardar',
  int? maxCents,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _AmountDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      maxCents: maxCents,
    ),
  );
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.confirmLabel,
    this.message,
    this.maxCents,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final int? maxCents;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final cents = parseAmountToCents(_amount.text)!;
    final max = widget.maxCents;
    if (max != null && cents > max) {
      _amount.text = (max / 100).toStringAsFixed(2);
    }
    Navigator.pop(context, max != null && cents > max ? max : cents);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: 16),
            ],
            moneyField(_amount, autofocus: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
