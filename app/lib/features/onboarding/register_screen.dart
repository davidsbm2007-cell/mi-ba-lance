import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../shell/app_shell.dart' show BrandMark;

/// Registro / ingreso de la beta. Acepta cualquier dato: no existe una cuenta
/// real todavía. Solo se guarda el nombre (y el correo si se escribe) en el
/// dispositivo; la contraseña se ignora.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _login = false;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final first = _name.text.trim();
    final mail = _login
        ? (first.contains('@') ? first : '')
        : _email.text.trim();
    final name = _login && first.contains('@') ? null : first;
    await ref.read(sessionProvider.notifier).signIn(name: name, email: mail);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 44),
                    const SizedBox(height: 22),
                    Text(
                      _login ? 'Bienvenido de vuelta' : 'Crea tu cuenta',
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _login ? 'Entra con tu usuario o correo.' : 'Es gratis por 30 días. Solo necesitamos tu nombre para saludarte.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: _login
                          ? TextCapitalization.none
                          : TextCapitalization.words,
                      autofillHints: [
                        _login ? AutofillHints.username : AutofillHints.name,
                      ],
                      decoration: InputDecoration(
                        labelText: _login ? 'Usuario o correo' : 'Tu nombre',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (_login
                                ? 'Escribe tu usuario o correo'
                                : 'Escribe tu nombre')
                          : null,
                    ),
                    if (!_login) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Correo (opcional)',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hide,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hide
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(_login ? 'Entrar' : 'Crear cuenta'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _login = !_login),
                        child: Text(
                          _login
                              ? '¿Primera vez? Crea tu cuenta'
                              : '¿Ya tienes cuenta? Entrar',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Brand.tealText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Versión beta: la cuenta es de prueba. Se acepta cualquier '
                              'dato y solo se guarda tu nombre en este dispositivo. '
                              'La contraseña no se guarda.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
