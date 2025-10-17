import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:yachay/game_mode_screen.dart';
import 'iniciar_secion.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
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
      appBar: null,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/LogoYachay.png', height: 90),
                  const SizedBox(height: 24),
                  Text(
                    'YACHAY',
                    style: TextStyle(
                      color: Color(0xFF00FFEA),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu cuenta gratis, guarda tu avance, gana logros y compite en la trivia cultural de Bolivia.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person, color: Color(0xFF162936)),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: const TextStyle(color: Color(0xFF162936)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email, color: Color(0xFF162936)),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: const TextStyle(color: Color(0xFF162936)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF162936)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Color(0xFF162936),
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: const TextStyle(color: Color(0xFF162936)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF162936)),
                    obscureText: !_showPassword,
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
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFEA),
                        foregroundColor: const Color(0xFF162936),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });
                                final email = _emailController.text.trim();
                                final password = _passwordController.text
                                    .trim();
                                final name = _nameController.text.trim();
                                // Validar si ya existe username o email
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
                                  // Registro exitoso, buscar el user_id y guardar sesión
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF162936),
                                ),
                              ),
                            )
                          : const Text('Registrarse'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              //Navigator.pushReplacementNamed(context, '/login');
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ScreenIniciarSecion(),
                                ),
                              );
                            },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          //Navigator.pushNamed(context, '/login');
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const ScreenIniciarSecion(),
                            ),
                          );
                        },
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: Color(0xFF00FFEA),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
