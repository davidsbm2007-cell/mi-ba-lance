import 'package:flutter/material.dart';

import '../../core/dialogs.dart';
import '../../core/format.dart';
import '../transactions/category_style.dart';
import '../transactions/transaction.dart';
import 'budget.dart';

/// Crea o edita un presupuesto. Devuelve el [Budget] o null si se cancela.
class BudgetDialog extends StatefulWidget {
  const BudgetDialog({super.key, required this.takenCategories, this.existing});

  final Set<String> takenCategories;
  final Budget? existing;

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  final _form = GlobalKey<FormState>();
  late final List<String> _available = widget.existing != null
      ? [widget.existing!.category]
      : expenseCategories
          .where((c) => !widget.takenCategories.contains(c))
          .toList();
  late String _category = _available.first;
  late final _limit = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.limitCents / 100).toStringAsFixed(2),
  );

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, Budget(_category, parseAmountToCents(_limit.text)!));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? 'Editar presupuesto' : 'Nuevo presupuesto'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in _available)
                    DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(styleFor(c).icon, size: 20, color: styleFor(c).color),
                          const SizedBox(width: 10),
                          Text(c),
                        ],
                      ),
                    ),
                ],
                onChanged: editing ? null : (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              moneyField(_limit, label: 'Límite mensual', autofocus: true),
            ],
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
