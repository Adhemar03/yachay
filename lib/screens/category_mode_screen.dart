import 'package:flutter/material.dart';
import 'preguntas_screen.dart';

class CategoriaScreen extends StatelessWidget {
  const CategoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categorias = [
      "Historia",
      "Musica",
      "Geografía",
      "Deportes",
      "Arte",
      "Cultura"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Modo Categoría")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
              ),
              onPressed: () {
                _mostrarNiveles(context, categorias[index]);
              },
              child: Text(categorias[index],
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  void _mostrarNiveles(BuildContext context, String categoria) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Elige nivel en $categoria"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(context, categoria, "Fácil"),
            _buildDialogButton(context, categoria, "Medio"),
            _buildDialogButton(context, categoria, "Difícil"),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(BuildContext context, String categoria, String nivel) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreguntasScreen(
              titulo: "$categoria - $nivel",
              tiempo: null,
              totalPreguntas: 10,
            ),
          ),
        );
      },
      child: Text(nivel, style: const TextStyle(color: Colors.white)),
    );
  }
}
