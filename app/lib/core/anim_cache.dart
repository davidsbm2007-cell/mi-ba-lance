/// Recuerda lo último que mostró cada animación para no repetirla cada vez que
/// se vuelve a una pantalla: una cifra o barra ya vista aparece en su valor
/// final y solo se anima cuando el dato cambia (parte desde el valor anterior).
/// Vive mientras la app esté abierta; al abrirla de nuevo todo vuelve a animarse.
class AnimCache {
  AnimCache._();

  static final Map<String, double> _values = {};

  static double? valueOf(String? key) => key == null ? null : _values[key];

  static void remember(String? key, double value) {
    if (key != null) _values[key] = value;
  }

  static void clear() => _values.clear();
}
