import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // helper para extraer 'data' de distintas formas que puede devolver el cliente
  dynamic _extractData(dynamic resp) {
    if (resp is List || resp is Map) return resp;
    try {
      // algunos objetos tienen la propiedad .data
      final d = resp.data;
      return d;
    } catch (_) {}
    if (resp is Map && resp.containsKey('data')) return resp['data'];
    return resp; // ya es List/Map directo
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return {};

    final supabase = Supabase.instance.client;

    // Obtener el puntaje total del usuario
    final userRowResponse = await supabase
        .from('users')
        .select('in_game_points')
        .eq('user_id', userId);
    debugPrint('Raw userRowResponse: $userRowResponse');
    final userRowData = _extractData(userRowResponse);
    dynamic rawTotal = 0;
    if (userRowData is List && userRowData.isNotEmpty) {
      rawTotal = userRowData[0]['in_game_points'];
    } else if (userRowData is Map &&
        userRowData.containsKey('in_game_points')) {
      rawTotal = userRowData['in_game_points'];
    }
    final int totalScore = rawTotal is int
        ? rawTotal
        : int.tryParse(rawTotal?.toString() ?? '') ?? 0;

    // Obtener partidas jugadas del usuario usando la RPC `rpc_get_user_gamesessions`.
    // Esto evita problemas de RLS/policies porque la función está definida como
    // SECURITY DEFINER en el servidor (si fue desplegada desde sql/functions).
    List<dynamic> sessionsList = [];
    try {
      final rpcSessionsRes = await supabase
          .rpc(
            'rpc_get_user_gamesessions',
            params: {'p_user_id': userId, 'p_limit': 100},
          )
          .maybeSingle();
      debugPrint('rpc_get_user_gamesessions response: $rpcSessionsRes');
      final rpcData = _extractData(rpcSessionsRes);
      if (rpcData is Map && rpcData.containsKey('data')) {
        sessionsList = List<dynamic>.from(rpcData['data'] as List);
      } else if (rpcData is List) {
        sessionsList = List<dynamic>.from(rpcData);
      }
    } catch (e) {
      debugPrint('Error calling rpc_get_user_gamesessions: $e');
    }

    final int gamesPlayed = sessionsList.length;

    // 3. Contar partidas "correctas" (final_score >= 80) a partir de la lista obtenida
    int totalCorrect = 0;
    try {
      totalCorrect = sessionsList.where((s) {
        if (s is Map && s.containsKey('final_score')) {
          final v = s['final_score'];
          final score = v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
          return score >= 80;
        }
        return false;
      }).length;
    } catch (e) {
      debugPrint('Error parsing sessionsList for correct answers: $e');
      totalCorrect = 0;
    }

    // 4. Calcular porcentaje de aciertos
    final accuracy = gamesPlayed > 0 ? (totalCorrect / gamesPlayed) * 100 : 0.0;

    // Imprimir para depuración (Debugging)
    print("User ID: $userId");
    print("Partidas Jugadas (Total): $gamesPlayed");
    print("Partidas Correctas (>=80): $totalCorrect");
    print("Porcentaje de Aciertos: $accuracy%");

    return {
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'accuracy': double.parse(
        accuracy.toStringAsFixed(2),
      ), // Redondea a 2 decimales
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text("Estadísticas")),
      backgroundColor: const Color(0xFFFFFFFF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Estadísticas de tu progreso",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.teal[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(
                      Icons.star,
                      size: 40,
                      color: Colors.yellow,
                    ),
                    title: const Text(
                      "Partidas jugadas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${data['gamesPlayed'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.teal[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(
                      Icons.percent,
                      size: 40,
                      color: Colors.green,
                    ),
                    title: const Text(
                      "Porcentaje de aciertos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        CircularProgressIndicator(
                          value: (data['accuracy'] ?? 0) / 100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${data['accuracy']}%",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.teal[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(
                      Icons.emoji_events,
                      size: 40,
                      color: Colors.yellow,
                    ),
                    title: const Text(
                      "Puntaje total",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${data['totalScore'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
