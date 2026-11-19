import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showErrorSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _login() async {
    if (_cedulaController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Debes registrarte primero');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await ApiService.login(_cedulaController.text.trim(), _passwordController.text);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _demoLogin() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.login('000', '000');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ingreso rápido activado. ¡Bienvenido a la demo!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error en el entorno de demo. Asegúrate de haber creado el usuario en la BD.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // <--  LÓGICA DE RECUPERACIÓN DE CONTRASEÑA -->
  void _olvideMiContrasena() {
    final cedulaRecoveryController = TextEditingController();
    final pinController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isRecovering = false;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Recuperar Contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ingresa tu Cédula y el PIN de 4 dígitos que creaste al registrarte para cambiar tu contraseña.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cedulaRecoveryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cédula', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'PIN de Seguridad', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Nueva Contraseña', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isRecovering ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  onPressed: isRecovering ? null : () async {
                    if (cedulaRecoveryController.text.isEmpty || pinController.text.isEmpty || newPasswordController.text.isEmpty) {
                      _showErrorSnackBar('Por favor llena todos los campos');
                      return;
                    }
                    if (pinController.text.length != 4) {
                      _showErrorSnackBar('El PIN debe tener 4 dígitos');
                      return;
                    }

                    setStateDialog(() => isRecovering = true);

                    try {
                      await ApiService.resetPassword(
                        cedulaRecoveryController.text.trim(),
                        pinController.text.trim(),
                        newPasswordController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _showErrorSnackBar('Contraseña actualizada con éxito', isSuccess: true);
                      }
                    } catch (e) {
                      if (mounted) {
                        _showErrorSnackBar(e.toString());
                        setStateDialog(() => isRecovering = false);
                      }
                    }
                  },
                  child: isRecovering 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Restablecer'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.medical_services_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('UroTriaje', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Orientación Médica Preliminar', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _demoLogin,
                icon: const Icon(Icons.flash_on, color: Colors.amber),
                label: const Text('Probar Demo Rápida (Sin Registro)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.amber.shade400, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o ingresa con tu cuenta', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cédula', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.person)
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.lock)
                ),
              ),
              const SizedBox(height: 24),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _login,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('INGRESAR', style: TextStyle(fontSize: 16)),
                  ),
              const SizedBox(height: 8),
              
              
              TextButton(
                onPressed: _olvideMiContrasena,
                child: const Text(
                  '¿Olvidaste tu contraseña?', 
                  style: TextStyle(color: Colors.blue) // Cambio de color a azul para indicar que es clickeable
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              )
            ],
          ),
        ),
      ),
    );
  }
}