import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'core/theme_mode.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/cards/cards_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/movements/movements_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/register_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/transaction.dart';

/// Sin el estiramiento de Android al llegar al borde del scroll: deformaba
/// los gráficos y las tarjetas. iOS conserva su rebote, que mueve sin deformar.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

GoRoute _tab(String path, Widget screen) => GoRoute(
      path: path,
      pageBuilder: (context, state) => NoTransitionPage(child: screen),
    );

/// Primero la guía de bienvenida, luego el registro de prueba y después la app.
String? _sessionRedirect(AppSession session, String location) {
  if (!session.onboardingSeen) {
    return location == '/bienvenida' ? null : '/bienvenida';
  }
  if (!session.signedIn) {
    return location == '/registro' ? null : '/registro';
  }
  if (location == '/bienvenida' || location == '/registro') return '/';
  return null;
}

GoRouter _buildRouter(AppSession Function() session, Listenable refresh) => GoRouter(
  refreshListenable: refresh,
  redirect: (context, state) => _sessionRedirect(session(), state.uri.path),
  routes: [
    GoRoute(
      path: '/bienvenida',
      pageBuilder: (context, state) => const NoTransitionPage(child: OnboardingScreen()),
    ),
    GoRoute(
      path: '/registro',
      pageBuilder: (context, state) => const NoTransitionPage(child: RegisterScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        _tab('/', const DashboardScreen()),
        _tab('/movimientos', const MovementsScreen()),
        _tab('/tarjetas', const CardsScreen()),
        _tab('/presupuestos', const BudgetsScreen()),
        _tab('/deudas', const DebtsScreen()),
        _tab('/metas', const GoalsScreen()),
        _tab('/reportes', const ReportsScreen()),
        _tab('/config', const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) {
        final args = state.extra as AddArgs?;
        return AddTransactionScreen(
          initialKind: args?.kind ?? TxKind.expense,
          initialCategory: args?.category,
        );
      },
    ),
  ],
);

class FinanzasApp extends ConsumerStatefulWidget {
  const FinanzasApp({super.key});

  @override
  ConsumerState<FinanzasApp> createState() => _FinanzasAppState();
}

class _FinanzasAppState extends ConsumerState<FinanzasApp> {
  final _sessionChanged = ValueNotifier<int>(0);
  late final GoRouter _router = _buildRouter(
    () => ref.read(sessionProvider),
    _sessionChanged,
  );

  @override
  void dispose() {
    _router.dispose();
    _sessionChanged.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (_, _) => _sessionChanged.value++);
    return MaterialApp.router(
      title: 'Mi Balance',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es'), Locale('en')],
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: _router,
    );
  }
}
