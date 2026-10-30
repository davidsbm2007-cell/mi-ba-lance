import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/theme_mode.dart';
import '../../core/widgets.dart';
import 'app_shell.dart' show UserAvatar;

/// Contenedor de cada pestaña: encabezado + contenido con scroll.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    bool wide(BoxConstraints c) => c.maxWidth >= 900;
    return LayoutBuilder(
      builder: (context, c) {
        final pad = c.maxWidth >= 900 ? 28.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, wide(c) ? 28 : 16, pad, wide(c) ? 32 : 96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(title: title, subtitle: subtitle),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: wide ? 30 : 24,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: TextStyle(fontSize: wide ? 16 : 14, color: muted, height: 1.35),
            ),
          ),
      ],
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: titleBlock),
          const _MonthPicker(),
          const SizedBox(width: 4),
          const ThemeToggleButton(),
          const _BellButton(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: titleBlock),
            const ThemeToggleButton(),
            const _BellButton(),
            const SizedBox(width: 4),
            const _Avatar(),
          ],
        ),
        const SizedBox(height: 12),
        const _MonthPicker(),
      ],
    );
  }
}

class _MonthPicker extends ConsumerWidget {
  const _MonthPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final months = [for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i)];

    return PopupMenuButton<DateTime>(
      tooltip: 'Cambiar mes',
      onSelected: ref.read(selectedMonthProvider.notifier).select,
      itemBuilder: (_) => [
        for (final m in months)
          PopupMenuItem(value: m, child: Text(monthLabel(m))),
      ],
      child: PillLabel(monthLabel(selected), icon: Icons.calendar_today_outlined),
    );
  }
}

/// Alterna entre modo claro y oscuro desde cualquier pantalla.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 22),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificaciones: próximamente')),
      ),
      icon: const Icon(Icons.notifications_none, size: 22),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => context.go('/config'),
      child: const UserAvatar(size: 34),
    );
  }
}
