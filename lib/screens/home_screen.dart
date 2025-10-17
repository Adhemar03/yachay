import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: const Center(
        child: Text(
          '¡Bienvenido a Yachay! Registro exitoso.',
          style: TextStyle(fontSize: 22, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
