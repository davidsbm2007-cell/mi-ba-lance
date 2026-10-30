import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'transaction.dart';

class TransactionsNotifier extends Notifier<List<Tx>> {
  @override
  List<Tx> build() => _sorted(ref.watch(snapshotProvider).transactions);

  Future<void> add(Tx tx) async {
    state = _sorted([...state, tx]);
    await ref.read(repositoryProvider).upsertTx(tx);
  }

  Future<void> replaceAll(List<Tx> all) async {
    state = _sorted(all);
    await ref.read(repositoryProvider).replaceTxs(all);
  }

  Future<void> clear() => replaceAll(const []);

  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await ref.read(repositoryProvider).deleteTx(id);
  }

  List<Tx> _sorted(List<Tx> list) =>
      [...list]..sort((a, b) => b.date.compareTo(a.date));
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Tx>>(TransactionsNotifier.new);
