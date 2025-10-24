import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Definición simple del modelo para un usuario en la clasificación
class LeaderboardUser {
  final int userId;
  final String username;
  final int score;
  final bool isCurrentUser;

  LeaderboardUser({
    required this.userId,
    required this.username,
    required this.score,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  int? currentUserId;
  // Se elimina la variable _selectedTab ya que solo hay una vista.

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Carga el ID del usuario actual desde SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id');
    });
  }

  // Helper para extraer la data de la respuesta de Supabase
  dynamic _extractData(dynamic resp) {
    if (resp is List) return resp;
    try {
      final d = resp.data;
      return d ?? [];
    } catch (_) {}
    if (resp is Map && resp.containsKey('data')) return resp['data'] ?? [];
    return [];
  }

  // =========================================================
  // FUNCIÓN CLAVE: Cargar el Ranking de AMIGOS
  // =========================================================
  Future<List<LeaderboardUser>> _loadFriendsLeaderboard() async {
    if (currentUserId == null) return [];

    try {
      // 1. Obtener TODAS las relaciones de amistad (sin filtro en Supabase)
      // Esto asegura que si hay un error en el parsing de Supabase, la respuesta no sea nula.
      final friendsResponse = await supabase
          .from('amistad')
          .select('user_id_1, user_id_2');

      // ✅ Extracción de datos forzada: Supabase debe devolver una List<Map<String, dynamic>>
      // Usamos el .data o la respuesta completa, forzando un List.
      final List<dynamic> friendsData = friendsResponse as List<dynamic>? ?? [];
      if (friendsData.isEmpty) {
        print("No se encontraron filas en la tabla amistad.");
      }
      // 2. Filtrar y mapear en Dart para encontrar las relaciones del usuario 25
      final friendIds = friendsData
          .where((row) {
            // Verifica que la fila contenga el ID del usuario actual
            final id1 = row['user_id_1'] as int;
            final id2 = row['user_id_2'] as int;
            return id1 == currentUserId || id2 == currentUserId;
          })
          .map((row) {
            // Extrae el ID del amigo (el que no es el usuario actual)
            final id1 = row['user_id_1'] as int;
            final id2 = row['user_id_2'] as int;
            return (id1 == currentUserId) ? id2 : id1;
          })
          .toList();
      // Agrega el propio ID a la lista para mostrar al usuario actual
      friendIds.add(currentUserId!);

      // ✅ DEBUGGING: Verifica qué IDs va a consultar
      print("IDs de amigos a consultar: $friendIds"); // <--- AÑADE ESTA LÍNEA

      if (friendIds.length == 1 && friendIds.first == currentUserId)
        return []; // Retorna vacío si solo está el usuario actual
      // 2. Obtener el score y username de esos IDs, ordenados por in_game_points
      final usersResponse = await supabase
          .from('users')
          .select('user_id, username, in_game_points')
          // Usamos .filter, ya que el .in_ te da problemas
          .filter('user_id', 'in', friendIds)
          .order('in_game_points', ascending: false);

      // ✅ Extracción de datos forzada para la tabla users
      final List<dynamic> leaderboardData = (usersResponse is List)
          ? usersResponse
          : (usersResponse as PostgrestResponse).data as List<dynamic>? ?? [];
      return leaderboardData.map((row) {
        final userId = row['user_id'] as int;
        return LeaderboardUser(
          userId: userId,
          username: row['username'] as String? ?? 'Usuario Desconocido',
          score: row['in_game_points'] as int? ?? 0,
          isCurrentUser: userId == currentUserId,
        );
      }).toList();
    } on PostgrestException catch (e) {
      // Imprime cualquier error de SQL o conexión
      print("Error de Supabase: ${e.message}");
      return [];
    } catch (e) {
      // Imprime cualquier otro error
      print("Error desconocido al cargar amigos: $e");
      return [];
    }
  }

  // =========================================================
  // WIDGETS DE CONSTRUCCIÓN DE LA UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        // ✅ NO USAR 'const' en Scaffold
        appBar: AppBar(
          title: const Text("Clasificación"), // ✅ Añadir 'const' al Text
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ), // ✅ Añadir 'const' al Center/Indicator
      );
    }

    // ✅ CAMBIO CLAVE: futureData ahora SIEMPRE llama a _loadFriendsLeaderboard()
    final Future<List<LeaderboardUser>> futureData = _loadFriendsLeaderboard();

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A3A),
      appBar: AppBar(
        // ✅ CORRECCIÓN DE CONST en AppBar
        title: const Text(
          "Tabla de clasificación de Amigos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A3A),
        elevation: 0,
        // Puedes añadir aquí el botón de "Amigos" o dejarlo implícito
      ),
      body: Column(
        children: [
          // ❌ Se eliminó _buildTabToggle()
          Expanded(
            child: Card(
              color: const Color(0xFF264A4A),
              margin: const EdgeInsets.all(12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: FutureBuilder<List<LeaderboardUser>>(
                  future: futureData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final users = snapshot.data ?? [];

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¡Aún no tienes amigos!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Comparte tu ID de usuario: $currentUserId',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildLeaderboardTile(user, index + 1);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Se eliminó _buildTabToggle()

  Widget _buildLeaderboardTile(LeaderboardUser user, int rank) {
    final bool isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: user.isCurrentUser
            ? const Color(0xFF385757)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: user.isCurrentUser
                ? const Icon(Icons.star, color: Colors.yellow, size: 28)
                : Text(
                    rank.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isTopThree
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isTopThree ? Colors.white : Colors.white70,
                    ),
                  ),
          ),
        ),
        title: Text(
          // Se usa el nombre real si no es el usuario actual, de lo contrario 'Tú'
          user.isCurrentUser ? 'Tú' : user.username,
          style: TextStyle(
            color: user.isCurrentUser ? Colors.white : Colors.white,
            fontWeight: user.isCurrentUser
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        trailing: Text(
          user.score.toString(),
          style: TextStyle(
            color: user.isCurrentUser ? const Color(0xFF1de9b6) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
