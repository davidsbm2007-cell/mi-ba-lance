import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';

/// Crédito: `balanceCents` es lo usado del cupo. Débito: el saldo disponible.
enum CardKind { credit, debit }

enum CardNetwork { visa, mastercard, amex, diners, other }

extension CardNetworkLabel on CardNetwork {
  String get label => switch (this) {
        CardNetwork.visa => 'Visa',
        CardNetwork.mastercard => 'Mastercard',
        CardNetwork.amex => 'American Express',
        CardNetwork.diners => 'Diners Club',
        CardNetwork.other => 'Otra',
      };
}

/// Colores planos para identificar cada tarjeta.
const cardColors = [
  Brand.navy,
  Brand.deepTeal,
  Color(0xFF334155),
  Color(0xFF5B2A4E),
  Color(0xFF1F5130),
];

class BankCard {
  const BankCard({
    required this.id,
    required this.name,
    required this.kind,
    this.network = CardNetwork.other,
    this.last4,
    this.limitCents,
    this.balanceCents = 0,
    this.cutDay,
    this.dueDay,
    this.colorIndex = 0,
  });

  final String id;
  final String name;
  final CardKind kind;
  final CardNetwork network;
  final String? last4;
  final int? limitCents;
  final int balanceCents;
  final int? cutDay;
  final int? dueDay;
  final int colorIndex;

  bool get isCredit => kind == CardKind.credit;
  Color get color => cardColors[colorIndex % cardColors.length];

  /// Lo que se debe a la tarjeta (solo crédito).
  int get usedCents => isCredit ? balanceCents : 0;

  int get availableCents {
    final limit = limitCents;
    if (!isCredit || limit == null) return 0;
    return (limit - balanceCents).clamp(0, limit);
  }

  double get usage {
    final limit = limitCents;
    if (!isCredit || limit == null || limit == 0) return 0;
    return balanceCents / limit;
  }

  /// Próxima fecha de pago a partir de [now], o null si no hay día de pago.
  DateTime? nextDue(DateTime now) {
    final day = dueDay;
    if (!isCredit || day == null) return null;
    DateTime inMonth(int y, int m) {
      final last = DateTime(y, m + 1, 0).day;
      return DateTime(y, m, day.clamp(1, last));
    }

    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = inMonth(now.year, now.month);
    return thisMonth.isBefore(today) ? inMonth(now.year, now.month + 1) : thisMonth;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'network': network.name,
        'last4': last4,
        'limitCents': limitCents,
        'balanceCents': balanceCents,
        'cutDay': cutDay,
        'dueDay': dueDay,
        'colorIndex': colorIndex,
      };

  factory BankCard.fromJson(Map<String, dynamic> json) => BankCard(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: CardKind.values.byName(json['kind'] as String),
        network: CardNetwork.values.byName((json['network'] as String?) ?? 'other'),
        last4: json['last4'] as String?,
        limitCents: json['limitCents'] as int?,
        balanceCents: (json['balanceCents'] as int?) ?? 0,
        cutDay: json['cutDay'] as int?,
        dueDay: json['dueDay'] as int?,
        colorIndex: (json['colorIndex'] as int?) ?? 0,
      );

  BankCard copyWith({
    String? name,
    CardKind? kind,
    CardNetwork? network,
    String? last4,
    int? limitCents,
    int? balanceCents,
    int? cutDay,
    int? dueDay,
    int? colorIndex,
  }) =>
      BankCard(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        network: network ?? this.network,
        last4: last4 ?? this.last4,
        limitCents: limitCents ?? this.limitCents,
        balanceCents: balanceCents ?? this.balanceCents,
        cutDay: cutDay ?? this.cutDay,
        dueDay: dueDay ?? this.dueDay,
        colorIndex: colorIndex ?? this.colorIndex,
      );
}

/// Deuda total en tarjetas de crédito.
int totalUsed(List<BankCard> cards) =>
    cards.fold(0, (sum, c) => sum + c.usedCents);

/// Cupo disponible sumado de las tarjetas de crédito.
int totalAvailable(List<BankCard> cards) =>
    cards.fold(0, (sum, c) => sum + c.availableCents);

/// La tarjeta de crédito cuyo pago es el más cercano.
BankCard? nextDueCard(List<BankCard> cards, DateTime now) {
  BankCard? best;
  DateTime? bestDate;
  for (final c in cards) {
    final d = c.nextDue(now);
    if (d == null || c.usedCents == 0) continue;
    if (bestDate == null || d.isBefore(bestDate)) {
      best = c;
      bestDate = d;
    }
  }
  return best;
}

class CardsNotifier extends Notifier<List<BankCard>> {
  @override
  List<BankCard> build() => ref.watch(snapshotProvider).cards;

  Future<void> upsert(BankCard card) async {
    state = state.any((c) => c.id == card.id)
        ? [for (final c in state) c.id == card.id ? card : c]
        : [...state, card];
    await ref.read(repositoryProvider).upsertCard(card);
  }

  Future<void> _change(String id, BankCard Function(BankCard) change) async {
    final updated = [for (final c in state) c.id == id ? change(c) : c];
    state = updated;
    await ref.read(repositoryProvider).upsertCard(updated.firstWhere((c) => c.id == id));
  }

  /// Un pago baja lo usado, sin pasar de cero.
  Future<void> pay(String id, int cents) => _change(
        id,
        (c) => c.copyWith(balanceCents: (c.balanceCents - cents).clamp(0, 1 << 40)),
      );

  /// Un consumo sube lo usado.
  Future<void> charge(String id, int cents) =>
      _change(id, (c) => c.copyWith(balanceCents: c.balanceCents + cents));

  Future<void> remove(String id) async {
    state = [for (final c in state) if (c.id != id) c];
    await ref.read(repositoryProvider).deleteCard(id);
  }

  Future<void> replaceAll(List<BankCard> list) async {
    state = list;
    await ref.read(repositoryProvider).replaceCards(list);
  }

  Future<void> clear() => replaceAll(const []);
}

final cardsProvider =
    NotifierProvider<CardsNotifier, List<BankCard>>(CardsNotifier.new);
