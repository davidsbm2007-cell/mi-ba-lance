import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mes que muestran todas las pantallas.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void select(DateTime month) => state = DateTime(month.year, month.month);
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);
