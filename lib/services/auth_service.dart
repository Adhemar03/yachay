import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Registro directo en la tabla users
  Future<String?> signUp(String email, String password, String name) async {
    try {
      final insertResponse = await supabase.from('users').insert({
        'username': name,
        'email': email,
        'password_hash': password, // Para pruebas, igual que login
        // Los demás campos usan valores por defecto
      }).select();
      if (insertResponse.isEmpty) {
        return 'Error al guardar en tabla users.';
      }
      return null; // null = sin error
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Inicio de sesión con Supabase
  Future<String?> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return null; // null = sin error
      }
      return 'Error desconocido';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error: $e';
    }
  }
}
