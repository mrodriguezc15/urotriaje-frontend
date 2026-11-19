import 'dart:convert';
import 'dart:async'; 
import 'dart:io';    
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:http/http.dart' as http;
import '../models/evaluation_model.dart';

// Definimos una clase personalizada para manejar los errores de la API
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message; 
}

// Estructura para agrupar la respuesta del chat y los resultados medicos
class ChatEvaluationResponse {
  final String chatMessage;
  final EvaluationResult evaluationResult;
  final Map<String, dynamic> rawSymptoms;

  ChatEvaluationResponse({
    required this.chatMessage,
    required this.evaluationResult,
    required this.rawSymptoms,
  });
}

class ApiService {
  // Ajustamos la URL base dependiendo de si estamos en web o en un emulador Android (pruebas locales)
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://urotriaje-api.onrender.com'; 
    } else {
      return 'http://10.0.2.2:8000';
    }
  }
  
  static const int timeoutSeconds = 60;
  static int? currentUserId;
  static String? currentUserName;

  // Convertimos el codigo hexadecimal del servidor a un objeto Color de Flutter
  static Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  // Centralizamos el manejo de errores de red para no repetir codigo
  static ApiException _handleNetworkError(dynamic e) {
    if (e is TimeoutException) {
      return ApiException('La IA tardó mucho en responder. Intenta de nuevo.');
    } else if (e is ApiException) {
      return e; 
    } else if (!kIsWeb && e is SocketException) {
      return ApiException('No hay conexión al servidor. Verifica tu internet.');
    } else {
      return ApiException('Ocurrió un error de red o de servidor.');
    }
  }

  // Metodo para autenticar al usuario y guardar su sesion localmente
  static Future<void> login(String cedula, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"cedula": cedula, "contrasena": contrasena}),
      ).timeout(const Duration(seconds: timeoutSeconds)); 

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentUserId = data['id_usuario'];
        currentUserName = data['nombres'];
      } else {
        final error = json.decode(response.body);
        throw ApiException(error['detail'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  
  // Registramos un nuevo usuario incluyendo el PIN de seguridad
  static Future<void> register(String cedula, String nombres, String apellidos, String contrasena, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/registro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "cedula": cedula,
          "nombres": nombres,
          "apellidos": apellidos,
          "contrasena": contrasena,
          "pin_seguridad": pin 
        }),
      ).timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentUserId = data['id_usuario'];
        currentUserName = data['nombres'];
      } else {
        final error = json.decode(response.body);
        throw ApiException(error['detail'] ?? 'Error al registrar usuario');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
  
  
  // Consumimos el endpoint de recuperacion validando con el PIN de seguridad
  static Future<void> resetPassword(String cedula, String pin, String nuevaContrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recuperar_password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "cedula": cedula,
          "pin_seguridad": pin,
          "nueva_contrasena": nuevaContrasena
        }),
      ).timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw ApiException(error['detail'] ?? 'Error al restablecer la contraseña');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // Limpiamos los datos del usuario al cerrar sesion
  static void logout() {
    currentUserId = null;
    currentUserName = null;
  }

  // Enviamos el mensaje del paciente a la API para que la IA lo analice
  static Future<ChatEvaluationResponse> sendChatMessage(String mensaje, Map<String, dynamic> sintomasAcumulados) async {
    if (currentUserId == null) throw ApiException('La sesión ha caducado.');

    final requestBody = {
      "id_usuario": currentUserId,
      "mensaje_usuario": mensaje,
      "sintomas_previos": sintomasAcumulados 
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat_evaluar'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));
        final data = decodedBody['data'];
        final evaluacionData = data['evaluacion'];

        // Construimos el objeto de resultado con los datos que nos devuelve el servidor
        final result = EvaluationResult(
          riskLevel: evaluacionData['nivel_riesgo'],
          recommendation: evaluacionData['recomendacion'],
          date: DateTime.now().toString().substring(0, 10),
          riskColor: _hexToColor(evaluacionData['color_riesgo']),
        );

        return ChatEvaluationResponse(
          chatMessage: data['mensaje_chat'],
          evaluationResult: result,
          rawSymptoms: Map<String, dynamic>.from(data['sintomas_acumulados']), 
        );
      } else {
        final decodedError = json.decode(utf8.decode(response.bodyBytes));
        throw ApiException(decodedError['detail'] ?? 'Error al procesar el mensaje con la IA.');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // Traemos el historial de evaluaciones previas del paciente
  static Future<List<EvaluationResult>> getHistory() async {
    if (currentUserId == null) throw ApiException('La sesión ha caducado.');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/historial/$currentUserId'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = jsonResponse['data'];

        return data.map((item) => EvaluationResult(
          riskLevel: item['nivel_riesgo'],
          recommendation: item['recomendacion'],
          date: item['fecha_evaluacion'],
          riskColor: _hexToColor(item['color_riesgo']),
        )).toList();
      } else {
        throw ApiException('No se pudo cargar el historial.');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}