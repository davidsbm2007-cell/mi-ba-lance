import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/theme_mode.dart';
import '../../core/widgets.dart';
import '../../data/backup/backup_service.dart' show backupFilePath;
import '../demo/demo_actions.dart';
import '../shell/page_body.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _daily = true;
  bool _budgetAlerts = true;
  bool _weekly = false;

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _loadDemo() async {
    await loadDemoData(ref);
    if (mounted) _toast('Datos de ejemplo cargados');
  }

  Future<void> _wipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar todos los datos?'),
        content: const Text(
          'Se eliminarán tus movimientos, presupuestos, metas y deudas de este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: Brand.expenseText)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await wipeAllData(ref);
    if (mounted) _toast('Datos borrados');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return PageBody(
      title: 'Configuración',
      subtitle: 'Ajusta la app a tu medida',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            _Section(
              title: 'Perfil',
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Nombre'),
                  subtitle: Text(session.displayName),
                ),
                if (session.email != null)
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Correo'),
                    subtitle: Text(session.email!),
                  ),
                const ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Moneda'),
                  subtitle: Text('USD · Dólar estadounidense'),
                ),
                ListTile(
                  leading: const Icon(Icons.slideshow_outlined),
                  title: const Text('Ver la guía de bienvenida'),
                  onTap: () => ref.read(sessionProvider.notifier).replayOnboarding(),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  subtitle: const Text('Tus datos se quedan en este dispositivo'),
                  onTap: () => ref.read(sessionProvider.notifier).signOut(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Apariencia',
              children: [
                const ListTile(
                  leading: Icon(Icons.brightness_6_outlined),
                  title: Text('Tema'),
                  subtitle: Text('Claro, oscuro o el mismo de tu teléfono'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined, size: 18),
                        label: Text('Sistema'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined, size: 18),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 18),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {ref.watch(themeModeProvider)},
                    onSelectionChanged: (s) =>
                        ref.read(themeModeProvider.notifier).set(s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Notificaciones (vista previa)',
              children: [
                SwitchListTile(
                  value: _daily,
                  onChanged: (v) => setState(() => _daily = v),
                  title: const Text('Recordatorio diario'),
                  subtitle: const Text('Te avisa para registrar tus gastos'),
                ),
                SwitchListTile(
                  value: _budgetAlerts,
                  onChanged: (v) => setState(() => _budgetAlerts = v),
                  title: const Text('Alertas de presupuesto'),
                  subtitle: const Text('Cuando te acerques al límite'),
                ),
                SwitchListTile(
                  value: _weekly,
                  onChanged: (v) => setState(() => _weekly = v),
                  title: const Text('Resumen semanal'),
                  subtitle: const Text('Tips para mejorar tu dinero'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Plan',
              children: [
                ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Prueba gratis'),
                  subtitle: Text('Te quedan 30 días · luego, suscripción mensual'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Datos',
              children: [
                FutureBuilder<String?>(
                  future: backupFilePath(),
                  builder: (context, snap) => ListTile(
                    leading: const Icon(Icons.save_alt_outlined),
                    title: const Text('Copia en archivo local'),
                    subtitle: Text(
                      snap.data == null
                          ? 'Tus datos se guardan en este dispositivo'
                          : 'Se actualiza sola: ${snap.data}',
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Cargar datos de ejemplo'),
                  subtitle: const Text(
                    'Reemplaza tus datos con movimientos, presupuestos, metas y deudas de ejemplo',
                  ),
                  onTap: _loadDemo,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Brand.expenseText),
                  title: const Text(
                    'Borrar todos los datos',
                    style: TextStyle(color: Brand.expenseText),
                  ),
                  onTap: _wipe,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
