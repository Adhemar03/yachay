import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'iniciar_secion.dart';
import 'package:yachay/core/app_colors.dart';

/// >>> CAMBIO AÑADIDO: MODELO DE DATOS PARA LOGROS (coincide con tabla 'achievements')
class Achievement {
  final int id; // mapeará achievement_id
  final String title; // mapeará name
  final String description;
  final String iconUrl;
  final int reward; // tu esquema actual no tiene reward -> lo dejamos 0
  final bool completed; // true si existe una fila en userachievements

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.reward,
    required this.completed,
  });
}

/// >>> FIN DEL CAMBIO AÑADIDO

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? username;
  String? email;
  int? userPoints;
  bool loading = true;
  bool _loadingLogout = false;

  /// >>> CAMBIO AÑADIDO: LISTA DE LOGROS CARGADOS DESDE LA BD
  List<Achievement> _achievements = [];

  /// >>> CAMBIO AÑADIDO: ESTADO LOCAL DE PRESIONADO (UI sólo por ahora)
  /// Key: achievement id -> value: pressed (apagar visual)
  /// >>> FIN DEL CAMBIO AÑADIDO

  @override
  void initState() {
    super.initState();
    _loadUser();
    // >>> CAMBIO AÑADIDO: Cargar logros al iniciar (llamamos desde init)
    _loadAchievements();
    // >>> FIN DEL CAMBIO AÑADIDO
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');

    if (id != null) {
      final userRow = await Supabase.instance.client
          .from('users')
          .select('username, email, in_game_points')
          .eq('user_id', id)
          .maybeSingle();

      if (userRow != null) {
        setState(() {
          username = userRow['username'] as String?;
          email = userRow['email'] as String?;
          userPoints = userRow['in_game_points'] as int?;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
    }
  }

  // >>> CAMBIO AÑADIDO: INICIO - Carga de logros (consulta achievements y userachievements)
  Future<void> _loadAchievements() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final client = Supabase.instance.client;

      final dynamic resAchRaw = await client
          .from('achievements')
          .select('achievement_id, name, description, icon_url')
          .order('achievement_id', ascending: true);

      List<dynamic> _normalizeToList(dynamic raw) {
        if (raw == null) return [];
        if (raw is List) return List<dynamic>.from(raw);
        if (raw is Map && raw['data'] is List) {
          return List<dynamic>.from(raw['data'] as List);
        }
        try {
          final dynamic possibleData = (raw as dynamic).data;
          if (possibleData is List) return List<dynamic>.from(possibleData);
        } catch (_) {}
        if (raw is Iterable) return List<dynamic>.from(raw);
        return [];
      }

      final List<dynamic> rows = _normalizeToList(resAchRaw);

      final Set<int> earnedIds = {};
      if (userId != null) {
        final dynamic resUserAchRaw = await client
            .from('userachievements')
            .select('achievement_id')
            .eq('user_id', userId);

        final List<dynamic> userAchRows = _normalizeToList(resUserAchRaw);

        for (final r in userAchRows) {
          if (r is Map) {
            final dynamic mid = r['achievement_id'] ?? r['achievementId'];
            if (mid is int)
              earnedIds.add(mid);
            else if (mid is String) {
              final parsed = int.tryParse(mid);
              if (parsed != null) earnedIds.add(parsed);
            } else if (mid != null) {
              final parsed = int.tryParse(mid.toString());
              if (parsed != null) earnedIds.add(parsed);
            }
          } else {
            final parsed = int.tryParse(r.toString());
            if (parsed != null) earnedIds.add(parsed);
          }
        }
      }

      final List<Achievement> loaded = [];
      for (var r in rows) {
        if (r == null) continue;
        if (r is! Map) {
          try {
            final parsed = (r as dynamic);
            if (parsed is Map)
              r = parsed;
            else
              continue;
          } catch (_) {
            continue;
          }
        }
        final row = r as Map<String, dynamic>;

        final dynamic rawAid =
            row['achievement_id'] ?? row['achievementId'] ?? row['id'];
        final int aid = (rawAid is int)
            ? rawAid
            : (rawAid is String
                  ? int.tryParse(rawAid) ?? 0
                  : int.tryParse(rawAid.toString()) ?? 0);

        final String name =
            (row['name'] ?? row['titulo'] ?? '')?.toString() ?? '';
        final String desc =
            (row['description'] ?? row['descripcion'] ?? '')?.toString() ?? '';
        final String icon =
            (row['icon_url'] ?? row['iconUrl'] ?? row['icono'] ?? '')
                ?.toString() ??
            '';
        final bool completed = earnedIds.contains(aid);

        if (aid <= 0) continue;

        loaded.add(
          Achievement(
            id: aid,
            title: name,
            description: desc,
            iconUrl: icon,
            reward: 0,
            completed: completed,
          ),
        );
      }

      setState(() {
        _achievements = loaded;
        loading = false;
      });
    } catch (e) {
      setState(() {
        _achievements = [];
        loading = false;
      });
      // ignore: avoid_print
      print('Error en _loadAchievements: $e');
    }
  }
  // >>> CAMBIO AÑADIDO: FIN - Carga de logros (consulta achievements y userachievements)

  Future<void> _confirmLogout() async {
    final bool? confirmar = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            "¿Cerrar sesión?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        content: const Text(
          "Estás a punto de cerrar tu sesión.\n¿Deseas continuar?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            height: 42,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.grey.shade400,
                ),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              child: const Text("Cancelar"),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            height: 42,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              child: const Text("Aceptar"),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _logout();
    }
  }

  Future<void> _logout() async {
    setState(() => _loadingLogout = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Supabase.instance.client.auth.signOut();

    setState(() => _loadingLogout = false);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ScreenIniciarSecion()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      //appBar: AppBar(
      //backgroundColor: Colors.black87,
      //title: const Text(
      //"Perfil de usuario",
      //style: TextStyle(color: Colors.white),
      //),
      //iconTheme: const IconThemeData(color: Colors.white),
      //),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Contenido superior
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage("assets/logo.png"),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        username ?? '-',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        email ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Puntos: ${userPoints ?? 0}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16), // separación controlada
                  //Logros

                  // >>> CAMBIO AÑADIDO: INICIO - Reemplazo de fila de botones por encabezado "Logros"
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 3,
                      right: 3,
                      bottom: 1,
                      top: 1,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PaletadeColores.secundario,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Logros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // >>> CAMBIO AÑADIDO: FIN - Reemplazo de fila de botones por encabezado "Logros"
                  const SizedBox(height: 1),

                  // Área central que puede scrollear y ocupa el espacio restante
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: SizedBox(
                      height: 255,
                      child: Card(
                        color: PaletadeColores.fondo,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        clipBehavior: Clip
                            .hardEdge, // importante: recorta contenido a las esquinas
                        child: _achievements.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay logros disponibles',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  top: 2,
                                ), // <- AQUI: eliminar padding del ListView
                                itemCount: _achievements.length,
                                itemBuilder: (context, index) {
                                  final a = _achievements[index];
                                  return _buildCasillaLogros(a);
                                },
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),
                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loadingLogout ? null : _confirmLogout,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.red.shade700;
                              }
                              return Colors.red;
                            }),
                        foregroundColor: MaterialStateProperty.all<Color>(
                          Colors.white,
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                      ),
                      child: _loadingLogout
                          ? const CircularProgressIndicator.adaptive(
                              backgroundColor: Colors.white,
                            )
                          : const Text(
                              "Cerrar Sesión",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // >>> CAMBIO AÑADIDO: INICIO - Casilla de logro (corrección de colores para distinguir interior/ exterior)
  Widget _buildCasillaLogros(Achievement achievement) {
    final bool completed = achievement.completed;

    // Colores ajustados: fondo exterior neutro, rectángulo interior coloreado solo si completed==true
    final Color leftCircleColor = completed
        ? const Color(0xFFFFD700)
        : Colors.grey.shade500;

    final Color rectColor = completed
        ? PaletadeColores.fondo
        : Colors.grey.shade600;
    final double textOpacity = completed ? 1.0 : 0.6;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
      decoration: BoxDecoration(
        // Fondo exterior neutro para que el rectángulo interior destaque
        color: completed ? PaletadeColores.secundario : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: leftCircleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: achievement.iconUrl.isNotEmpty
                    ? Opacity(
                        opacity: textOpacity,
                        child: Image.network(
                          achievement.iconUrl,
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.emoji_events);
                          },
                        ),
                      )
                    : const Icon(Icons.emoji_events),
              ),
            ),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Container(
              height: 85,
              padding: const EdgeInsets.only(right: 12, left: 12),
              decoration: BoxDecoration(
                color:
                    rectColor, // este es el que cambia para indicar cumplido / no cumplido
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: textOpacity,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(
                              achievement.title,
                              style: TextStyle(
                                color: PaletadeColores.textoB,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Opacity(
                          opacity: textOpacity,
                          child: Text(
                            achievement.description.isNotEmpty
                                ? achievement.description
                                : 'Sin descripción',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 2.5),
        ],
      ),
    );
  }
}
