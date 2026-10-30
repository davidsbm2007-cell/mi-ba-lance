import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

/// Abre SQLite en el dispositivo: archivo nativo en Android, iOS y escritorio;
/// en web usa sqlite3.wasm con OPFS/IndexedDB (ver `web/`).
QueryExecutor openAppConnection() => driftDatabase(
      name: 'finanzas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.base.resolve('sqlite3.wasm'),
        driftWorker: Uri.base.resolve('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Base web: ${result.chosenImplementation} '
              '(faltan: ${result.missingFeatures})',
            );
          }
        },
      ),
    );
