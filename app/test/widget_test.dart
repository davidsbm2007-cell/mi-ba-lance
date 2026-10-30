import 'package:finanzas_app/app.dart';
import 'package:finanzas_app/core/anim_cache.dart';
import 'package:finanzas_app/core/motion.dart';
import 'package:finanzas_app/core/session.dart';
import 'package:finanzas_app/features/dashboard/dashboard_cards.dart';
import 'package:drift/native.dart';
import 'package:finanzas_app/data/database.dart' show AppDatabase;
import 'package:finanzas_app/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_app/core/theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_fonts.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(412, 900),
  bool withDemo = false,
  AppSession session = const AppSession(name: 'David', onboardingSeen: true),
}) async {
  AnimCache.clear();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final overrides = await dataOverrides(db);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides, initialSessionProvider.overrideWithValue(session)],
      child: const FinanzasApp(),
    ),
  );
  await tester.pumpAndSettle();

  if (withDemo) {
    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
  }
}

/// Va a una sección desde la barra inferior (o desde "Más") en el teléfono.
Future<void> _goTo(WidgetTester tester, String label) async {
  final bar = find.byType(NavigationBar);
  final inBar = find.descendant(of: bar, matching: find.text(label));
  if (inBar.evaluate().isNotEmpty) {
    await tester.tap(inBar);
  } else {
    await tester.tap(find.descendant(of: bar, matching: find.text('Más')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(ListTile), matching: find.text(label)));
  }
  await tester.pumpAndSettle();
}

/// Abre "Nuevo movimiento" con el botón flotante del teléfono.
Future<void> _openNewMovement(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await loadTestFonts();
  });

  testWidgets('sin datos ofrece cargar el ejemplo', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Aún no tienes movimientos'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes movimientos'), findsNothing);
    expect(find.text('Saldo total'), findsOneWidget);
  });

  testWidgets('modo oscuro: se cambia desde Configuración y desde el botón rápido',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(brightness(), Brightness.light);

    // Botón rápido del encabezado.
    await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    expect(await loadSavedThemeMode(), ThemeMode.dark, reason: 'se guarda');

    await tester.tap(find.byTooltip('Cambiar a modo claro'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);

    // Selector de Configuración.
    await _goTo(tester, 'Configuración');
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light, reason: 'el sistema de pruebas es claro');
    expect(await loadSavedThemeMode(), ThemeMode.system);
  });

  testWidgets('beta: guía de bienvenida, registro y saludo con el nombre', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester, session: const AppSession());
    expect(find.text('Tu dinero, claro'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Tarjetas, deudas y reportes'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    // Registro: acepta cualquier dato, pero pide un nombre.
    expect(find.text('Crea tu cuenta'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Tu nombre'), 'maría paz');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, María Paz'), findsOneWidget);
  });

  testWidgets('beta: ingresar con solo un correo usa su nombre y se puede cerrar sesión',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester, session: const AppSession(onboardingSeen: true));
    expect(find.text('Crea tu cuenta'), findsWidgets);

    await tester.tap(find.text('¿Ya tienes cuenta? Entrar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario o correo'),
      'carlos.mora@correo.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Carlos Mora'), findsOneWidget);

    await _goTo(tester, 'Configuración');
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsWidgets);
  });

  testWidgets('caché de animaciones: una cifra ya vista no vuelve a subir desde cero',
      (tester) async {
    AnimCache.clear();
    Future<void> show() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedMoney(250000, cacheKey: 'test.money')),
      ));
    }

    await show();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(r'$2.500,00'), findsNothing, reason: 'primera vez: va subiendo');
    await tester.pumpAndSettle();
    expect(find.text(r'$2.500,00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await show();
    expect(find.text(r'$2.500,00'), findsOneWidget, reason: 'segunda vez: ya aparece completa');
  });

  testWidgets('al llegar al borde del scroll no se deforma el contenido',
      (tester) async {
    await _pumpApp(tester, withDemo: true);
    // En Android (la plataforma de las pruebas) el indicador por defecto
    // estiraba gráficos y tarjetas.
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);

    // Jalar más allá del borde superior no mueve ni estira el contenido.
    final before = tester.getTopLeft(find.text('Saldo total'));
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.text('Saldo total')), before);
    await tester.pumpAndSettle();
  });

  testWidgets('las cifras suben desde cero y las barras se llenan al cargar',
      (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pump(); // el reemplazo de datos termina
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    String balance() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => RegExp(r'^-?\$[\d.]+,\d\d$').hasMatch(s));

    final early = balance();
    await tester.pumpAndSettle();
    final done = balance();

    expect(early, isNot(done), reason: 'a mitad de la animación aún no llega');
    // Al terminar, la cifra final del saldo es la real (no queda en cero).
    expect(done, isNot(r'$0,00'));
  });

  testWidgets('con "reducir movimiento" las cifras aparecen ya completas',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpApp(tester);
    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final amounts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => RegExp(r'^-?\$[\d.]+,\d\d$').hasMatch(s))
        .toList();
    await tester.pumpAndSettle();
    final settled = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => RegExp(r'^-?\$[\d.]+,\d\d$').hasMatch(s))
        .toList();
    expect(amounts, settled);
  });

  testWidgets('nuevo movimiento: elegir categoría y registrar un gasto',
      (tester) async {
    await _pumpApp(tester);

    await _openNewMovement(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transporte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '12,50');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text(r'- $12,50'), findsOneWidget);
  });

  testWidgets('nuevo movimiento: cambiar a ingreso y registrarlo', (tester) async {
    await _pumpApp(tester);

    await _openNewMovement(tester);
    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nómina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text(r'+ $500,00'), findsOneWidget);
  });

  testWidgets('no guarda un monto inválido', (tester) async {
    await _pumpApp(tester);
    await _openNewMovement(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hogar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un monto mayor a 0'), findsOneWidget);
  });

  testWidgets('presupuestos: crear un límite y verlo en la lista',
      (tester) async {
    await _pumpApp(tester);
    await _goTo(tester, 'Presupuestos');
    expect(find.text('Aún no tienes presupuestos'), findsOneWidget);

    await tester.tap(find.text('Nuevo presupuesto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.tap(_inDialog('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes presupuestos'), findsNothing);
    expect(find.text('Presupuesto total del mes'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(BudgetRow), matching: find.text('Alimentación')),
      findsOneWidget,
    );
  });

  testWidgets('metas: crear una meta y abonar', (tester) async {
    await _pumpApp(tester);
    await _goTo(tester, 'Metas');
    expect(find.text('Aún no tienes metas'), findsOneWidget);

    await tester.tap(find.text('Nueva meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Viaje');
    await tester.enterText(find.byType(TextFormField).at(2), '1000');
    await tester.tap(_inDialog('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Viaje'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await _tapVisible(tester, find.text('Abonar'));
    await tester.enterText(find.byType(TextFormField).first, '250');
    await tester.tap(_inDialog('Abonar'));
    await tester.pumpAndSettle();

    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('deudas: registrar quién me debe y cobrar un abono',
      (tester) async {
    await _pumpApp(tester);
    await _goTo(tester, 'Deudas');
    expect(find.text('Nadie te debe por ahora'), findsOneWidget);

    await _tapVisible(tester, find.text('Agregar').first);
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await tester.tap(_inDialog('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Nadie te debe por ahora'), findsNothing);

    await _tapVisible(tester, find.text('Cobrar'));
    await tester.enterText(find.byType(TextFormField).first, '40');
    await tester.tap(_inDialog('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text(r'$60,00'), findsWidgets);
  });

  testWidgets('móvil con datos: dashboard completo y pestañas sin errores',
      (tester) async {
    await _pumpApp(tester, withDemo: true);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.text('Presupuestos de gastos'), findsOneWidget);

    for (final label in [
      'Movimientos',
      'Tarjetas',
      'Presupuestos',
      'Deudas',
      'Metas',
      'Reportes',
      'Configuración',
      'Resumen',
    ]) {
      await _goTo(tester, label);
      expect(tester.takeException(), isNull, reason: 'sección $label');
    }
    // Ya no hay una segunda barra con íconos de categorías.
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('tarjetas: crear una de crédito, consumir y pagar', (tester) async {
    await _pumpApp(tester);
    await _goTo(tester, 'Tarjetas');
    expect(find.text('Aún no tienes tarjetas'), findsOneWidget);

    await tester.tap(find.text('Nueva tarjeta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Visa Test');
    await tester.enterText(find.byType(TextFormField).at(1), '4821');
    await tester.enterText(find.byType(TextFormField).at(2), '1000');
    await tester.tap(_inDialog('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes tarjetas'), findsNothing);
    expect(find.text('Visa Test'), findsOneWidget);
    expect(find.text(r'Disponible $1.000,00'), findsOneWidget);

    await _tapVisible(tester, find.text('Consumo'));
    await tester.enterText(find.byType(TextFormField).first, '250');
    await tester.tap(_inDialog('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text(r'Disponible $750,00'), findsOneWidget);

    await _tapVisible(tester, find.text('Registrar pago'));
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.tap(_inDialog('Registrar'));
    await tester.pumpAndSettle();
    expect(find.text(r'Disponible $850,00'), findsOneWidget);
  });

  testWidgets('escritorio con datos: barra lateral y dashboard sin errores',
      (tester) async {
    await _pumpApp(tester, size: const Size(1500, 1000), withDemo: true);

    expect(find.text('Mi Balance'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Ingresos vs. Gastos'), findsOneWidget);
    expect(find.text('Gastos por categoría'), findsOneWidget);
    expect(find.text('Meta de ahorro'), findsOneWidget);

    expect(find.text('Nuevo movimiento'), findsOneWidget);

    for (final label in [
      'Movimientos',
      'Tarjetas',
      'Presupuestos',
      'Deudas',
      'Metas',
      'Reportes',
      'Configuración',
      'Resumen',
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'pestaña $label');
    }
  });
}
