import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';

const goalIcons = <String, IconData>{
  'flight': Icons.flight,
  'shield': Icons.shield,
  'laptop': Icons.laptop_mac,
  'home': Icons.home,
  'car': Icons.directions_car,
  'school': Icons.school,
  'gift': Icons.card_giftcard,
  'savings': Icons.savings,
};

const goalColors = [
  Brand.teal,
  Brand.orange,
  Color(0xFF2B5282),
  Color(0xFF6C63D9),
  Brand.income,
  Color(0xFFE5484D),
];

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetCents,
    this.note = '',
    this.savedCents = 0,
    this.iconKey = 'savings',
    this.colorIndex = 0,
  });

  final String id;
  final String name;
  final String note;
  final int targetCents;
  final int savedCents;
  final String iconKey;
  final int colorIndex;

  IconData get icon => goalIcons[iconKey] ?? Icons.flag;
  Color get color => goalColors[colorIndex % goalColors.length];
  double get progress =>
      targetCents == 0 ? 0 : (savedCents / targetCents).clamp(0.0, 1.0);
  int get remainingCents => (targetCents - savedCents).clamp(0, targetCents);
  bool get isComplete => savedCents >= targetCents;

  Goal copyWith({
    String? name,
    String? note,
    int? targetCents,
    int? savedCents,
    String? iconKey,
    int? colorIndex,
  }) =>
      Goal(
        id: id,
        name: name ?? this.name,
        note: note ?? this.note,
        targetCents: targetCents ?? this.targetCents,
        savedCents: savedCents ?? this.savedCents,
        iconKey: iconKey ?? this.iconKey,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'targetCents': targetCents,
        'savedCents': savedCents,
        'iconKey': iconKey,
        'colorIndex': colorIndex,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String,
        note: (json['note'] as String?) ?? '',
        targetCents: json['targetCents'] as int,
        savedCents: (json['savedCents'] as int?) ?? 0,
        iconKey: (json['iconKey'] as String?) ?? 'savings',
        colorIndex: (json['colorIndex'] as int?) ?? 0,
      );
}

class GoalsNotifier extends Notifier<List<Goal>> {
  @override
  List<Goal> build() => ref.watch(snapshotProvider).goals;

  Future<void> upsert(Goal goal) async {
    state = state.any((g) => g.id == goal.id)
        ? [for (final g in state) g.id == goal.id ? goal : g]
        : [...state, goal];
    await ref.read(repositoryProvider).upsertGoal(goal);
  }

  Future<void> contribute(String id, int cents) async {
    final updated = [
      for (final g in state)
        g.id == id ? g.copyWith(savedCents: g.savedCents + cents) : g,
    ];
    state = updated;
    await ref.read(repositoryProvider).upsertGoal(updated.firstWhere((g) => g.id == id));
  }

  Future<void> remove(String id) async {
    state = [for (final g in state) if (g.id != id) g];
    await ref.read(repositoryProvider).deleteGoal(id);
  }

  Future<void> replaceAll(List<Goal> list) async {
    state = list;
    await ref.read(repositoryProvider).replaceGoals(list);
  }

  Future<void> clear() => replaceAll(const []);
}

final goalsProvider =
    NotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);
