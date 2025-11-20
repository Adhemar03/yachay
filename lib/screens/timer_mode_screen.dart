import 'package:flutter/material.dart';
import '../game_page.dart';
import 'dart:math';

class ContrarrelojScreen extends StatelessWidget {
  const ContrarrelojScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modo Contrarreloj")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Elige un nivel (2 minutos por partida, categoría al azar)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildLevelButton(BuildContext context, String nivel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.teal,
        ),
        onPressed: () {
          final categorias = [
            "Historia",
            "Ciencia",
            "Geografía",
            "Deportes",
            "Arte",
            "Tecnología",
          ];
          final categoria = categorias[Random().nextInt(categorias.length)];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GamePage(
                modo: 'contrarreloj',
                nivel: nivel,
                categoria: categoria,
              ),
            ),
          );
        },
        child: Text(
          nivel,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
