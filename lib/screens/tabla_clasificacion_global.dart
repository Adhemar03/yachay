import 'package:flutter/material.dart';
import 'package:yachay/core/app_colors.dart';

class ScreenTablaClasificacionGlobal extends StatefulWidget {
  const ScreenTablaClasificacionGlobal({super.key});

  @override
  State<ScreenTablaClasificacionGlobal> createState() =>
      _ScreenTablaClasificacionGlobalState();
}

class _ScreenTablaClasificacionGlobalState
    extends State<ScreenTablaClasificacionGlobal> {
  int opcion = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletadeColores.textoB,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            Container(
              width: double.infinity, // ancho del rectángulo
              height: 70, // alto del rectángulo
              decoration: BoxDecoration(
                color: PaletadeColores
                    .fondo, // usa color aquí, NO en Container.color
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ), // <- radio de las esquinas
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 25,
                    ),
                    child: Image.asset(
                      "assets/images/logo_GOOGLE.png",
                      height: 30, // tamaño apropiado para el botón
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // Espacio pequeño
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Primer botón
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 7, left: 20),
                    child: SizedBox(
                      width: 40,
                      height: 48,

                      child: ElevatedButton(
                        onPressed: () {
                          // Acción del primer botón
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PaletadeColores.secundario,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Global',
                          style: TextStyle(
                            color: PaletadeColores.textoB,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Segundo botón
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, left: 7),
                    child: SizedBox(
                      width: 40,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // Acción del segundo botón
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PaletadeColores.fondo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Local',
                          style: TextStyle(
                            color: PaletadeColores.textoB,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // ...más widgets si los necesitas...
          ],
        ),
      ),
    );
  }
}
