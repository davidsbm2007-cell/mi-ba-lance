import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// owedToMe: alguien me debe a mí. iOwe: yo le debo a alguien.
enum DebtKind { owedToMe, iOwe }

class Debt {
  const Debt({
    required this.id,
    required this.kind,
    required this.person,
    required this.totalCents,
    required this.createdAt,
    this.concept = '',
    this.paidCents = 0,
    this.dueDate,
  });

  final String id;
  final DebtKind kind;
  final String person;
  final String concept;
  final int totalCents;
  final int paidCents;
  final DateTime? dueDate;
  final DateTime createdAt;

  int get pendingCents => (totalCents - paidCents).clamp(0, totalCents);
  bool get isPaid => paidCents >= totalCents;
  double get progress =>
      totalCents == 0 ? 0 : (paidCents / totalCents).clamp(0.0, 1.0);

  bool isOverdue(DateTime now) {
    final due = dueDate;
    if (due == null || isPaid) return false;
    return DateTime(due.year, due.month, due.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  Debt copyWith({
    DebtKind? kind,
    String? person,
    String? concept,
    int? totalCents,
    int? paidCents,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) =>
      Debt(
        id: id,
        kind: kind ?? this.kind,
        person: person ?? this.person,
        concept: concept ?? this.concept,
        totalCents: totalCents ?? this.totalCents,
        paidCents: paidCents ?? this.paidCents,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'person': person,
        'concept': concept,
        'totalCents': totalCents,
        'paidCents': paidCents,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as String,
        kind: DebtKind.values.byName(json['kind'] as String),
        person: json['person'] as String,
        concept: (json['concept'] as String?) ?? '',
        totalCents: json['totalCents'] as int,
        paidCents: (json['paidCents'] as int?) ?? 0,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Total pendiente de un tipo de deuda.
int pendingTotal(List<Debt> debts, DebtKind kind) => debts
    .where((d) => d.kind == kind)
    .fold(0, (sum, d) => sum + d.pendingCents);

class DebtsNotifier extends Notifier<List<Debt>> {
  @override
  List<Debt> build() => ref.watch(snapshotProvider).debts;

  Future<void> upsert(Debt debt) async {
    state = state.any((d) => d.id == debt.id)
        ? [for (final d in state) d.id == debt.id ? debt : d]
        : [...state, debt];
    await ref.read(repositoryProvider).upsertDebt(debt);
  }

  Future<void> _change(String id, Debt Function(Debt) change) async {
    final updated = [for (final d in state) d.id == id ? change(d) : d];
    state = updated;
    await ref.read(repositoryProvider).upsertDebt(updated.firstWhere((d) => d.id == id));
  }

  /// Registra un abono sin pasarse del total.
  Future<void> addPayment(String id, int cents) => _change(
        id,
        (d) => d.copyWith(paidCents: (d.paidCents + cents).clamp(0, d.totalCents)),
      );

  Future<void> markPaid(String id) =>
      _change(id, (d) => d.copyWith(paidCents: d.totalCents));

  Future<void> remove(String id) async {
    state = [for (final d in state) if (d.id != id) d];
    await ref.read(repositoryProvider).deleteDebt(id);
  }

  Future<void> replaceAll(List<Debt> list) async {
    state = list;
    await ref.read(repositoryProvider).replaceDebts(list);
  }

  Future<void> clear() => replaceAll(const []);
}

final debtsProvider =
    NotifierProvider<DebtsNotifier, List<Debt>>(DebtsNotifier.new);
