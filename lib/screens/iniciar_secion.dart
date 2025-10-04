// lib/screens/iniciar_secion.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yachay/core/app_colors.dart';
import 'package:yachay/main.dart';
import 'package:yachay/game_mode_screen.dart';

class ScreenIniciarSecion extends StatefulWidget {
  const ScreenIniciarSecion({super.key});

  @override
  _ScreenIniciarSecionState createState() => _ScreenIniciarSecionState();
}

class _ScreenIniciarSecionState extends State<ScreenIniciarSecion> {
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passCtl = TextEditingController();

  bool _ocultarContra = true;
  bool _showCorreoError = false;
  bool _showPassError = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  // Versión simple: compara password en texto plano con password_hash en la tabla 'users'
  Future<void> _attemptSignIn() async {
    final email = _emailCtl.text.trim().toLowerCase();
    final password = _passCtl.text;

    setState(() {
      _showCorreoError = false;
      _showPassError = false;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) _showCorreoError = true;
        if (password.isEmpty) _showPassError = true;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      // Busca el usuario en la tabla 'users' (igual que antes)
      final userRow = await Supabase.instance.client
          .from('users')
          .select('user_id, password_hash')
          .eq('email', email)
          .maybeSingle();

      if (userRow == null) {
        setState(() {
          _showCorreoError = true;
          _loading = false;
        });
        return;
      }

      // Asegurarnos de tener un Map
      final Map<String, dynamic> u = Map<String, dynamic>.from(userRow);
      final stored = u['password_hash'] as String?;

      if (stored == null) {
        // Usuario sin contraseña guardada localmente (posible OAuth)
        setState(() {
          _showPassError = true;
          _loading = false;
        });
        return;
      }

      // COMPARACIÓN EN TEXTO PLANO (parche temporal)
      final bool passwordMatches = (stored == password);

      if (!passwordMatches) {
        setState(() {
          _showPassError = true;
          _loading = false;
        });
        return;
      }

      // Login aceptado: guardamos un flag local como "sesión" temporal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged', true);
      await prefs.setInt('user_id', u['user_id'] as int);

      if (!mounted) return;
      // Redireccionamiento a Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameModeScreen()),
      );
    } catch (err, st) {
      debugPrint('SIGNIN ERROR: $err\n$st');
      setState(() => _showPassError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: [
            Image.asset("assets/images/logo_YACHAY.png", height: 240),

            const SizedBox(height: 6),
            Text(
              "Bienvenido",
              style: TextStyle(
                color: PaletadeColores.secundario,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 18),
              child: Text(
                "Ingresa y continúa donde lo dejaste. \nGuarda tu progreso y sigue aprendiendo \nmientras juegas.",
                style: TextStyle(color: PaletadeColores.textoB, fontSize: 14),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PaletadeColores.textoB,
                  hintText: "correoelectronico@gmail.com",
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.account_circle,
                      size: 30,
                      color: PaletadeColores.iconoNegro,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: _showCorreoError ? 1.0 : 0.0,
                  child: Text(
                    "Correo no registrado",
                    style: TextStyle(color: PaletadeColores.error),
                    softWrap: true,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                controller: _passCtl,
                obscureText: _ocultarContra,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PaletadeColores.textoB,
                  hintText: "contraseña",
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.lock,
                      size: 30,
                      color: PaletadeColores.iconoNegro,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: IconButton(
                      icon: Icon(
                        _ocultarContra
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      color: PaletadeColores.iconoNegro,
                      onPressed: () {
                        setState(() {
                          _ocultarContra = !_ocultarContra;
                        });
                      },
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: _showPassError ? 1.0 : 0.0,
                  child: Text(
                    "Contraseña incorrecta",
                    style: TextStyle(color: PaletadeColores.error),
                    softWrap: true,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _attemptSignIn,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      PaletadeColores.secundario,
                    ),
                    foregroundColor: MaterialStateProperty.all(
                      PaletadeColores.textoB,
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator.adaptive()
                      : const Text("Iniciar Sesión"),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "¿No tienes una cuenta? ",
                    style: TextStyle(
                      color: PaletadeColores.textoB,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Acción al presionar Registrate
                      // Navegar a HomeScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // reduce espacio interno
                      minimumSize: Size(0, 0), // reduce tamaño mínimo
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: PaletadeColores.secundario,
                    ),
                    child: Text("Registrate", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HomeScreen mínimo de ejemplo. Reemplázalo por tu MyHomePage o pantalla real.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: const Center(child: Text('Bienvenido a la Home')),
    );
  }
}
