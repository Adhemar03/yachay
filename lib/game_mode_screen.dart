import 'package:flutter/material.dart';
import 'screens/classic_mode_screen.dart';
import 'screens/timer_mode_screen.dart';
import 'screens/category_mode_screen.dart';
import 'screens/quick_mode_screen.dart';
import 'screens/daily_challenge_screen.dart';

class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key});

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
                    const Icon(Icons.attach_money, color: Colors.yellow, size: 28),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "150",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: const [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage("assets/logo.png"),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "YACHAY",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 26),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "5:00",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildModeButton("Clásico", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ClasicoScreen()));
                }),
                _buildModeButton("Contrarreloj", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ContrarrelojScreen()));
                }),
                _buildModeButton("Elegir\ncategoría", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriaScreen()));
                }),
                _buildModeButton("Partida\nrápida", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickModeScreen()));
                }),
                _buildModeButton("Desafío\ndiario", icon: Icons.star, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyChallengeScreen()));
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
