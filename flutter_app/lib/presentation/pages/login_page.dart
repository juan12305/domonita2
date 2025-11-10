import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/l10n_extensions.dart';
import '../../services/biometric_auth_service.dart';
import '../theme/color_utils.dart';
import '../widgets/particle_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  final _biometricService = BiometricAuthService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;
  String? _biometricEmail;
  bool _autoBiometricAttempted = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _initBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = context.l10n;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        setState(() => _error = l10n.literal(
              es: 'Credenciales incorrectas.',
              en: 'Incorrect credentials.',
            ));
        return;
      }

      if (!mounted) return;

      if (_biometricAvailable && response.session != null) {
        await _handleBiometricEnrollment(response.session!);
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.literal(
              es: 'Inicio de sesión exitoso ✅',
              en: 'Signed in successfully ✅',
            ),
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, '/control');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _initBiometrics() async {
    final available = await _biometricService.canCheckBiometrics();
    final enabled = await _biometricService.isBiometricEnabled();
    final savedEmail = await _biometricService.savedEmail();
    final storedSession =
        enabled ? await _biometricService.savedSessionString() : null;

    if (!mounted) return;

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled && storedSession != null;
      _biometricEmail = savedEmail;
    });

    if (available &&
        enabled &&
        storedSession != null &&
        !_autoBiometricAttempted) {
      _autoBiometricAttempted = true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await _attemptBiometricLogin(autoTriggered: true);
      }
    }
  }

  Future<void> _attemptBiometricLogin({bool autoTriggered = false}) async {
    final l10n = context.l10n;
    final sessionString = await _biometricService.savedSessionString();
    if (sessionString == null) {
      await _biometricService.disableBiometrics();
      if (!autoTriggered && mounted) {
        setState(() {
          _biometricEnabled = false;
          _error = l10n.literal(
            es: 'No hay una sesión guardada para usar la huella.',
            en: 'No stored session available for fingerprint login.',
          );
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _biometricBusy = true;
        if (!autoTriggered) {
          _error = null;
        }
      });
    }

    try {
      final authenticated = await _biometricService.authenticate(
        reason: l10n.literal(
          es: 'Confirma tu huella para continuar',
          en: 'Confirm your fingerprint to continue',
        ),
      );

      if (!authenticated) {
        if (!autoTriggered && mounted) {
          setState(() => _error = l10n.literal(
                es: 'Autenticación cancelada.',
                en: 'Authentication cancelled.',
              ));
        }
        return;
      }

      final response =
          await Supabase.instance.client.auth.recoverSession(sessionString);

      if (response.session == null) {
        throw Exception(
          l10n.literal(
            es: 'No se pudo restaurar la sesión.',
            en: 'The session could not be restored.',
          ),
        );
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/control');
    } catch (e) {
      await _biometricService.disableBiometrics();
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
          if (!autoTriggered) {
            _error = l10n.literal(
              es: 'No se pudo iniciar con huella. Usa tu correo y contraseña.',
              en: 'Fingerprint login failed. Use your email and password.',
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _biometricBusy = false;
        });
      }
    }
  }

  Future<void> _handleBiometricEnrollment(Session session) async {
    if (!_biometricAvailable) return;

    final l10n = context.l10n;
    final email = session.user.email ?? _emailController.text.trim();
    final friendlyEmail =
        email.isEmpty ? l10n.literal(es: 'tu cuenta', en: 'your account') : email;

    if (_biometricEnabled) {
      await _biometricService.refreshStoredSession(session, email);
      return;
    }

    final shouldEnable = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              l10n.literal(
                es: 'Usar huella digital',
                en: 'Use fingerprint login',
              ),
            ),
            content: Text(
              l10n.literal(
                es:
                    '¿Quieres usar la huella para iniciar sesión como $friendlyEmail sin volver a escribir la contraseña?',
                en:
                    'Do you want to use your fingerprint to sign in as $friendlyEmail without retyping the password?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.literal(es: 'Ahora no', en: 'Not now'),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  l10n.literal(es: 'Sí, activar', en: 'Yes, enable'),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldEnable) {
      return;
    }

    await _biometricService.enableForSession(
      session: session,
      email: email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricEnabled = true;
      _biometricEmail = email;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.literal(
            es: 'Huella registrada para el próximo inicio.',
            en: 'Fingerprint saved for next sign in.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loginTitle = l10n.literal(es: 'Inicia sesión', en: 'Sign in');
    final fingerprintLabel = l10n.literal(
      es: 'Iniciar con huella',
      en: 'Sign in with fingerprint',
    );
    final registerPrompt = l10n.literal(
      es: '¿No tienes cuenta? Regístrate',
      en: "Don't have an account? Register",
    );
    return Scaffold(
      body: Stack(
        children: [
          const ParticleField(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF56CCF2),
                  Color(0xFF2F80ED),
                  Color(0xFF6DD5FA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue =
                      Curves.easeInOut.transform(_pulseController.value);
                  return Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: adjustOpacity(Colors.black, 0.4),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: adjustOpacity(const Color(0xFF6C63FF), 0.6 + 0.3 * pulseValue),
                            blurRadius: 20 + 15 * pulseValue,
                            spreadRadius: 2 + 2 * pulseValue,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            loginTitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 30),
                          if (_biometricAvailable && _biometricEnabled) ...[
                            OutlinedButton.icon(
                              onPressed: (_loading || _biometricBusy)
                                  ? null
                                  : () => _attemptBiometricLogin(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF6C63FF)),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 24,
                                ),
                              ),
                              icon: const Icon(Icons.fingerprint, color: Colors.white),
                              label: Text(
                                _biometricEmail != null
                                    ? '$fingerprintLabel ($_biometricEmail)'
                                    : fingerprintLabel,
                              ),
                            ),
                            if (_biometricBusy)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: LinearProgressIndicator(
                                  color: Color(0xFF6C63FF),
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],

                          _buildTextField(
                            context,
                            _emailController,
                            l10n.literal(
                              es: 'Correo electrónico',
                              en: 'Email',
                            ),
                            Icons.email,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context,
                            _passwordController,
                            l10n.literal(
                              es: 'Contraseña',
                              en: 'Password',
                            ),
                            Icons.lock,
                            isPassword: true,
                          ),

                          const SizedBox(height: 20),
                          if (_error != null)
                            Text(_error!, style: const TextStyle(color: Colors.redAccent)),

                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: (_loading || _biometricBusy)
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) _login();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              shadowColor: adjustOpacity(const Color(0xFF6C63FF), 0.5),
                              elevation: 12,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    loginTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ).animate().fadeIn().scale(),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/register'),
                            child: Text(
                              registerPrompt,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: adjustOpacity(Colors.white, 0.1),
      ),
      validator: (value) => value == null || value.isEmpty
          ? l10n.literal(
              es: 'Completa este campo',
              en: 'Please complete this field',
            )
          : null,
    );
  }
}
