import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:yachay/game_mode_screen.dart';
import 'iniciar_secion.dart';
import 'package:yachay/core/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  Future<bool> _usuarioOCorreoExiste(String username, String email) async {
    final response = await Supabase.instance.client
        .from('users')
        .select('user_id')
        .or('username.eq.$username,email.eq.$email')
        .maybeSingle();
    return response != null;
  }

  bool _isLoading = false;
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;
  String? _successMessage;
  final RegExp _emailRegex = RegExp(r'^[\w\-.]+@[\w\-.]+\.[a-zA-Z]{2,}$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔹 Imagen principal (mismo alto y separación que login)
              Image.asset('assets/images/logoV1.png', height: 240),

              const SizedBox(height: 6),
              Text(
                'Únete a nosotros',
                style: TextStyle(
                  color: PaletadeColores.secundario,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 18),
                child: Text(
                  'Crea tu cuenta gratis, guarda tu avance, \ngana logros y compite en la trivia \ncultural de Bolivia.',
                  style: TextStyle(color: PaletadeColores.textoB, fontSize: 14),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),

              // 🔹 Campo: Nombre de usuario
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: PaletadeColores.textoB,
                    hintText: 'Nombre de usuario',
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: PaletadeColores.iconoNegro,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF162936)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su nombre';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),
              // 🔹 Campo: Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: PaletadeColores.textoB,
                    hintText: 'correoelectronico@gmail.com',
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.email,
                        size: 30,
                        color: PaletadeColores.iconoNegro,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF162936)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su correo';
                    }
                    if (!_emailRegex.hasMatch(value)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),
              // 🔹 Campo: Contraseña
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: PaletadeColores.textoB,
                    hintText: 'contraseña',
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
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        color: PaletadeColores.iconoNegro,
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF162936)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: PaletadeColores.error),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              ],

              const SizedBox(height: 24),

              // 🔹 Botón: Registrarse
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 25,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              final name = _nameController.text.trim();
                              final existe = await _usuarioOCorreoExiste(
                                name,
                                email,
                              );

                              if (existe) {
                                setState(() {
                                  _errorMessage =
                                      'El usuario o correo ya está registrado.';
                                  _successMessage = null;
                                  _isLoading = false;
                                });
                                return;
                              }

                              final result = await _authService.signUp(
                                email,
                                password,
                                name,
                              );

                              if (result == null) {
                                final userRow = await Supabase.instance.client
                                    .from('users')
                                    .select('user_id')
                                    .eq('email', email)
                                    .maybeSingle();

                                if (userRow != null &&
                                    userRow['user_id'] != null) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('is_logged', true);
                                  await prefs.setInt(
                                    'user_id',
                                    userRow['user_id'] as int,
                                  );
                                }

                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const GameModeScreen(),
                                    ),
                                  );
                                }
                              } else {
                                setState(() {
                                  _errorMessage = _traducirError(result);
                                  _successMessage = null;
                                });
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
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
                    child: _isLoading
                        ? const CircularProgressIndicator.adaptive()
                        : const Text("Registrarse"),
                  ),
                ),
              ),

              // 🔹 Botón: Cancelar
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 25,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const ScreenIniciarSecion(),
                              ),
                            );
                          },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.black),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔹 Enlace: Ya tienes cuenta
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(
                        color: PaletadeColores.textoB,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ScreenIniciarSecion(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: PaletadeColores.secundario,
                      ),
                      child: const Text(
                        "Inicia sesión",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _traducirError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('already') ||
        lower.contains('exists') ||
        lower.contains('ya existe')) {
      return 'El correo ya está registrado.';
    }
    if (lower.contains('invalid email') ||
        lower.contains('email address is invalid') ||
        lower.contains('correo no es válido')) {
      return 'El correo no es válido.';
    }
    if (lower.contains('network')) {
      return 'Error de red. Intenta nuevamente.';
    }
    if (lower.contains('rate limit')) {
      return 'Demasiados intentos. Intenta más tarde.';
    }
    return error;
  }
}
