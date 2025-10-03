import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xbdtenznssbragnduobc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZHRlbnpuc3NicmFnbmR1b2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwNzYxNDIsImV4cCI6MjA3MzY1MjE0Mn0.bZe5KFXKqx329uXdIL5Y7HDT3b-1uL3y_fatESptQqk',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yachay Trivia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF162936),
          primary: const Color(0xFF162936),
        ),
        scaffoldBackgroundColor: const Color(0xFF162936),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF162936),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF162936),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
