import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/classic_mode_screen.dart';
import 'screens/timer_mode_screen.dart';
import 'screens/category_mode_screen.dart';
import 'screens/quick_mode_screen.dart';
import 'screens/daily_challenge_screen.dart';
import 'screens/perfil_screen.dart';

import 'package:flutter/services.dart';

import 'screens/leaderboard_screen.dart'; // Asegúrate de importar LeaderboardScreen
import 'screens/stats_screen.dart'; // Asegúrate de importar correctamente la pantalla de estadísticas
// import 'game_page.dart'; // eliminado porque no se usa aquí

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
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFF162936), // Transparente
        statusBarIconBrightness: Brightness.light, // Íconos blancos
      ),
    );
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

  final List<Widget> _screens = [
    StatsScreen(),
    PerfilScreen(),
    HomeContent(), // pantalla principal (actual contenido de game_mode)
    LeaderboardScreen(),
    Center(child: Text("⚙️ Ajustes próximamente")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _screens[_selectedIndex]), //cambia contenido
        ],
      ),
      // Navbar con efecto de "crecer" el ícono seleccionado
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Color(0xFF162936),
        selectedItemColor: Color(0xFF04D9B2),
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.bar_chart,
                size: _selectedIndex == 0 ? 35 : 24,
              ), // crece si seleccionado
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.person,
                size: _selectedIndex == 1 ? 35 : 24,
              ), // Perfil
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.home,
                color: _selectedIndex == 2 ? Color(0xFF04D9B2) : Colors.white,
                size: _selectedIndex == 2 ? 35 : 26,
              ), // Home dorado + grande
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.emoji_events,
                size: _selectedIndex == 3 ? 35 : 24,
              ),
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.settings, size: _selectedIndex == 4 ? 35 : 24),
            ),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF162936),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
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
                        "x5",
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
            Image.asset(
              "assets/images/logopeque.png",
              height: 40,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        const SizedBox(height: 12),
        const Text(
          "Selecciona el modo de juego",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF162936),
          ),
        ),
        const SizedBox(height: 0),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildImageButton(
                context,
                "assets/images/clasico.png",
                const ClasicoScreen(),
              ),
              _buildImageButton(
                context,
                "assets/images/contrareloj.png",
                const ContrarrelojScreen(),
              ),
              _buildImageButton(
                context,
                "assets/images/elegirCategoria.png",
                const CategoriaScreen(),
              ),
              _buildImageButton(
                context,
                "assets/images/partidaRapida.png",
                const QuickModeScreen(),
              ),
              _buildImageButton(
                context,
                "assets/images/dasafioDiario.png",
                const DailyChallengeScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildImageButton(
    BuildContext context,
    String imagePath,
    Widget nextScreen,
  ) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => nextScreen),
          );
        },
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
