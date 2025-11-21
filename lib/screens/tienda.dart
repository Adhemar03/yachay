import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yachay/core/app_colors.dart';
import 'package:yachay/game_mode_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Tienda extends StatefulWidget {
  const Tienda({super.key});

  @override
  State<Tienda> createState() => _TiendaState();
}

class _TiendaState extends State<Tienda> {
  int? PuntosDeUsuario;
  bool loading = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletadeColores.fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Stack que contiene cortina, container y vendedor ---
              SizedBox(
                height: 165, // espacio total donde vivirán los elementos
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1) CORTINA ARRIBA DEL TODO
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Image.asset(
                        "assets/images/Cortina.png",
                        //height: 100,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // 2) CONTAINER ABAJO DE LA CORTINA
                    Positioned(
                      top:
                          80, // aparece justo debajo de cortina (ajusta si quieres)
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 90,
                        padding: const EdgeInsets.only(
                          top:
                              60, // espacio para que la imagen del vendedor entre
                          left: 12,
                          right: 12,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF00D7CC),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    Positioned(
                      top:
                          108, // aparece justo debajo de cortina (ajusta si quieres)
                      left: 250,
                      right: 20,

                      child: Container(
                        height: 33,
                        padding: const EdgeInsets.only(
                          top:
                              60, // espacio para que la imagen del vendedor entre
                          left: 12,
                          right: 12,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF038C7F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Positioned(
                      top:
                          112.5, // aparece justo debajo de cortina (ajusta si quieres)
                      left: 285,
                      right: 10,
                      child: PuntosDeUsuario != null
                          ? Text(
                              "$PuntosDeUsuario",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              ".........",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    Positioned(
                      top: 105, // controla cuánto se mete en la cortina
                      left: 150,
                      right:
                          20, // AJUSTA LA POSICIÓN HORIZONTAL (centra o mueve)
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: Image.asset(
                          "assets/images/Oro.png",
                          fit: BoxFit.contain, // NO recorta la transparencia
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 80);
                          },
                        ),
                      ),
                    ),

                    // 3) IMAGEN DEL VENDEDOR SOBRESALIENDO ARRIBA Y SOBRE LA CORTINA
                    Positioned(
                      top: 25, // controla cuánto se mete en la cortina
                      left:
                          20, // AJUSTA LA POSICIÓN HORIZONTAL (centra o mueve)
                      child: SizedBox(
                        height: 170,
                        width: 170,
                        child: Image.asset(
                          "assets/images/Vendedor.png",
                          fit: BoxFit.contain, // NO recorta la transparencia
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 80);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- CARD CENTRAL ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- FILA 1 ----
                      Row(
                        children: [
                          _buildCaja(
                            context,
                            "assets/images/Vidas.png",
                            "Vidas x1",
                            "500",
                          ),
                          const SizedBox(width: 12),
                          _buildCaja(
                            context,
                            "assets/images/50 a 50.png",
                            "50 / 50 x1",
                            "300",
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ---- FILA 2 ----
                      Row(
                        children: [
                          _buildCaja(
                            context,
                            "assets/images/Next.png",
                            "Next x1",
                            "300",
                          ),
                          const SizedBox(width: 189),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 20,
                ), // ajusta la distancia
                child: SizedBox(
                  width: 60,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameModeScreen(),
                        ),
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.red),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    child: const Text(
                      "Regresar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _procesarCompra(String descripcion, int precio) async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');

      if (id == null) {
        setState(() => loading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: PaletadeColores.fondo,
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: const Text('No se encontró la sesión del usuario.'),
          ),
        );
        return;
      }

      final userRow = await Supabase.instance.client
          .from('users')
          .select('in_game_points,lives_count,hints_count,skips_count')
          .eq('user_id', id)
          .maybeSingle();

      if (userRow == null) {
        setState(() => loading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: PaletadeColores.fondo,
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: const Text(
              'No se encontró el usuario en la base de datos.',
            ),
          ),
        );
        return;
      }

      final currentPoints = (userRow['in_game_points'] as int?) ?? 0;

      if (currentPoints < precio) {
        setState(() => loading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: PaletadeColores.fondo,
            title: const Text(
              'Fondos insuficientes',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'No tienes suficientes puntos para realizar esta compra.',
            ),
          ),
        );
        return;
      }

      int lives = (userRow['lives_count'] as int?) ?? 0;
      int hints = (userRow['hints_count'] as int?) ?? 0;
      int skips = (userRow['skips_count'] as int?) ?? 0;

      final desc = descripcion.toLowerCase();
      if (desc.contains('vidas')) {
        lives += 1;
      } else if (desc.contains('50')) {
        hints += 1;
      } else if (desc.contains('next')) {
        skips += 1;
      }

      final updated = await Supabase.instance.client
          .from('users')
          .update({
            'in_game_points': currentPoints - precio,
            'lives_count': lives,
            'hints_count': hints,
            'skips_count': skips,
          })
          .eq('user_id', id)
          .select()
          .maybeSingle();

      if (updated != null) {
        setState(() {
          PuntosDeUsuario =
              (updated['in_game_points'] as int?) ?? (currentPoints - precio);
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra realizada con éxito')),
        );
        // Note: we already updated the user's `hints_count`/`skips_count` above
        // (the `update` call increments the appropriate counter). Do not call
        // `rpc_increment_power` here as that would increment twice.
      } else {
        setState(() => loading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: PaletadeColores.fondo,
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: const Text(
              'No se pudo completar la compra. Intenta nuevamente.',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: PaletadeColores.fondo,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          content: Text('Ocurrió un error: $e'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _sincronizarPuntosUsuario();
  }

  Future<void> _sincronizarPuntosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');

    if (id != null) {
      final userRow = await Supabase.instance.client
          .from('users')
          .select('in_game_points')
          .eq('user_id', id)
          .maybeSingle();

      if (userRow != null) {
        setState(() {
          PuntosDeUsuario = userRow['in_game_points'] as int?;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
    }
  }

  Widget _buildCaja(
    BuildContext context,
    String urlImagen,
    String descripcion,
    String precio,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _confirmarCompra(context, descripcion, precio),
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF00D7CC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                right: 10,
                left: 10,
                bottom: 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // contenedor interno con la imagen
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF038C7F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        urlImagen,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 48);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        precio,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Image.asset(
                        "assets/images/Oro.png",
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 30);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarCompra(
    BuildContext context,
    String descripcion,
    String precio,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              PaletadeColores.fondo, // <-- color del fondo del diálogo
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: const TextStyle(
            color: Colors.white, // color del título
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white70, // color del contenido
            fontSize: 16,
          ),
          title: const Text('Confirmar compra'),
          content: Text(
            '¿Seguro que quieres comprar "$descripcion" por $precio puntos?',
          ),
          actions: [
            ElevatedButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // color texto
                backgroundColor: Colors.redAccent, // fondo del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Rechazar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D7CC), // color del botón confirmar
                foregroundColor: Colors.white, // color texto del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                final precioInt = int.tryParse(precio) ?? 0;
                _procesarCompra(descripcion, precioInt);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
