import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/achievements_service.dart';
import '../core/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      await AchievementsService.instance.syncUserAchievements(userId);
    }
    final list = await AchievementsService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        backgroundColor: const Color(0xFF1F3240),
      ),
      backgroundColor: const Color(0xFF111921),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, idx) {
                final a = _items[idx];
                return ListTile(
                  leading: a.iconUrl != null
                      ? SizedBox(
                          width: 40,
                          height: 40,
                          child: Builder(builder: (ctx) {
                            // si el icono parece ser un asset local usamos Image.asset
                            final icon = a.iconUrl!;
                            if (icon.startsWith('http')) {
                              return Image.network(icon, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: Colors.amber));
                            }
                            // intentar cargar desde assets/ si existe (si no, fallback a Icon)
                            try {
                              return Image.asset('assets/$icon', fit: BoxFit.cover);
                            } catch (_) {
                              return Icon(a.unlocked ? Icons.emoji_events : Icons.lock, color: a.unlocked ? Colors.amber : Colors.white54);
                            }
                          }),
                        )
                      : Icon(
                          a.unlocked ? Icons.emoji_events : Icons.lock,
                          color: a.unlocked ? Colors.amber : Colors.white54,
                        ),
                  title: Text(a.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.description, style: const TextStyle(color: Colors.white70)),
                      if (a.unlockedAt != null)
                        Text('Desbloqueado: ${a.unlockedAt}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemCount: _items.length,
            ),
    );
  }
}
