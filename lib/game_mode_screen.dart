import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/classic_mode_screen.dart';
import 'screens/timer_mode_screen.dart';
import 'screens/category_mode_screen.dart';
import 'screens/quick_mode_screen.dart';
import 'screens/daily_challenge_screen.dart';
import 'screens/perfil_screen.dart';

import 'screens/leaderboard_screen.dart'; // Asegúrate de importar LeaderboardScreen
import 'screens/stats_screen.dart'; // Asegúrate de importar correctamente la pantalla de estadísticas

class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  int? userId;
  int? userPoints;
  String? username;
  bool loadingPoints = true;

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null) {
      setState(() {
        userId = id;
      });
      // Consultar puntos y username en Supabase
      final userRow = await Supabase.instance.client
          .from('users')
          .select('in_game_points, username')
          .eq('user_id', id)
          .maybeSingle();
      setState(() {
        userPoints = userRow != null ? userRow['in_game_points'] as int? : null;
        username = userRow != null ? userRow['username'] as String? : null;
        loadingPoints = false;
      });
    } else {
      setState(() {
        loadingPoints = false;
      });
    }
  }

  // Método para manejar el cambio de índice en el BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Encabezado
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Colors.yellow,
                      size: 28,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        loadingPoints ? '...' : (userPoints?.toString() ?? '0'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage("assets/logo.png"),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loadingPoints ? '...' : (username ?? 'Usuario'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 26),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "5:00",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Icon(Icons.store, size: 36, color: Colors.teal),
                Icon(Icons.filter_2, size: 36, color: Colors.teal),
                Icon(Icons.fast_forward, size: 36, color: Colors.teal),
                Icon(Icons.search, size: 36, color: Colors.teal),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Selecciona el modo de juego",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildModeButton(
                  "Clásico",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClasicoScreen()),
                    );
                  },
                ),
                _buildModeButton(
                  "Contrarreloj",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ContrarrelojScreen(),
                      ),
                    );
                  },
                ),
                _buildModeButton(
                  "Elegir\ncategoría",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriaScreen(),
                      ),
                    );
                  },
                ),
                _buildModeButton(
                  "Partida\nrápida",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuickModeScreen(),
                      ),
                    );
                  },
                ),
                _buildModeButton(
                  "Desafío\ndiario",
                  icon: Icons.star,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyChallengeScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Lógica de navegación
          switch (index) {
            case 0:
              // Pantalla de estadísticas
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
              break;
            case 1:
              // Pantalla de tabla de clasificación
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
              break;
            case 2: //Perfil
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              );
              break;
            case 3:
              // Pantalla de inicio
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              );
              break;
            // Puedes agregar más si luego quieres que otros botones abran pantallas
          }
        },

        backgroundColor: Colors.black87,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 40, color: Colors.yellow),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
