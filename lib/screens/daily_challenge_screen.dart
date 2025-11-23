import 'package:flutter/material.dart';
import '../game_page.dart';
import 'dart:math';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categorias = ["Historia", "Ciencia", "Geografía", "Deportes", "Arte", "Tecnología"];
    final niveles = ["Fácil", "Medio", "Difícil"];

    return Scaffold(
      appBar: AppBar(title: const Text("Desafío Diario")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 50),
            backgroundColor: Colors.teal,
          ),
          onPressed: () {
            final categoria = categorias[Random().nextInt(categorias.length)];
            final nivel = niveles[Random().nextInt(niveles.length)];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GamePage(
                  modo: 'desafío diario',
                  nivel: null,
                  categoria: null,
                ),
              ),
            );
          },
          child: const Text("Iniciar Desafío", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }
}
