import 'package:flutter/material.dart';
import 'dart:async';

class PreguntasScreen extends StatefulWidget {
  final String titulo;
  final Duration? tiempo;
  final int totalPreguntas;

  const PreguntasScreen({
    super.key,
    required this.titulo,
    this.tiempo,
    this.totalPreguntas = 10,
  });

  @override
  State<PreguntasScreen> createState() => _PreguntasScreenState();
}

class _PreguntasScreenState extends State<PreguntasScreen> {
  int preguntaActual = 1;
  Timer? _timer;
  int segundosRestantes = 0;

  @override
  void initState() {
    super.initState();
    if (widget.tiempo != null) {
      segundosRestantes = widget.tiempo!.inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (segundosRestantes > 0) {
          setState(() => segundosRestantes--);
        } else {
          timer.cancel();
          Navigator.pop(context); // se acaba el tiempo
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          if (widget.tiempo != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  "${(segundosRestantes ~/ 60).toString().padLeft(2, '0')}:${(segundosRestantes % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pregunta $preguntaActual de ${widget.totalPreguntas}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Aquí iría el enunciado de la pregunta...",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (preguntaActual < widget.totalPreguntas) {
                  setState(() => preguntaActual++);
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Responder", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
