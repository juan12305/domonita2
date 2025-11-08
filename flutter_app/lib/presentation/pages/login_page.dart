import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        setState(() => _error = 'Credenciales incorrectas.');
        return;
      }

      if (!mounted) return;

      if (_biometricAvailable && response.session != null) {
        await _handleBiometricEnrollment(response.session!);
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso ✅')),
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
    final sessionString = await _biometricService.savedSessionString();
    if (sessionString == null) {
      await _biometricService.disableBiometrics();
      if (!autoTriggered && mounted) {
        setState(() {
          _biometricEnabled = false;
          _error = 'No hay una sesión guardada para usar la huella.';
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
        reason: 'Confirma tu huella para continuar',
      );

      if (!authenticated) {
        if (!autoTriggered && mounted) {
          setState(() => _error = 'Autenticación cancelada.');
        }
        return;
      }

      final response =
          await Supabase.instance.client.auth.recoverSession(sessionString);

      if (response.session == null) {
        throw Exception('No se pudo restaurar la sesión.');
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/control');
    } catch (e) {
      await _biometricService.disableBiometrics();
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
          if (!autoTriggered) {
            _error =
                'No se pudo iniciar con huella. Usa tu correo y contraseña.';
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

    final email = session.user.email ?? _emailController.text.trim();
    final friendlyEmail = email.isEmpty ? 'tu cuenta' : email;

    if (_biometricEnabled) {
      await _biometricService.refreshStoredSession(session, email);
      return;
    }

    final shouldEnable = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usar huella digital'),
            content: Text(
              '¿Quieres usar la huella para iniciar sesión como $friendlyEmail sin volver a escribir la contraseña?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, activar'),
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
      const SnackBar(
        content: Text('Huella registrada para el próximo inicio.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            "Inicia sesión",
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
                                    ? 'Iniciar con huella ($_biometricEmail)'
                                    : 'Iniciar con huella',
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

                          _buildTextField(_emailController, "Correo electrónico", Icons.email),
                          const SizedBox(height: 16),
                          _buildTextField(_passwordController, "Contraseña", Icons.lock, isPassword: true),

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
                                : const Text("Iniciar sesión",
                                    style: TextStyle(fontSize: 16, color: Colors.white)),
                          ).animate().fadeIn().scale(),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                            child: const Text(
                              "¿No tienes cuenta? Regístrate",
                              style: TextStyle(color: Colors.white70),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
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
      validator: (value) =>
          value == null || value.isEmpty ? 'Completa este campo' : null,
    );
  }
}
