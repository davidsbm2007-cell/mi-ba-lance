import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'database.dart';
import 'local_repository.dart';

/// Se inicializan en `main()` (o en los tests) con [dataOverrides].
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Se inicializa con dataOverrides()'),
);

final snapshotProvider = Provider<LocalSnapshot>(
  (ref) => throw UnimplementedError('Se inicializa con dataOverrides()'),
);

final repositoryProvider = Provider<LocalRepository>(
  (ref) => LocalRepository(ref.watch(databaseProvider)),
);

/// Carga lo guardado y devuelve los overrides que necesita el `ProviderScope`.
Future<List<Override>> dataOverrides(AppDatabase db) async {
  final snapshot = await LocalRepository(db).loadAll();
  return [
    databaseProvider.overrideWithValue(db),
    snapshotProvider.overrideWithValue(snapshot),
  ];
}
