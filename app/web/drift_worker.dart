import 'package:drift/wasm.dart';

// Worker que comparte la base SQLite entre pestañas. Se compila a
// drift_worker.js (ver README del proyecto).
void main() => WasmDatabase.workerMainForOpen();
