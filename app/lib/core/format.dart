import 'package:intl/intl.dart';

final _amount = NumberFormat('#,##0.00', 'es');
final _whole = NumberFormat('#,##0', 'es');

/// 845075 -> "$8.450,75"
String money(int cents) =>
    '${cents < 0 ? '-' : ''}\$${_amount.format(cents.abs() / 100)}';

String axisMoney(double dollars) => _whole.format(dollars);

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String monthLabel(DateTime d) => _capitalize(DateFormat('MMMM y', 'es').format(d));

String monthShort(DateTime d) =>
    _capitalize(DateFormat.MMM('es').format(d).replaceAll('.', ''));

String dayLabel(DateTime d) => DateFormat.MMMd('es').format(d).replaceAll('.', '');

String fullDate(DateTime d) =>
    DateFormat('d MMM y', 'es').format(d).replaceAll('.', '');

/// 6.2 -> "6,2"
String percentLabel(double v, {int digits = 0}) =>
    v.abs().toStringAsFixed(digits).replaceAll('.', ',');

/// Convierte "12,50" o "12.5" a centavos. Devuelve null si no es válido o <= 0.
int? parseAmountToCents(String input) {
  final v = double.tryParse(input.trim().replaceAll(',', '.'));
  if (v == null || v <= 0) return null;
  return (v * 100).round();
}
