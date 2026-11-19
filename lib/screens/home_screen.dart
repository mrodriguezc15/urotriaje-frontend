// Archivo: home_screen.dart
import 'package:flutter/material.dart';
import 'evaluation_screen.dart';
import 'history_screen.dart';
import '../services/api_service.dart';
import 'inactivity_wrapper.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Limpiamos los datos locales del usuario al salir de la sesion
  void _logout(BuildContext context) {
    ApiService.logout();
    // Aqui usamos pushNamedAndRemoveUntil con '/' para borrar el historial y que la URL vuelva al inicio
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // Asi protegemos el inicio si el paciente deja el celular sobre la mesa
    return InactivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio - UroTriaje'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _logout(context),
            )
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenido(a), ${ApiService.currentUserName ?? 'Usuario'}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Seleccione una opción para continuar:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Nos lleva a la pantalla donde se hace la evaluacion con la IA
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EvaluationScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Hablar con Orientador IA'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
                
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Ver Mi Historial'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
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