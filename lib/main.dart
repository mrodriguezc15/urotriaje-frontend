import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'screens/inactivity_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const UroTriajeApp());
}

class UroTriajeApp extends StatelessWidget {
  const UroTriajeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UroTriaje',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),  
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return InactivityWrapper(
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => ApiService.currentUserId == null
            ? const LoginScreen()
            : const HomeScreen(),
      },
    );
  }
}