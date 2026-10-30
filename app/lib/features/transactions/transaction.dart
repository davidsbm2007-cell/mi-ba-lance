enum TxKind { expense, income }

const expenseCategories = [
  'Alimentación',
  'Hogar',
  'Transporte',
  'Salud',
  'Entretenimiento',
  'Educación',
  'Otros',
];

const incomeCategories = ['Nómina', 'Negocio', 'Otros ingresos'];

class Tx {
  const Tx({
    required this.id,
    required this.kind,
    required this.amountCents,
    required this.category,
    required this.date,
    this.note = '',
  });

  final String id;
  final TxKind kind;
  final int amountCents;
  final String category;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'amountCents': amountCents,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Tx.fromJson(Map<String, dynamic> json) => Tx(
        id: json['id'] as String,
        kind: TxKind.values.byName(json['kind'] as String),
        amountCents: json['amountCents'] as int,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        note: (json['note'] as String?) ?? '',
      );
}
