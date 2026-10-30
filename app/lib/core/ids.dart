import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// UUID v4 para registros nuevos. Igual que en Supabase, así no hay que
/// traducir ids al sincronizar.
String newId() => _uuid.v4();

/// UUID estable derivado de un texto (para datos de ejemplo repetibles).
String stableId(String seed) => _uuid.v5(Namespace.url.value, seed);

/// Usuario único mientras no exista inicio de sesión. Al iniciar sesión con
/// Supabase se reemplaza por `auth.uid()`.
const kLocalUserId = '00000000-0000-0000-0000-000000000001';
