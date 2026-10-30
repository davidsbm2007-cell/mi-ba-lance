import 'dart:io';

import 'package:flutter/services.dart';

/// Carga las fuentes reales en las pruebas. La fuente por defecto (Ahem) es
/// mucho más ancha y provoca desbordes falsos: Figtree es la fuente de la app,
/// Roboto la del PDF y MaterialIcons dibuja los íconos en las capturas.
Future<void> loadTestFonts() async {
  final figtree = File('assets/fonts/Figtree.ttf');
  if (figtree.existsSync()) {
    final loader = FontLoader('Figtree')
      ..addFont(Future.value(ByteData.sublistView(figtree.readAsBytesSync())));
    await loader.load();
  }

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;

  final roboto = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last.toLowerCase();
    if (name.startsWith('roboto-') && name.endsWith('.ttf')) {
      roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
  }
  await roboto.load();

  final icons = File('${dir.path}/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}
