/// En web no hay carpeta de documentos: los datos viven en la base del navegador.
Future<String?> backupFilePath() async => null;

Future<void> writeBackupFile(String json) async {}

Future<String?> readBackupFile() async => null;
