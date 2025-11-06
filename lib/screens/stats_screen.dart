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

    // Obtener partidas jugadas del usuario
    final allGameSessionsResponse = await supabase
        .from('gamesessions')
        .select('final_score') // Selecciona todos los campos
        .eq('user_id', userId);

    final allGameSessionsData = _extractData(allGameSessionsResponse);
    final int gamesPlayed = (allGameSessionsData is List)
        ? allGameSessionsData.length
        : 0;

    // 3. Obtener el total de partidas 'correctas' (final_score >= 80)
    // Contar partidas con puntaje suficientemente alto como "correctas".
    // Usamos >= 80 para considerar partidas con al menos 80 puntos como acertadas.
    final correctAnswersResponse = await supabase
        .from('gamesessions')
        .select('final_score')
        .eq('user_id', userId)
        .gte('final_score', 80);

    // ✅ CORRECCIÓN CLAVE: Usamos _extractData para obtener la lista real de resultados
    final correctAnswersData = _extractData(correctAnswersResponse);
    final int totalCorrect = (correctAnswersData is List)
        ? correctAnswersData.length
        : 0;

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
      appBar: AppBar(title: const Text("Estadísticas")),
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
