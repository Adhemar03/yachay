import 'package:flutter/material.dart';
import 'preguntas_screen.dart';
import 'dart:math';

class ClasicoScreen extends StatelessWidget {
  const ClasicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modo Clásico")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Elige dificultad",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildLevelButton(context, "Fácil"),
            _buildLevelButton(context, "Medio"),
            _buildLevelButton(context, "Difícil"),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(BuildContext context, String dificultad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.teal,
        ),
        onPressed: () {
          final categorias = ["Historia", "Ciencia", "Geografía", "Deportes", "Arte", "Tecnología"];
          final categoria = categorias[Random().nextInt(categorias.length)];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PreguntasScreen(
                titulo: "Clásico - $dificultad - $categoria",
                tiempo: null,
                totalPreguntas: 10,
              ),
            ),
          );
        },
        child: Text(dificultad, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
