import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../core/format.dart';
import 'category_style.dart';
import 'transaction.dart';
import 'transactions_provider.dart';

class AddArgs {
  const AddArgs(this.kind, this.category);

  final TxKind kind;
  final String category;
}

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialKind = TxKind.expense,
    this.initialCategory,
  });

  final TxKind initialKind;
  final String? initialCategory;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late TxKind _kind = widget.initialKind;
  late String _category = widget.initialCategory ?? _categories.first;
  DateTime _date = DateTime.now();

  List<String> get _categories =>
      _kind == TxKind.expense ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final cents = parseAmountToCents(_amount.text)!;
    await ref.read(transactionsProvider.notifier).add(
          Tx(
            id: newId(),
            kind: _kind,
            amountCents: cents,
            category: _category,
            date: _date,
            note: _note.text.trim(),
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TxKind>(
              segments: const [
                ButtonSegment(value: TxKind.expense, label: Text('Gasto')),
                ButtonSegment(value: TxKind.income, label: Text('Ingreso')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _category = _categories.first;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) => parseAmountToCents(v ?? '') == null
                  ? 'Ingresa un monto mayor a 0'
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Categoría', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _categories)
                  ChoiceChip(
                    avatar: Icon(styleFor(c).icon, size: 18, color: styleFor(c).color),
                    label: Text(c),
                    showCheckmark: false,
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('${dayLabel(_date)} ${_date.year}'),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Cambiar'),
              ),
            ),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
