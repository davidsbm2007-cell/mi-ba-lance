import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kName = 'session_name_v1';
const _kEmail = 'session_email_v1';
const _kOnboarding = 'onboarding_seen_v1';

/// Sesión de prueba de la beta: no hay cuenta real. Se acepta cualquier
/// nombre o correo y solo se guarda en este dispositivo. La contraseña nunca
/// se guarda.
class AppSession {
  const AppSession({this.name, this.email, this.onboardingSeen = false});

  final String? name;
  final String? email;
  final bool onboardingSeen;

  bool get signedIn => name != null && name!.trim().isNotEmpty;

  /// Nombre para el saludo; "amigo" mientras no haya sesión.
  String get displayName => signedIn ? name!.trim() : 'amigo';

  /// Primera letra para el avatar.
  String get initial => displayName.substring(0, 1).toUpperCase();

  AppSession copyWith({String? name, String? email, bool? onboardingSeen}) =>
      AppSession(
        name: name ?? this.name,
        email: email ?? this.email,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      );
}

/// Nombre a mostrar a partir de lo que escribió la persona. Si no hay nombre,
/// se usa la parte del correo antes de la @.
String nameFromInput({String? name, String? email}) {
  final n = (name ?? '').trim();
  if (n.isNotEmpty) return _capitalize(n);
  final local = (email ?? '').trim().split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
  if (local.isNotEmpty) return _capitalize(local);
  return 'Usuario';
}

String _capitalize(String s) =>
    s.split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

Future<AppSession> loadSavedSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return AppSession(
      name: prefs.getString(_kName),
      email: prefs.getString(_kEmail),
      onboardingSeen: prefs.getBool(_kOnboarding) ?? false,
    );
  } catch (_) {
    return const AppSession();
  }
}

/// Lo leído al abrir la app; se inicializa en `main()`.
final initialSessionProvider = Provider<AppSession>((ref) => const AppSession());

class SessionNotifier extends Notifier<AppSession> {
  @override
  AppSession build() => ref.watch(initialSessionProvider);

  Future<void> _save(void Function(SharedPreferences p) write) async {
    try {
      write(await SharedPreferences.getInstance());
    } catch (_) {
      // Sin almacenamiento: la sesión vale solo para esta ejecución.
    }
  }

  Future<void> finishOnboarding() async {
    state = state.copyWith(onboardingSeen: true);
    await _save((p) => p.setBool(_kOnboarding, true));
  }

  /// Registro o ingreso de prueba: acepta cualquier valor.
  Future<void> signIn({String? name, String? email}) async {
    final shown = nameFromInput(name: name, email: email);
    final mail = (email ?? '').trim();
    state = AppSession(
      name: shown,
      email: mail.isEmpty ? null : mail,
      onboardingSeen: true,
    );
    await _save((p) {
      p.setString(_kName, shown);
      mail.isEmpty ? p.remove(_kEmail) : p.setString(_kEmail, mail);
      p.setBool(_kOnboarding, true);
    });
  }

  /// Cierra la sesión; los datos financieros se conservan en el dispositivo.
  Future<void> signOut() async {
    state = AppSession(onboardingSeen: state.onboardingSeen);
    await _save((p) {
      p.remove(_kName);
      p.remove(_kEmail);
    });
  }

  /// Vuelve a mostrar la guía de bienvenida.
  Future<void> replayOnboarding() async {
    state = AppSession(name: state.name, email: state.email);
    await _save((p) => p.remove(_kOnboarding));
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, AppSession>(SessionNotifier.new);
