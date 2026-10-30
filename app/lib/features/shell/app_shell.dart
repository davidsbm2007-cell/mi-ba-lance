import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../core/theme.dart';

class NavDest {
  const NavDest(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

const navDestinations = [
  NavDest('/', 'Resumen', Icons.home_rounded),
  NavDest('/movimientos', 'Movimientos', Icons.format_list_bulleted),
  NavDest('/tarjetas', 'Tarjetas', Icons.credit_card_outlined),
  NavDest('/presupuestos', 'Presupuestos', Icons.pie_chart_outline),
  NavDest('/deudas', 'Deudas', Icons.handshake_outlined),
  NavDest('/metas', 'Metas', Icons.track_changes),
  NavDest('/reportes', 'Reportes', Icons.bar_chart),
  NavDest('/config', 'Configuración', Icons.settings_outlined),
];

/// En el teléfono la barra inferior muestra solo los primeros destinos;
/// el resto vive detrás de "Más".
const _mobileMain = 4;

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final found = navDestinations.indexWhere((d) => d.path == location);
    final index = found < 0 ? 0 : found;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(selected: index),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        tooltip: 'Nuevo movimiento',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < _mobileMain ? index : _mobileMain,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => i < _mobileMain
            ? context.go(navDestinations[i].path)
            : _showMore(context, index),
        destinations: [
          for (final d in navDestinations.take(_mobileMain))
            NavigationDestination(icon: Icon(d.icon), label: d.label, tooltip: d.label),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Más',
            tooltip: 'Más secciones',
          ),
        ],
      ),
    );
  }

  void _showMore(BuildContext context, int current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = _mobileMain; i < navDestinations.length; i++)
              ListTile(
                leading: Icon(navDestinations[i].icon),
                title: Text(
                  navDestinations[i].label,
                  style: TextStyle(
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: i == current,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(navDestinations[i].path);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  BrandMark(size: 32),
                  SizedBox(width: 10),
                  Text(
                    'Mi Balance',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/add'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo movimiento'),
                ),
              ),
            ),
            for (var i = 0; i < navDestinations.length; i++)
              _SidebarItem(dest: navDestinations[i], selected: i == selected),
            const Spacer(),
            const _UserRow(),
          ],
        ),
      ),
    );
  }
}

/// Marca: tres barras ascendentes sobre azul marino.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, Color c) => Container(
          width: size * 0.14,
          height: size * h,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(size * 0.05),
          ),
        );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Brand.navy,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bar(0.28, Colors.white54),
          SizedBox(width: size * 0.07),
          bar(0.42, Colors.white),
          SizedBox(width: size * 0.07),
          bar(0.56, Brand.cyan),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.dest, required this.selected});

  final NavDest dest;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF1E3550) : const Color(0xFFE9EEF3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
      child: Material(
        color: selected ? fill : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: fill.withValues(alpha: 0.6),
          onTap: () => context.go(dest.path),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  dest.icon,
                  size: 20,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  dest.label,
                  style: TextStyle(
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  const _UserRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/config'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const UserAvatar(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.watch(sessionProvider).displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Prueba gratis · 30 días',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inicial del usuario en un círculo de tono neutro.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? const Color(0xFF1E3550) : const Color(0xFFE0F4F7),
      ),
      child: Text(
        ref.watch(sessionProvider).initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: dark ? Brand.cyan : Brand.tealText,
        ),
      ),
    );
  }
}
