import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/session.dart';
import 'core/theme_mode.dart';
import 'data/backup/backup_service.dart';
import 'data/connection.dart';
import 'data/database.dart';
import 'data/legacy_import.dart';
import 'data/local_repository.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

  final db = AppDatabase(openAppConnection());
  await importLegacyPrefs(
    await SharedPreferences.getInstance(),
    LocalRepository(db),
  );

  // Copia de los datos en un archivo local (mi_balance_datos.json).
  final backup = AutoBackup(db);
  await backup.restoreIfEmpty();
  backup.start();

  final themeMode = await loadSavedThemeMode();
  final session = await loadSavedSession();

  runApp(
    ProviderScope(
      overrides: [
        ...await dataOverrides(db),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialSessionProvider.overrideWithValue(session),
      ],
      child: const FinanzasApp(),
    ),
  );
}
