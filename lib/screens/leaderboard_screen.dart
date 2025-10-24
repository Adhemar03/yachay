import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yachay/core/app_colors.dart';

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

  /// >>> CAMBIO AÑADIDO: PESTAÑA POR DEFECTO CAMBIADA A 'general'
  /// Ahora al ingresar la vista por defecto es la pestaña "General".
  String _selectedTab = 'general';

  /// <<< FIN CAMBIO AÑADIDO

  /// >>> CAMBIO AÑADIDO: FILTRO DE FECHA PARA LA VISTA 'GENERAL'
  /// Valores: 'general' (todo), 'mes' (último mes), 'dia' (hoy)
  String _selectedDateFilter = 'general';

  /// <<< FIN CAMBIO AÑADIDO

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

  /// >>> CAMBIO AÑADIDO: FUNCIÓN UNIFICADA PARA CARGAR RANKING GENERAL CON FILTRO DE FECHA
  /// - Si dateFilter == 'general' => ranking por users.in_game_points (todo el tiempo)
  /// - Si dateFilter == 'mes' => suma de gamesessions.final_score desde inicio del mes
  /// - Si dateFilter == 'dia' => suma de gamesessions.final_score desde inicio del día
  Future<List<LeaderboardUser>> _loadGeneralLeaderboard({
    String dateFilter = 'general',
  }) async {
    try {
      if (dateFilter == 'general') {
        // Comportamiento original: usar users.in_game_points
        final usersResponse = await supabase
            .from('users')
            .select('user_id, username, in_game_points')
            .order('in_game_points', ascending: false);

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
      } else {
        // dateFilter == 'mes' o 'dia' -> agregamos sessions por periodo y luego buscamos usernames
        final now = DateTime.now().toUtc();
        DateTime start;
        if (dateFilter == 'mes') {
          start = DateTime.utc(now.year, now.month, 1);
        } else {
          // 'dia'
          start = DateTime.utc(now.year, now.month, now.day);
        }

        // Obtener sessions desde 'start'
        final sessionsResponse = await supabase
            .from('gamesessions')
            .select('user_id, final_score, created_at')
            .gte('created_at', start.toIso8601String());

        final List<dynamic> sessions = sessionsResponse as List<dynamic>? ?? [];

        // Agregación en Dart por user_id
        final Map<int, int> totals = {};
        for (var row in sessions) {
          // Manejo robusto de tipos (puede venir como String o int según supabase)
          final rawUserId = row['user_id'];
          final rawScore = row['final_score'];
          final int userId = (rawUserId is int)
              ? rawUserId
              : int.parse(rawUserId.toString());
          final int score = (rawScore is int)
              ? rawScore
              : int.parse(rawScore.toString());
          totals[userId] = (totals[userId] ?? 0) + score;
        }

        if (totals.isEmpty) return [];

        // Obtener usernames para los userIds resultantes
        final userIds = totals.keys.toList();
        final usersResponse = await supabase
            .from('users')
            .select('user_id, username')
            .filter('user_id', 'in', userIds);

        final List<dynamic> usersData = usersResponse as List<dynamic>? ?? [];

        // Map userId -> username
        final Map<int, String> usernameMap = {};
        for (var row in usersData) {
          final rawUserId = row['user_id'];
          final int userId = (rawUserId is int)
              ? rawUserId
              : int.parse(rawUserId.toString());
          usernameMap[userId] =
              row['username'] as String? ?? 'Usuario Desconocido';
        }

        // Construir lista ordenada por score (desc)
        final List<LeaderboardUser> list = totals.entries.map((e) {
          final uid = e.key;
          return LeaderboardUser(
            userId: uid,
            username: usernameMap[uid] ?? 'Usuario Desconocido',
            score: e.value,
            isCurrentUser: uid == currentUserId,
          );
        }).toList();

        list.sort((a, b) => b.score.compareTo(a.score));
        return list;
      }
    } on PostgrestException catch (e) {
      print("Error de Supabase (general con filtro): ${e.message}");
      return [];
    } catch (e) {
      print("Error desconocido al cargar general (filtro): $e");
      return [];
    }
  }

  /// <<< FIN CAMBIO AÑADIDO

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

    /// >>> CAMBIO AÑADIDO: SELECCIÓN DEL FUTURE SEGÚN PESTAÑA Y FILTRO
    /// Si estamos en 'amigos' usamos la lógica original _loadFriendsLeaderboard()
    /// Si estamos en 'general' llamamos a _loadGeneralLeaderboard(dateFilter: _selectedDateFilter)
    final Future<List<LeaderboardUser>> futureData = (_selectedTab == 'amigos')
        ? _loadFriendsLeaderboard()
        : _loadGeneralLeaderboard(dateFilter: _selectedDateFilter);

    /// <<< FIN CAMBIO AÑADIDO

    return Scaffold(
      backgroundColor: PaletadeColores.textoB,

      body: Column(
        children: [
          /// >>> CAMBIO AÑADIDO: FILA DE BOTONES (GENERAL | AMIGOS)
          /// Aquí se encuentran los dos botones que alternan la vista.
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
              left: 25,
              right: 25,
              bottom: 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedTab != 'general') {
                        setState(() {
                          _selectedTab = 'general';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'general'
                          ? PaletadeColores.secundario
                          : PaletadeColores.fondo,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fixedSize: const Size(
                        120,
                        40,
                      ), // <-- ancho x alto fijos del botón
                      textStyle: const TextStyle(
                        fontSize: 21,
                      ), // tamaño por defecto del texto
                    ),
                    child: Text(
                      'Global',
                      style: TextStyle(
                        color: _selectedTab == 'general'
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: _selectedTab == 'general'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedTab != 'amigos') {
                        setState(() {
                          _selectedTab = 'amigos';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'amigos'
                          ? PaletadeColores.secundario
                          : PaletadeColores.fondo,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fixedSize: const Size(
                        120,
                        40,
                      ), // <-- ancho x alto fijos del botón
                      textStyle: const TextStyle(
                        fontSize: 21,
                      ), // tamaño por defecto del texto
                    ),
                    child: Text(
                      'Amigos',
                      style: TextStyle(
                        color: _selectedTab == 'amigos'
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: _selectedTab == 'amigos'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// <<< FIN CAMBIO AÑADIDO: FILA DE BOTONES

          /// >>> CAMBIO AÑADIDO: FILA DE BOTONES DE FILTRO DE FECHA (SOLO VISIBLE EN 'GENERAL')
          if (_selectedTab == 'general')
            Padding(
              padding: const EdgeInsets.only(
                left: 25,
                right: 25,
                bottom: 0,
                top: 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (_selectedDateFilter != 'general') {
                          setState(() {
                            _selectedDateFilter = 'general';
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedDateFilter == 'general'
                            ? PaletadeColores.secundario
                            : PaletadeColores.fondo,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fixedSize: const Size(
                          120,
                          40,
                        ), // <-- ancho x alto fijos del botón
                        textStyle: const TextStyle(fontSize: 17), // tamañ
                      ),
                      child: Text(
                        'General',
                        style: TextStyle(
                          color: _selectedDateFilter == 'general'
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: _selectedDateFilter == 'general'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (_selectedDateFilter != 'mes') {
                          setState(() {
                            _selectedDateFilter = 'mes';
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedDateFilter == 'mes'
                            ? PaletadeColores.secundario
                            : PaletadeColores.fondo,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fixedSize: const Size(
                          120,
                          40,
                        ), // <-- ancho x alto fijos del botón
                        textStyle: const TextStyle(fontSize: 17),
                      ),
                      child: Text(
                        'Mes',
                        style: TextStyle(
                          color: _selectedDateFilter == 'mes'
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: _selectedDateFilter == 'mes'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (_selectedDateFilter != 'dia') {
                          setState(() {
                            _selectedDateFilter = 'dia';
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedDateFilter == 'dia'
                            ? PaletadeColores.secundario
                            : PaletadeColores.fondo,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fixedSize: const Size(
                          120,
                          40,
                        ), // <-- ancho x alto fijos del botón
                        textStyle: const TextStyle(fontSize: 17),
                      ),
                      child: Text(
                        'Día',
                        style: TextStyle(
                          color: _selectedDateFilter == 'dia'
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: _selectedDateFilter == 'dia'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(
              left: 25,
              right: 25,
              bottom: 5,
              top: 10,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PaletadeColores.fondo,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.zero,
                ),
              ),
              child: const Text(
                "Tabla de Clasificación",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          /// <<< FIN CAMBIO AÑADIDO: FILA DE BOTONES DE FILTRO DE FECHA

          // ❌ Se eliminó _buildTabToggle()
          Expanded(
            child: Card(
              color: PaletadeColores.fondo,
              margin: const EdgeInsets.only(
                top: 0,
                left: 25,
                right: 25,
                bottom: 25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
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
                      // >>> CAMBIO AÑADIDO: MENSAJE VACÍO DIFERENCIADO
                      // ahora muestra texto distinto si estás en "amigos" o "general"
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedTab == 'amigos'
                                  ? '¡Aún no tienes amigos!'
                                  : '¡Aún no hay usuarios en la clasificación!',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTab == 'amigos'
                                  ? 'Comparte tu ID de usuario: $currentUserId'
                                  : 'Se el primero en la tabla',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                      // <<< FIN CAMBIO AÑADIDO
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
    final bool isTopThree = rank == 3;
    //Agregarciones
    final bool isTopOne = rank == 1;
    final bool isTopTwo = rank == 2;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: user.isCurrentUser ? const Color(0xFF385757) : Color(0xFF183548),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: user.isCurrentUser
                ? Container(
                    width: 35,
                    height: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isTopOne
                          ? const Color(0xFFFFD700) // color oro
                          : isTopTwo
                          ? const Color(0xFFC0C0C0) // color plata
                          : isTopThree
                          ? const Color(
                              0xFFCD7F32,
                            ) // leve tono para top3 (opcional)
                          : const Color(0xFF939393), // sin fondo en los demás
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : Container(
                    width: 35,
                    height: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isTopOne
                          ? const Color(0xFFFFD700) // color oro
                          : isTopTwo
                          ? const Color(0xFFC0C0C0) // color plata
                          : isTopThree
                          ? const Color(
                              0xFFCD7F32,
                            ) // leve tono para top3 (opcional)
                          : const Color(0xFF939393), // sin fondo en los demás
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // menos redondeado
                      border: Border.all(
                        color: isTopOne
                            ? Colors.transparent
                            : Colors.white12, // borde sutil si no es oro
                        width: 1,
                      ),
                    ),
                    child: Text(
                      rank.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // texto normal blanco
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          // Se usa el nombre real si no es el usuario actual, de lo contrario 'Tú'
          user.isCurrentUser ? 'Tú' : user.username,
          style: TextStyle(
            color: user.isCurrentUser ? Color(0xFF00FFEA) : Color(0xFF00FFEA),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          user.score.toString(),
          style: TextStyle(
            color: user.isCurrentUser
                ? const Color(0xFF00FFEA)
                : Color(0xFF00FFEA),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
