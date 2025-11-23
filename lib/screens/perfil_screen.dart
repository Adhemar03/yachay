import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yachay/core/achievements_service.dart';
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
  int? userId;
  String? avatarUrl;
  bool loading = true;
  bool _loadingLogout = false;

  final picker = ImagePicker();

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
      setState(() {
        userId = id; // ← guardamos el ID real para mostrarlo
      });
      final userRow = await Supabase.instance.client
          .from('users')
          .select('username, email, in_game_points, avatar_url')
          .eq('user_id', id)
          .maybeSingle();

      if (userRow != null) {
        setState(() {
          username = userRow['username'] as String?;
          email = userRow['email'] as String?;
          userPoints = userRow['in_game_points'] as int?;
          avatarUrl = userRow['avatar_url'] ?? 'assets/images/iconoPerfil.png';
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
    }
  }

  //  Editar perfil (nombre y foto)
  Future<void> _editarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) return;

    TextEditingController nameController = TextEditingController(
      text: username ?? '',
    );

    // Lista de avatares predefinidos
    final List<String> avatarOptions = [
      'assets/images/iconoPerfil.png',
      'assets/avatars/avatar1.png',
      'assets/avatars/avatar2.png',
      'assets/avatars/avatar3.png',
      'assets/avatars/avatar4.png',
      'assets/avatars/avatar5.png',
      'assets/avatars/avatar6.png',
      'assets/avatars/avatar7.png',
      'assets/avatars/avatar8.png',
      'assets/avatars/avatar9.png',
      'assets/avatars/avatar10.png',
    ];

    String selectedAvatar = avatarUrl ?? avatarOptions[0];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Editar perfil", textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cuadrícula de avatares con tamaño controlado
                      SizedBox(
                        height: 300,
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: avatarOptions.map((avatar) {
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedAvatar = avatar;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedAvatar == avatar
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Image.asset(
                                  avatar,
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client
                        .from('users')
                        .update({
                          'username': nameController.text,
                          'avatar_url': selectedAvatar,
                        })
                        .eq('user_id', id);

                    setState(() {
                      username = nameController.text;
                      avatarUrl = selectedAvatar;
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //Modal de confirmación para cerrar sesión
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

    // Reset local achievements (in-memory + persisted) so a new account
    // does not inherit the previous user's local unlocked achievements.
    try {
      await AchievementsService.instance.resetAll();
    } catch (_) {}

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

  // Tarjeta de información del usuario
  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF7A9DB0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de perfil
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: avatarUrl != null
                          ? (avatarUrl!.startsWith('assets')
                                ? AssetImage(avatarUrl!) as ImageProvider
                                : NetworkImage(avatarUrl!))
                          : const AssetImage('assets/images/iconoPerfil.png'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Datos del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.person_outline, username ?? '-'),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.email_outlined, email ?? '-'),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.credit_card,
                        userId?.toString() ?? '—',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botón Editar perfil
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFF7A00),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: TextButton(
              onPressed: _editarPerfil,
              child: const Text(
                "Editar perfil",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
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
                  Column(children: [_buildUserCard()]),

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
