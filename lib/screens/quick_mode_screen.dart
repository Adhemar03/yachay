import 'package:flutter/material.dart';
import '../game_page.dart';

class QuickModeScreen extends StatelessWidget {
  const QuickModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partida Rápida")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 50),
            backgroundColor: Colors.teal,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GamePage(
                  modo: 'rápida',
                  nivel: null,
                  categoria: null,
                ),
              ),
            );
          },
          child: const Text("Iniciar", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }
}
