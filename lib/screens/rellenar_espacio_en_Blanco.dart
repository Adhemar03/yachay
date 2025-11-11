import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yachay/core/app_colors.dart';

class ScreenEspacioEnBlanco extends StatefulWidget {
  const ScreenEspacioEnBlanco({super.key});

  @override
  State<ScreenEspacioEnBlanco> createState() => _ScreenEspacioEnBlancoState();
}

class _ScreenEspacioEnBlancoState extends State<ScreenEspacioEnBlanco> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: [
            Image.asset("assets/images/logoV1.png", height: 240),

            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Stack(
                alignment:
                    Alignment.center, // centra los hijos dentro del Stack
                children: [
                  // Texto base con los puntos
                  Text(
                    "La............................ es un baile tipico que representa la lucha contra los demonios en Oruro",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PaletadeColores.textoB,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Rectángulo encima de los puntos
                  Positioned(
                    left: 34, // ajusta la posición horizontal del rectángulo
                    top: 3, // ajusta la vertical si es necesario
                    child: Container(
                      width: 200,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.only(
                top: 15,
                left: 5,
                right: 200,
                bottom: 10,
              ),
              child: Container(
                width: 200, // ancho del rectángulo
                height: 30, // alto del rectángulo
                decoration: BoxDecoration(
                  color: Colors.white, // color del fondo
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // esquinas redondeadas
                ),
                child: const Center(
                  child: Text(
                    "CUECA",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 200,
                right: 5,
                bottom: 10,
              ),
              child: Container(
                width: 200, // ancho del rectángulo
                height: 30, // alto del rectángulo
                decoration: BoxDecoration(
                  color: Colors.white, // color del fondo
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // esquinas redondeadas
                ),
                child: const Center(
                  child: Text(
                    "SAYA",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 5,
                right: 200,
                bottom: 10,
              ),
              child: Container(
                width: 200, // ancho del rectángulo
                height: 30, // alto del rectángulo
                decoration: BoxDecoration(
                  color: Colors.white, // color del fondo
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // esquinas redondeadas
                ),
                child: const Center(
                  child: Text(
                    "DIABLADA",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 200,
                right: 10,
                bottom: 5,
              ),
              child: Container(
                width: 200, // ancho del rectángulo
                height: 30, // alto del rectángulo
                decoration: BoxDecoration(
                  color: Colors.white, // color del fondo
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // esquinas redondeadas
                ),
                child: const Center(
                  child: Text(
                    "MORENADA",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
