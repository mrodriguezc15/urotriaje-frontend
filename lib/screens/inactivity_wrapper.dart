import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  
  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    // Se configura en 2 minutos
    _timer = Timer(const Duration(minutes: 2), _logoutUsuario);
  }

  void _handleInteraction([_]) {
    _startTimer(); // Si el usuario toca la pantalla, el tiempo se reinicia
  }

  void _logoutUsuario() {
    ApiService.logout();
    if (mounted) {
      // Expulsa al usuario por seguridad y lo manda al login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada por inactividad. Privacidad protegida.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El widget Listener detecta cualquier toque en la pantalla
    return Listener(
      onPointerDown: _handleInteraction,
      onPointerMove: _handleInteraction,
      onPointerUp: _handleInteraction,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}