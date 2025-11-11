import 'package:flutter/material.dart';
import 'package:yachay/core/app_colors.dart';
import 'package:yachay/screens/rellenar_espacio_en_Blanco.dart';
// import 'game_mode_screen.dart';
import 'screens/iniciar_secion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yachay/game_mode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xbdtenznssbragnduobc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZHRlbnpuc3NicmFnbmR1b2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwNzYxNDIsImV4cCI6MjA3MzY1MjE0Mn0.bZe5KFXKqx329uXdIL5Y7HDT3b-1uL3y_fatESptQqk',
  );
  final prefs = await SharedPreferences.getInstance();
  final isLogged = prefs.getBool('is_logged') ?? false;
  runApp(MyApp(isLoggedIn: isLogged));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({required this.isLoggedIn, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //title: 'Juego de Preguntas',
      title: 'Yachay Trivia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: PaletadeColores.fondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: isLoggedIn ? const GameModeScreen() : const ScreenIniciarSecion(),
    );
  }
}
