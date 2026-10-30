import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _fileName = 'mi_balance_datos.json';

/// Ruta del archivo de datos en la carpeta de documentos de la app.
Future<String?> backupFilePath() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _fileName);
  } catch (_) {
    return null;
  }
}

Future<void> writeBackupFile(String json) async {
  final path = await backupFilePath();
  if (path == null) return;
  // Se escribe a un temporal y se renombra: un corte a mitad no daña el archivo.
  final tmp = File('$path.tmp');
  await tmp.writeAsString(json, flush: true);
  await tmp.rename(path);
}

Future<String?> readBackupFile() async {
  final path = await backupFilePath();
  if (path == null) return null;
  final f = File(path);
  return await f.exists() ? f.readAsString() : null;
}
