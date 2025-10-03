import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Registro de usuario con Supabase
  Future<String?> signUp(String email, String password, String name) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user != null) {
        // Insertar en la tabla personalizada Users
        final userId = response.user!.id;
        final insertResponse = await supabase.from('users').insert({
          'supabase_id': userId,
          'username': name,
          'email': email,
          // Otros campos pueden ir con valores por defecto
        }).select();
        // Si la respuesta es una lista vacía, hubo un error
        if (insertResponse.isEmpty) {
          return 'Error al guardar en tabla users.';
        }
        return null; // null = sin error
      } else if (response.session == null) {
        // Puede requerir verificación de email
        return 'Revisa tu correo para verificar tu cuenta.';
      }
      return 'Error desconocido';
    } on AuthException catch (e) {
      return e.message;
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
