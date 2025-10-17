// lib/screens/iniciar_secion.dart
import 'dart:async';
import 'package:flutter/services.dart'; // 👈 Necesario para copiar al portapapeles
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:yachay/core/app_colors.dart';
import 'package:yachay/main.dart';
import 'package:yachay/game_mode_screen.dart';
import 'signup_screen.dart';
import 'dart:math';

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
  bool _loadingGoogle = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  //Crear Contraseña
  String _generateRandomPassword([int length = 16]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_+=';
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  Future<void> _showGeneratedPasswordDialog(String password) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contraseña asignada', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ----- Etiqueta superior: una sola línea -----
            Text(
              'Tu contraseña temporal es:           ',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // asegura que quede en 1 línea
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 10),

            // ----- Caja de contraseña con password (izq) y botón copiar (der) -----
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Contraseña (izquierda)
                  Expanded(
                    child: SelectableText(
                      password,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Botón copiar (derecha)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy),
                      iconSize: 18,
                      tooltip: 'Copiar contraseña',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contraseña copiada al portapapeles'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ----- Etiqueta inferior centrada -----
            Text(
              'Cópiala y cámbiala desde tu perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: PaletadeColores.iconoNegro),
            ),
          ],
        ),

        // Botón cerrar centrado
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: PaletadeColores.secundario,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
            Image.asset("assets/images/logo_YACHAY.png", height: 200),

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

            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _attemptSignIn,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      PaletadeColores.secundario,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      PaletadeColores.textoB,
                    ),
                    shape: WidgetStateProperty.all(
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
            const SizedBox(height: 50),

            //Espacio para  el codgo de  imagen de separecion y el boton de continuar con Google
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loadingGoogle
                      ? null
                      : () async {
                          setState(() {
                            _loadingGoogle = true;
                          });

                          const webClientId =
                              '570366343589-5rct1gfumkk5alub4ju4fdjd0g4p2nfm.apps.googleusercontent.com';
                          const iosClientId =
                              '570366343589-oomgqr84af8a6f2eerp8dsc3ritmfjfa.apps.googleusercontent.com';
                          final googleSignIn = GoogleSignIn.instance;
                          final supabase = Supabase.instance.client;

                          try {
                            await googleSignIn.initialize(
                              clientId: kIsWeb ? webClientId : iosClientId,
                              serverClientId: webClientId,
                            );

                            final GoogleSignInAccount account =
                                await googleSignIn.authenticate();
                            if (account == null) {
                              setState(() {
                                _loadingGoogle = false;
                              });
                              return;
                            }

                            final GoogleSignInAuthentication auth =
                                await account.authentication;
                            final String? idToken = auth.idToken;

                            String? accessToken;
                            try {
                              final authClient = account.authorizationClient;
                              final dynamic authz = await authClient
                                  .authorizeScopes(<String>[
                                    'openid',
                                    'email',
                                    'profile',
                                  ]);
                              accessToken = authz?.accessToken as String?;
                              if (accessToken == null) {
                                final dynamic authz2 = await authClient
                                    .authorizationForScopes(<String>[
                                      'openid',
                                      'email',
                                      'profile',
                                    ]);
                                accessToken = authz2?.accessToken as String?;
                              }
                            } catch (e) {
                              debugPrint('authorizeScopes (no crítico): $e');
                              accessToken = null;
                            }

                            if (idToken == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se pudo obtener idToken desde Google.',
                                  ),
                                ),
                              );
                              await googleSignIn.signOut();
                              setState(() {
                                _loadingGoogle = false;
                              });
                              return;
                            }

                            // Iniciar sesión en Supabase (crea/recupera sesión en Auth)
                            await supabase.auth.signInWithIdToken(
                              provider: OAuthProvider.google,
                              idToken: idToken,
                              accessToken: accessToken,
                            );

                            final supabaseUser = supabase.auth.currentUser;
                            final String email = account.email;

                            // Buscar si ya existe usuario en la tabla 'users'
                            final profile = await supabase
                                .from('users')
                                .select()
                                .eq('email', email)
                                .maybeSingle();
                            Map<String, dynamic>? userRow;

                            if (profile == null) {
                              // --- Usuario NO existe: crear fila en users y ASIGNAR contraseña ---
                              // Generar username base y candidato
                              String base = email
                                  .split('@')
                                  .first
                                  .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
                              if (base.isEmpty) base = 'user';
                              String username = base;
                              bool created = false;
                              int attempts = 0;

                              final Map<String, dynamic> candidate =
                                  <String, dynamic>{};

                              while (!created && attempts < 8) {
                                candidate.clear();
                                candidate.addAll({
                                  'email': email,
                                  'username': username,
                                  if (account.photoUrl != null &&
                                      account.photoUrl!.isNotEmpty)
                                    'avatar_url': account.photoUrl,
                                  if (account.id != null &&
                                      account.id!.isNotEmpty)
                                    'google_id': account.id,
                                  if (supabaseUser?.id != null)
                                    'supabase_id': supabaseUser!.id,
                                  // no incluimos campos NOT NULL con default (in_game_points, hints_count, etc.)
                                });

                                try {
                                  final inserted = await supabase
                                      .from('users')
                                      .insert(candidate)
                                      .select()
                                      .maybeSingle();
                                  if (inserted == null) {
                                    final fetched = await supabase
                                        .from('users')
                                        .select()
                                        .eq('email', email)
                                        .maybeSingle();
                                    if (fetched == null)
                                      throw Exception(
                                        'No se pudo crear/recuperar perfil en users.',
                                      );
                                    userRow = Map<String, dynamic>.from(
                                      fetched as Map,
                                    );
                                  } else {
                                    userRow = Map<String, dynamic>.from(
                                      inserted as Map,
                                    );
                                  }
                                  created = true;
                                } catch (e) {
                                  final errStr = e is PostgrestException
                                      ? (e.message?.toString() ?? e.toString())
                                      : e.toString();
                                  debugPrint(
                                    'Insert users attempt #$attempts failed: $errStr',
                                  );

                                  if (errStr.toLowerCase().contains('unique') ||
                                      errStr.toLowerCase().contains(
                                        'duplicate',
                                      ) ||
                                      errStr.toLowerCase().contains(
                                        'already exists',
                                      )) {
                                    // username duplicado -> generar sufijo y reintentar
                                    username =
                                        '$base${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
                                    attempts++;
                                    continue;
                                  }

                                  // si no podemos resolver, mostramos el error y salimos
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al crear perfil en Yachay: $errStr',
                                      ),
                                    ),
                                  );
                                  try {
                                    await googleSignIn.signOut();
                                  } catch (_) {}
                                  try {
                                    await supabase.auth.signOut();
                                  } catch (_) {}
                                  setState(() {
                                    _loadingGoogle = false;
                                  });
                                  return;
                                }
                              } // end while

                              if (!created) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo generar un username único. Intenta de nuevo.',
                                    ),
                                  ),
                                );
                                try {
                                  await googleSignIn.signOut();
                                } catch (_) {}
                                try {
                                  await supabase.auth.signOut();
                                } catch (_) {}
                                setState(() {
                                  _loadingGoogle = false;
                                });
                                return;
                              }

                              // --- SOLO AQUÍ GENERAMOS Y ASIGNAMOS LA CONTRASEÑA ---
                              final newPassword = _generateRandomPassword(12);

                              // 1) Actualizar la contraseña en Supabase Auth (para login con email+password)
                              try {
                                await supabase.auth.updateUser(
                                  UserAttributes(password: newPassword),
                                );
                              } catch (e) {
                                debugPrint(
                                  'Error actualizando password en Auth: $e',
                                );
                                // seguimos: intentaremos guardar la contraseña en la tabla users aunque updateUser falle
                              }

                              // 2) Guardar contraseña EN TEXTO PLANO en users.password_hash SOLO si acabo de crear al usuario
                              try {
                                if (userRow != null) {
                                  final uid = userRow['user_id'];
                                  if (uid != null) {
                                    await supabase
                                        .from('users')
                                        .update({'password_hash': newPassword})
                                        .eq('user_id', uid);
                                  } else {
                                    await supabase
                                        .from('users')
                                        .update({'password_hash': newPassword})
                                        .eq('email', email);
                                  }
                                }
                              } catch (e) {
                                debugPrint(
                                  'Error guardando password en texto plano: $e',
                                );
                              }

                              // Mostrar contraseña generada al usuario
                              await _showGeneratedPasswordDialog(newPassword);
                            } else {
                              // --- Usuario YA existe: NO tocar contraseña ni password_hash ---
                              userRow = Map<String, dynamic>.from(
                                profile as Map,
                              );
                              // Si necesitas, aquí puedes sincronizar supabase_id/google_id en la fila existente,
                              // pero SOLO haz updates no relacionados con password.
                            }

                            // Guardar sesión local y navegar (ambos casos)
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_logged', true);
                            if (userRow != null &&
                                (userRow['user_id'] is int)) {
                              await prefs.setInt(
                                'user_id',
                                userRow['user_id'] as int,
                              );
                            } else if (supabaseUser?.id != null) {
                              await prefs.setString(
                                'user_uuid',
                                supabaseUser!.id,
                              );
                            }

                            if (!mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const GameModeScreen(),
                              ),
                            );
                          } on GoogleSignInException catch (gse) {
                            debugPrint(
                              'GoogleSignInException: ${gse.code} ${gse.toString()}',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Google Sign-In cancelado o falló: ${gse.code ?? gse.toString()}',
                                ),
                              ),
                            );
                          } on PostgrestException catch (pe) {
                            final msg = pe.message?.toString() ?? pe.toString();
                            debugPrint('PostgrestException: $msg');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error en Yachay: $msg')),
                            );
                          } catch (e, st) {
                            debugPrint(
                              'Error Google Sign-In / Supabase: $e\n$st',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          } finally {
                            if (mounted)
                              setState(() {
                                _loadingGoogle = false;
                              });
                          }
                        },

                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      PaletadeColores.iconoNegro,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      PaletadeColores.textoB,
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: _loadingGoogle
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator.adaptive(),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/logo_GOOGLE.png",
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            const Text("Continuar con Google"),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                          builder: (context) => const SignupScreen(),
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
