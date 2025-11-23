import 'package:flutter/material.dart';
import '../game_page.dart';

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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildLevelButton(context, "fácil"),
            _buildLevelButton(context, "medio"),
            _buildLevelButton(context, "difícil"),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  GamePage(modo: 'clásico', nivel: dificultad, categoria: null),
            ),
          );
        },
        child: Text(
          dificultad,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
