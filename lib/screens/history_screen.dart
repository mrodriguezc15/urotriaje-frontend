import 'package:flutter/material.dart';
import '../models/evaluation_model.dart';
import '../services/api_service.dart';
import 'result_screen.dart'; 

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Historial')),
      // Se envuelve el arbol de widgets en un SafeArea para prevenir superposiciones con los bordes fisicos del dispositivo
      body: SafeArea(
        child: FutureBuilder<List<EvaluationResult>>(
          // Se consume el endpoint del backend mediante el FutureBuilder para recuperar el historial de evaluaciones del paciente
          future: ApiService.getHistory(), 
          builder: (context, snapshot) {
            // Se gestiona el estado de espera renderizando un indicador de carga durante la resolucion del future
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando historial...'),
                  ],
                ),
              );
            } 
            // Se capturan y exponen las excepciones de red o servidor para proveer feedback visual controlado al usuario
            else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar el historial:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            } 
            // Se valida el escenario donde la peticion es exitosa pero la coleccion de registros retorna vacia
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No hay evaluaciones previas.'),
              );
            }

            // Se extraen los registros resueltos para poblar el ListView de forma dinamica
            final records = snapshot.data!;
            return ListView.builder(
              itemCount: records.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record.riskColor.withOpacity(0.2),
                      child: Icon(Icons.assignment, color: record.riskColor),
                    ),
                    title: Text(record.riskLevel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Fecha: ${record.date}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    
                    // Se implementa el manejador de eventos onTap para capturar la interaccion tactil sobre la tarjeta
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Se inyecta el modelo de evaluacion especifico a traves del constructor de la pantalla de resultados
                          builder: (_) => ResultScreen(result: record),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}