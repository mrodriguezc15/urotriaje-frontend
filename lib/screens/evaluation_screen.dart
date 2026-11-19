// Archivo: evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/api_service.dart';
import '../models/evaluation_model.dart';
import 'inactivity_wrapper.dart'; 

// Definimos como se va a estructurar cada mensaje dentro del chat
class ChatMessage {
  final String text;
  final bool isUser;
  final EvaluationResult? evaluation; 

  ChatMessage({required this.text, required this.isUser, this.evaluation});
}

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  
  // Con esto bloqueamos el boton mientras esperamos que la IA nos responda
  bool _isLoading = false;
  
  // Aqui vamos guardando los sintomas que el paciente menciona durante la charla
  Map<String, dynamic> _sintomasAcumulados = {
    "s_disuria": false,
    "s_hematuria": false,
    "s_fiebre": false,
    "s_polaquiuria": false,
    "s_dolor_lumbar": false,
  };

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Hola ${ApiService.currentUserName ?? ''}. Soy tu orientador médico virtual. Por favor, descríbeme con tus propias palabras qué molestias o síntomas sientes el día de hoy.',
        isUser: false,
      ),
    );
  }

  // Este metodo nos sirve para hacer auto-scroll hacia el ultimo mensaje recibido
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Aqui procesamos lo que escribe el paciente y se lo mandamos a la API
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Armamos el historial oculto para que la IA entienda el contexto de la charla
    StringBuffer historialOculto = StringBuffer();
    historialOculto.writeln("--- HISTORIAL DE CONVERSACIÓN ---");
    for (var msg in _messages) {
      if (msg.text.contains("Soy tu orientador médico")) continue;
      String rol = msg.isUser ? "Paciente" : "Orientador";
      historialOculto.writeln("$rol: ${msg.text}");
    }
    historialOculto.writeln("Paciente (NUEVO MENSAJE): $text");
    historialOculto.writeln("---------------------------------");

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      // Consumimos el endpoint pasandole todo el historial y los sintomas actuales
      final response = await ApiService.sendChatMessage(
        historialOculto.toString(), 
        _sintomasAcumulados
      );
      
      if (mounted) {
        setState(() {
          _sintomasAcumulados = response.rawSymptoms;
          
          _messages.add(
            ChatMessage(
              text: response.chatMessage,
              isUser: false,
              evaluation: response.evaluationResult, 
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }
  
  // Utilizamos este metodo para abrir mapas si el paciente necesita ir a urgencias
  Future<void> _abrirUrgenciasCercanas() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=hospitales+urgencias+barranquilla');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el mapa en este dispositivo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // Si el usuario deja la pantalla sin tocar, cerrara sesion automaticamente.
    return InactivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Triaje Preliminar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Nueva Consulta',
              onPressed: () {
                // Limpiamos la conversacion para empezar un triaje desde cero
                setState(() {
                  _messages.clear();
                  _sintomasAcumulados = {
                    "s_disuria": false,
                    "s_hematuria": false,
                    "s_fiebre": false,
                    "s_polaquiuria": false,
                    "s_dolor_lumbar": false,
                  };
                  _messages.add(
                    ChatMessage(
                      text: 'Hola. ¿Hay algún otro síntoma que desees evaluar hoy?',
                      isUser: false,
                    ),
                  );
                });
              },
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildChatBubble(_messages[index]);
                  },
                ),
              ),
              
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('IA analizando síntomas...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading, 
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Describe tus molestias aquí...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Aqui renderizamos los mensajitos del chat y la tarjeta de riesgo si la hay
  Widget _buildChatBubble(ChatMessage message) {
    bool isUser = message.isUser;
    
    bool esRiesgoAlto = message.evaluation != null && 
        (message.evaluation!.riskLevel.toLowerCase().contains('alto') || 
         message.evaluation!.riskColor == Colors.red);
         
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 16,
                  child: Icon(Icons.medical_information, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 24), 
            ],
          ),

          if (message.evaluation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 32, right: 16),
              child: Card(
                elevation: 0,
                color: message.evaluation!.riskColor.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: message.evaluation!.riskColor.withOpacity(0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: message.evaluation!.riskColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.evaluation!.riskLevel.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: message.evaluation!.riskColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text('Recomendación de Triaje:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        message.evaluation!.recommendation,
                        style: const TextStyle(height: 1.4),
                      ),
                      
                      // Mostramos el boton del mapa solo si el motor experto detecto riesgo alto
                      if (esRiesgoAlto) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _abrirUrgenciasCercanas,
                            icon: const Icon(Icons.local_hospital),
                            label: const Text('Ver Urgencias Cercanas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              elevation: 0,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}