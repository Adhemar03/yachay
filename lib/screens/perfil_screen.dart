import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'iniciar_secion.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? username;
  String? email;
  int? userPoints;
  String? avatarUrl;
  bool loading = true;
  bool _loadingLogout = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');

    if (id != null) {
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
                      _buildInfoRow(Icons.credit_card, '1293782'),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Contenido superior
                  Column(children: [_buildUserCard()]),

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
}
