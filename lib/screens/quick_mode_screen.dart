import 'package:flutter/material.dart';
import 'preguntas_screen.dart';

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
                builder: (_) => PreguntasScreen(
                  titulo: "Partida Rápida",
                  tiempo: null,
                  totalPreguntas: 10,
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
