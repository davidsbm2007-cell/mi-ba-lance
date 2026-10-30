import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'theme_mode_v1';

ThemeMode themeModeFromName(String? name) => ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );

/// Tema guardado en el dispositivo (claro, oscuro o el del sistema).
Future<ThemeMode> loadSavedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return themeModeFromName(prefs.getString(_key));
  } catch (_) {
    return ThemeMode.system;
  }
}

/// Lo leído al abrir la app; se inicializa en `main()`.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Sin almacenamiento disponible: el cambio vale para esta sesión.
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
