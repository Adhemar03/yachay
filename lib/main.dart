import 'package:flutter/material.dart';
// import 'game_mode_screen.dart';
import 'screens/iniciar_secion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  await Supabase.initialize(
    url: 'https://xbdtenznssbragnduobc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZHRlbnpuc3NicmFnbmR1b2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwNzYxNDIsImV4cCI6MjA3MzY1MjE0Mn0.bZe5KFXKqx329uXdIL5Y7HDT3b-1uL3y_fatESptQqk',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juego de Preguntas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const ScreenIniciarSecion(),
    );
  }
}
