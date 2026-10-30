import 'package:flutter/material.dart';

import '../../core/theme.dart';

class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

const _styles = <String, CategoryStyle>{
  'Alimentación': CategoryStyle(Icons.shopping_basket, Brand.teal),
  'Hogar': CategoryStyle(Icons.home, Brand.orange),
  'Transporte': CategoryStyle(Icons.directions_car, Color(0xFF2B5282)),
  'Salud': CategoryStyle(Icons.medical_services, Color(0xFF19A974)),
  'Entretenimiento': CategoryStyle(Icons.movie, Color(0xFFE5484D)),
  'Educación': CategoryStyle(Icons.school, Color(0xFF6C63D9)),
  'Otros': CategoryStyle(Icons.more_horiz, Color(0xFF9AA5B5)),
  'Nómina': CategoryStyle(Icons.account_balance, Brand.income),
  'Negocio': CategoryStyle(Icons.storefront, Color(0xFF00897B)),
  'Otros ingresos': CategoryStyle(Icons.savings, Color(0xFF66BB6A)),
};

const _fallback = CategoryStyle(Icons.category, Color(0xFF9AA5B5));

CategoryStyle styleFor(String category) => _styles[category] ?? _fallback;
