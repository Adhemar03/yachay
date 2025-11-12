import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'achievement.dart';

class AchievementsService {
  AchievementsService._private();

  static final AchievementsService instance = AchievementsService._private();

  static const _prefsKey = 'yachay_achievements_unlocked_map_v1';

  // Definiciones de logros disponibles (id está en snake_case)
  // NOTA: no usar `const` aquí porque actualizamos las definiciones desde la BD
  // en tiempo de ejecución (cargando dbId/iconUrl). Necesitamos una lista
  // mutable.
  final List<Achievement> _definitions = [
  Achievement(id: 'primer_paso', title: 'Primer Paso', description: 'Juega tu primera partida.'),
    // Racha Perfecta (tiers)
    Achievement(id: 'racha_5', title: 'Racha Perfecta - Bronce', description: '5 respuestas seguidas.'),
    Achievement(id: 'racha_10', title: 'Racha Perfecta - Plata', description: '10 respuestas seguidas.'),
    Achievement(id: 'racha_20', title: 'Racha Perfecta - Oro', description: '20 respuestas seguidas.'),
    Achievement(id: 'racha_50', title: 'Racha Perfecta - Diamante', description: '50 respuestas seguidas.'),
    // Reflejos
    Achievement(id: 'reflejos_5', title: 'Reflejos de rayo', description: '5 respuestas correctas en menos de 3 segundos seguidas.'),
  // Uso de poderes (logros simples)
  Achievement(id: 'used_fifty', title: '50/50 usado', description: 'Utiliza el poder 50/50 por primera vez.'),
  Achievement(id: 'used_auto', title: 'Auto-respuesta usada', description: 'Utiliza la auto-respuesta por primera vez.'),
    // Constante Aprendiz (tiers)
    Achievement(id: 'constante_5', title: 'Constante Aprendiz - Bronce', description: '5 días seguidos.'),
    Achievement(id: 'constante_10', title: 'Constante Aprendiz - Plata', description: '10 días seguidos.'),
    Achievement(id: 'constante_20', title: 'Constante Aprendiz - Oro', description: '20 días seguidos.'),
    Achievement(id: 'constante_50', title: 'Constante Aprendiz - Diamante', description: '50 días seguidos.'),
    // Conquistador de Categorías
    Achievement(id: 'conquistador_categorias', title: 'Conquistador de Categorías', description: 'Juega al menos una vez en cada categoría disponible.'),
    // Líder del Ranking (Top10)
    Achievement(id: 'lider_ranking', title: 'Líder del Ranking', description: 'Alcanza el Top10 global.'),
    // Espíritu Yachay (all others)
    Achievement(id: 'espiritu_yachay', title: 'Espíritu Yachay', description: 'Obtén todas las demás insignias.'),
  ];

  // Map para buscar en la tabla de la base de datos por nombre (asume filas pre-creadas)
  final Map<String, String> _idToDbName = {
    'primer_paso': 'Primer Paso',
    'racha_5': 'Racha Perfecta - Bronce',
    'racha_10': 'Racha Perfecta - Plata',
    'racha_20': 'Racha Perfecta - Oro',
    'racha_50': 'Racha Perfecta - Diamante',
    'reflejos_5': 'Reflejos de rayo',
    'constante_5': 'Constante Aprendiz - Bronce',
    'constante_10': 'Constante Aprendiz - Plata',
    'constante_20': 'Constante Aprendiz - Oro',
    'constante_50': 'Constante Aprendiz - Diamante',
    'conquistador_categorias': 'Conquistador de Categorías',
    'lider_ranking': 'Líder del Ranking',
    'espiritu_yachay': 'Espíritu Yachay',
  };

  bool _definitionsLoadedFromDb = false;

  Map<String, String> _unlockedMap = {}; // id -> ISO timestamp
  // Cache of recently inserted gamesessions per user to work around
  // RLS/visibility/replication delays when we immediately query gamesessions
  final Map<int, List<Map<String, dynamic>>> _localSessionCache = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(raw);
        _unlockedMap = decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        _unlockedMap = {};
      }
    }
    // intentar cargar definiciones desde la BD (si hay conexión)
    await _loadDefinitionsFromDb();
  }

  Future<List<Achievement>> getAll() async {
    await init();
    return _definitions.map((d) {
      final ts = _unlockedMap[d.id];
      if (ts != null) return d.copyWith(unlocked: true, unlockedAt: DateTime.parse(ts));
      return d;
    }).toList();
  }

  /// Sincroniza los logros que ya ganó el usuario desde la tabla `userachievements`.
  /// Llama esto después del login para reflejar el estado real de la BD.
  Future<void> syncUserAchievements(int userId) async {
    try {
      final res = await Supabase.instance.client
          .from('userachievements')
          .select('achievement_id, earned_at, achievements(name)')
          .eq('user_id', userId);
      if (res is List) {
        for (final r in res) {
          final achRow = r['achievements'] as Map<String, dynamic>?;
          final name = achRow != null ? achRow['name'] as String? : null;
          final earnedAt = r['earned_at'] as String?;
          if (name != null) {
            // buscar internal id por nombre
            final internal = _idToDbName.entries.firstWhere((e) => e.value == name, orElse: () => MapEntry('', '')).key;
            if (internal.isNotEmpty) {
              _unlockedMap[internal] = earnedAt ?? DateTime.now().toIso8601String();
            }
          }
        }
        await _save();
      }
    } catch (e) {
      debugPrint('Error syncing user achievements from DB: $e');
    }
  }

  /// Migra logros desbloqueados localmente (por ejemplo en modo invitado)
  /// a la tabla `userachievements` del usuario proporcionado.
  Future<void> migrateLocalAchievementsToServer(int userId) async {
    await init();
    try {
      for (final entry in _unlockedMap.entries) {
        final id = entry.key;
        final earnedAtIso = entry.value;
        // obtener achievement id en la BD
        int? achId;
        final def = _definitions.firstWhere((d) => d.id == id, orElse: () => Achievement(id: id, title: id, description: ''));
        if (def.dbId != null) {
          achId = def.dbId;
        } else {
          final dbName = _idToDbName[id];
          if (dbName != null) {
            try {
              final res = await Supabase.instance.client
                  .from('achievements')
                  .select('achievement_id')
                  .ilike('name', dbName)
                  .maybeSingle();
              achId = res != null ? (res['achievement_id'] as int?) : null;
            } catch (e) {
              debugPrint('Error looking up achievement id for $id: $e');
            }
          }
        }

        if (achId != null) {
          try {
            final exists = await Supabase.instance.client
                .from('userachievements')
                .select('user_id')
                .eq('user_id', userId)
                .eq('achievement_id', achId)
                .maybeSingle();
            if (exists == null) {
              await Supabase.instance.client.from('userachievements').insert({
                'user_id': userId,
                'achievement_id': achId,
                'earned_at': earnedAtIso,
              });
            }
          } catch (e) {
            debugPrint('Error migrating local achievement $id for user $userId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in migrateLocalAchievementsToServer: $e');
    }
  }


  Future<bool> isUnlocked(String id) async {
    await init();
    return _unlockedMap.containsKey(id);
  }

  /// Desbloquea localmente y, si se proporciona userId, intenta sincronizar con la DB
  /// Devuelve el Achievement desbloqueado o null si ya estaba desbloqueado.
  Future<Achievement?> unlock(String id, {int? userId}) async {
    await init();
    if (_unlockedMap.containsKey(id)) return null;
    final now = DateTime.now();
    _unlockedMap[id] = now.toIso8601String();
    await _save();

    debugPrint('AchievementsService.unlock -> id=$id userId=$userId');
    // intentar insertar en la tabla UserAchievements si es posible
    if (userId != null) {
      try {
  // Preferir usar el achievement_id ya cargado en las definiciones
        final def = _definitions.firstWhere((d) => d.id == id, orElse: () => Achievement(id: id, title: id, description: ''));
        int? achId = def.dbId;
  debugPrint('AchievementsService.unlock -> def.dbId=${def.dbId} def.title=${def.title}');
        if (achId == null) {
          // fallback: buscar por nombre en la tabla achievements
          final dbName = _idToDbName[id];
          if (dbName != null) {
            final res = await Supabase.instance.client
                .from('achievements')
                .select('achievement_id')
                .ilike('name', dbName)
                .maybeSingle();
            achId = res != null ? (res['achievement_id'] as int?) : null;
          }
        }

        if (achId != null) {
          debugPrint('AchievementsService.unlock -> inserting userachievement user=$userId achId=$achId');
          // proteger contra duplicados
          try {
            final exists = await Supabase.instance.client
                .from('userachievements')
                .select('user_id')
                .eq('user_id', userId)
                .eq('achievement_id', achId)
                .maybeSingle();
            if (exists == null) {
              await Supabase.instance.client.from('userachievements').insert({
                'user_id': userId,
                'achievement_id': achId,
                'earned_at': now.toIso8601String(),
              });
              debugPrint('AchievementsService.unlock -> inserted userachievement user=$userId achId=$achId');
            }
          } catch (e) {
            // ignore duplicate/insertion errors
            debugPrint('Error inserting userachievement: $e');
          }
        }
      } catch (e) {
        // no interrumpimos si falla la sincronización
        debugPrint('Error syncing achievement to DB: $e');
      }
    }

    final def = _definitions.firstWhere((d) => d.id == id);
    return def.copyWith(unlocked: true, unlockedAt: now);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(_unlockedMap));
  }

  Future<void> resetAll() async {
    _unlockedMap.clear();
    await _save();
  }

  /// Carga las definiciones (name, description, icon_url, achievement_id) desde la tabla `achievements`
  /// y mapea a las definiciones internas si los nombres coinciden.
  Future<void> _loadDefinitionsFromDb() async {
    if (_definitionsLoadedFromDb) return;
    try {
      final res = await Supabase.instance.client.from('achievements').select('achievement_id, name, description, icon_url');
      if (res is List) {
        // construir un mapa nombre -> row
        final Map<String, Map<String, dynamic>> dbByName = {};
        for (final r in res) {
          final name = r['name'] as String?;
          if (name != null) dbByName[name] = Map<String, dynamic>.from(r);
        }

        // actualizar _definitions manteniendo el orden existente
        final List<Achievement> newDefs = [];
        for (final def in _definitions) {
          final dbName = _idToDbName[def.id];
          if (dbName != null && dbByName.containsKey(dbName)) {
            final row = dbByName[dbName]!;
            newDefs.add(def.copyWith(
              dbId: row['achievement_id'] as int?,
              iconUrl: row['icon_url'] as String?,
              title: row['name'] as String?,
              description: row['description'] as String?,
            ));
          } else {
            newDefs.add(def);
          }
        }
        _definitions
          ..clear()
          ..addAll(newDefs);
      }
    } catch (e) {
      // no hacemos nada si falla — seguimos usando definiciones locales
      debugPrint('Warning loading achievement defs from DB: $e');
    }
    _definitionsLoadedFromDb = true;
  }

  /// Comprueba y desbloquea logros basados en parámetros de la partida
  /// Devuelve la lista de Achievement recién desbloqueadas en esta comprobación.
  Future<List<Achievement>> checkProgress({
    int? correctStreak,
    int? fastStreak,
    Set<int>? categoriesPlayedThisSession,
    int? userId,
    bool sessionEnded = false,
    int? sessionPoints,
    bool sessionRecorded = false,
  }) async {
    final List<Achievement> newly = [];
    // Racha perfecta tiers
    // Note: racha perfecta is now defined across whole matches (each match = 5 questions).
    // If sessionEnded and userId is provided, compute consecutive perfect matches
    // from recent `gamesessions` (final_score == 500) and award tiers accordingly.
    if (sessionEnded && userId != null) {
      try {
        debugPrint('checkProgress(sessionEnded=true) for user=$userId');
        var perfectStreak = await _computePerfectMatchStreak(userId);
        // Determine how many correct answers a "perfect" match represents.
        // Historically we used 5 questions/match (5 * 100 points = 500),
        // but some game configurations may use 10 questions (10 * 100 = 1000),
        // so infer from the current sessionPoints when available.
        int answersPerMatch = 5;
        if (sessionPoints != null) {
          final inferred = sessionPoints ~/ 100;
          if (inferred > 0) answersPerMatch = inferred;
        }
        debugPrint('checkProgress -> answersPerMatch=$answersPerMatch for user=$userId');

        // If we have the just-played session points and it's a perfect match, include it
        if (sessionPoints != null && sessionPoints >= (answersPerMatch * 100)) {
          debugPrint('checkProgress -> including current session (points=$sessionPoints) in perfectStreak');
          perfectStreak += 1;
        }
        debugPrint('checkProgress -> perfectStreak=$perfectStreak for user=$userId');
        // Cada partida perfecta aporta `answersPerMatch` respuestas correctas seguidas.
        final totalConsecutiveCorrect = perfectStreak * answersPerMatch;
        debugPrint('checkProgress -> totalConsecutiveCorrect=$totalConsecutiveCorrect for user=$userId');
        if (totalConsecutiveCorrect >= 5) {
          debugPrint('checkProgress -> awarding racha_5 for user=$userId');
          final a = await unlock('racha_5', userId: userId);
          if (a != null) newly.add(a);
        }
        if (totalConsecutiveCorrect >= 10) {
          debugPrint('checkProgress -> awarding racha_10 for user=$userId');
          final a = await unlock('racha_10', userId: userId);
          if (a != null) newly.add(a);
        }
        if (totalConsecutiveCorrect >= 20) {
          debugPrint('checkProgress -> awarding racha_20 for user=$userId');
          final a = await unlock('racha_20', userId: userId);
          if (a != null) newly.add(a);
        }
        if (totalConsecutiveCorrect >= 50) {
          debugPrint('checkProgress -> awarding racha_50 for user=$userId');
          final a = await unlock('racha_50', userId: userId);
          if (a != null) newly.add(a);
        }
      } catch (e) {
        debugPrint('Error computing perfect match streak: $e');
      }
    } else if (correctStreak != null) {
      // Backward compatibility: if called during the session, still allow
      // awarding based on in-game correctStreak (useful for testing or offline).
      if (correctStreak >= 5) {
        final a = await unlock('racha_5', userId: userId);
        if (a != null) newly.add(a);
      }
      if (correctStreak >= 10) {
        final a = await unlock('racha_10', userId: userId);
        if (a != null) newly.add(a);
      }
      if (correctStreak >= 20) {
        final a = await unlock('racha_20', userId: userId);
        if (a != null) newly.add(a);
      }
      if (correctStreak >= 50) {
        final a = await unlock('racha_50', userId: userId);
        if (a != null) newly.add(a);
      }
    }

    // Reflejos
    if (fastStreak != null && fastStreak >= 5) {
      final a = await unlock('reflejos_5', userId: userId);
      if (a != null) newly.add(a);
    }

    // Conquistador de categorías (sólo comprobamos al final de la sesión y si userId disponible)
    if (sessionEnded && userId != null) {
      try {
        final playedRes = await Supabase.instance.client
            .from('gamesessions')
            .select('category_id')
            .eq('user_id', userId);
        final Set<int> played = {};
        for (final r in playedRes as List) {
          final cid = r['category_id'];
          if (cid is int) played.add(cid);
        }
        // also include the categories of this session if provided
        if (categoriesPlayedThisSession != null) played.addAll(categoriesPlayedThisSession);

  final catsRes = await Supabase.instance.client.from('categories').select('category_id');
  final totalCats = (catsRes as List).length;
        if (played.length >= totalCats && totalCats > 0) {
          final a = await unlock('conquistador_categorias', userId: userId);
          if (a != null) newly.add(a);
        }
      } catch (e) {
        debugPrint('Error checking conquistador_categorias: $e');
      }
    }

    // Primer Paso: al final de la sesión, otorgar "Primer Paso".
    // Antes se comprobaba que fuera la primera partida (count == 1). Eso fallaba
    // cuando el usuario tenía sesiones previas o jugaba sin estar logueado.
    // Ahora aplicamos estas reglas:
    // - Si el usuario está logueado: si no tiene ya el logro, y existe al menos
    //   una fila en `gamesessions` (incluida la recién insertada), le otorgamos
    //   el logro (esto permite corregir casos donde no fue otorgado antes).
    // - Si el usuario no está logueado: desbloqueamos localmente el logro.
    if (sessionEnded) {
      try {
        debugPrint('checkProgress: sessionEnded, userId=$userId');
        if (userId != null) {
          // si ya está localmente desbloqueado, no hacemos nada
          if (!_unlockedMap.containsKey('primer_paso')) {
            // comprobar en la BD si ya existe userachievement (para evitar duplicados)
            bool alreadyInDb = false;
            try {
              final dbAch = await Supabase.instance.client
                  .from('achievements')
                  .select('achievement_id')
                  .ilike('name', _idToDbName['primer_paso'] ?? '')
                  .maybeSingle();
              final achId = dbAch != null ? (dbAch['achievement_id'] as int?) : null;
              if (achId != null) {
                final existing = await Supabase.instance.client
                    .from('userachievements')
                    .select('user_id')
                    .eq('user_id', userId)
                    .eq('achievement_id', achId)
                    .maybeSingle();
                if (existing != null) alreadyInDb = true;
              }
              } catch (_) {
                // ignoramos errores y seguimos — unlock manejará duplicados si existen
              }
              final dbIdForPrimer = _definitions.firstWhere((d) => d.id == 'primer_paso', orElse: () => Achievement(id: 'primer_paso', title: '', description: '')).dbId;
              debugPrint('checkProgress(primer_paso) -> def.dbId=$dbIdForPrimer alreadyInDb=$alreadyInDb');
            if (!alreadyInDb) {
              debugPrint('checkProgress -> primer_paso not in db for user=$userId, checking gamesessions presence');
              // asegurar que hay al menos una partida registrada para el usuario
        final played = await Supabase.instance.client
          .from('gamesessions')
          .select('final_score')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
              debugPrint('checkProgress -> played row for primer_paso check: $played');
              if (played != null) {
                debugPrint('checkProgress -> unlocking primer_paso for user=$userId');
                final a = await unlock('primer_paso', userId: userId);
                if (a != null) newly.add(a);
              } else if (sessionRecorded) {
                // We just inserted a session but DB query didn't return it (RLS/visibility/latency).
                debugPrint('checkProgress -> sessionRecorded true but played row null; unlocking primer_paso for user=$userId');
                final a = await unlock('primer_paso', userId: userId);
                if (a != null) newly.add(a);
              } else {
                debugPrint('checkProgress -> no played row found for primer_paso user=$userId');
              }
            }
          }
        } else {
          // usuario no logueado -> desbloquear localmente
          if (!_unlockedMap.containsKey('primer_paso')) {
            final a = await unlock('primer_paso');
            if (a != null) newly.add(a);
          }
        }
      } catch (e) {
        debugPrint('Error checking primer_paso: $e');
      }
    }

    // Espíritu Yachay: si ya desbloqueó todas las demás insignias
    try {
      final locked = _definitions.where((d) => d.id != 'espiritu_yachay').where((d) => !_unlockedMap.containsKey(d.id));
      if (locked.isEmpty) {
        final a = await unlock('espiritu_yachay', userId: userId);
        if (a != null) newly.add(a);
      }
    } catch (e) {
      debugPrint('Error checking espiritu_yachay: $e');
    }

    return newly;
  }

  /// Devuelve la cantidad de partidas consecutivas más recientes en las que
  /// el usuario obtuvo puntaje perfecto (final_score == 500).
  /// Limita la búsqueda a las últimas 100 partidas por seguridad.
  Future<int> _computePerfectMatchStreak(int userId) async {
    try {
      debugPrint('Computing perfect match streak for user=$userId');
       // Prefer server-side RPC to fetch recent sessions (handles RLS via
      // SECURITY DEFINER function). The RPC returns a JSON object { data: [...] }.
      List<Map<String, dynamic>> dbList = [];
      try {
        final rpcRes = await Supabase.instance.client.rpc('rpc_get_user_gamesessions', params: {
          'p_user_id': userId,
          'p_limit': 100,
        }).maybeSingle();
        debugPrint('computePerfectMatchStreak -> rpc result type=${rpcRes.runtimeType}');
        if (rpcRes != null) {
          try {
            final rpcMap = Map<String, dynamic>.from(rpcRes as Map);
            final data = rpcMap['data'];
            if (data is List) {
              dbList = data.map((e) => Map<String, dynamic>.from(e)).toList();
            }
          } catch (e) {
            debugPrint('computePerfectMatchStreak -> cannot parse rpc result: $e');
          }
        }
      } catch (e) {
        debugPrint('computePerfectMatchStreak -> RPC failed, falling back to direct query: $e');
        try {
          final res = await Supabase.instance.client
              .from('gamesessions')
              .select('session_id, final_score, created_at, user_id')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(100);
          dbList = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e2) {
          debugPrint('Direct query fallback also failed: $e2');
          dbList = <Map<String, dynamic>>[];
        }
      }

  final cachedForUser = _localSessionCache[userId] ?? <Map<String, dynamic>>[];

      // Merge without duplicates (by session_id if available).
      final Map<dynamic, Map<String, dynamic>> mergedById = {};
      for (final r in dbList) {
        final sid = r['session_id'];
        mergedById[sid ?? DateTime.now().microsecondsSinceEpoch.toString()] = r;
      }
      for (final r in cachedForUser) {
        final sid = r['session_id'];
        if (sid == null) {
          // generate a synthetic key for caching
          mergedById[DateTime.now().microsecondsSinceEpoch.toString()] = r;
        } else if (!mergedById.containsKey(sid)) {
          mergedById[sid] = r;
        }
      }

      // Create a combined list and sort descending by created_at
      final combined = mergedById.values.toList();
      combined.sort((a, b) {
        try {
          final ta = DateTime.parse(a['created_at'] as String);
          final tb = DateTime.parse(b['created_at'] as String);
          return tb.compareTo(ta);
        } catch (_) {
          return 0;
        }
      });

      int streak = 0;
      // Iterate over combined recent sessions
      for (final r in combined) {
        final scRaw = r['final_score'];
        debugPrint('  recent session raw final_score=$scRaw (${scRaw.runtimeType})');
        int? scInt;
        if (scRaw is int) scInt = scRaw;
        else if (scRaw is num) scInt = scRaw.toInt();
        else if (scRaw is String) scInt = int.tryParse(scRaw);

        if (scInt != null && scInt >= 500) {
          streak++;
        } else {
          break; // stop at first non-perfect recent match
        }
      }
      debugPrint('Computed perfect streak=$streak for user=$userId');
      return streak;
    } catch (e) {
      debugPrint('Error fetching gamesessions for perfect streak: $e');
      return 0;
    }
  }

  /// Add a locally-known gamesession row to the cache so subsequent
  /// streak computations can see it even if the DB query doesn't yet return it
  /// due to RLS/visibility/replication delays.
  void addLocalGameSession(Map<String, dynamic> row) {
    try {
      final uid = row['user_id'];
      if (uid is int) {
        _localSessionCache.putIfAbsent(uid, () => []).insert(0, Map<String, dynamic>.from(row));
        // Keep cache bounded (avoid unbounded growth)
        final list = _localSessionCache[uid]!;
        if (list.length > 200) list.removeRange(200, list.length);
      }
    } catch (e) {
      debugPrint('Error caching local game session: $e');
    }
  }

  Future<Achievement?> notifyUsedFifty({int? userId}) async => await unlock('used_fifty', userId: userId);
  Future<Achievement?> notifyUsedAuto({int? userId}) async => await unlock('used_auto', userId: userId);

  /// Comprueba logros derivados de la racha de login (Constante Aprendiz).
  /// Debe llamarse al iniciar sesión con el contador actualizado (loginStreak).
  Future<List<Achievement>> checkLoginStreak({required int loginStreak, int? userId}) async {
    final List<Achievement> newly = [];
    if (loginStreak >= 5) {
      final a = await unlock('constante_5', userId: userId);
      if (a != null) newly.add(a);
    }
    if (loginStreak >= 10) {
      final a = await unlock('constante_10', userId: userId);
      if (a != null) newly.add(a);
    }
    if (loginStreak >= 20) {
      final a = await unlock('constante_20', userId: userId);
      if (a != null) newly.add(a);
    }
    if (loginStreak >= 50) {
      final a = await unlock('constante_50', userId: userId);
      if (a != null) newly.add(a);
    }
    return newly;
  }

  /// Comprueba si el usuario está en el Top10 (por suma de final_score) y
  /// otorga el logro 'lider_ranking' desde la app si corresponde.
  /// Devuelve el Achievement otorgado o null si no se otorgó.
  Future<Achievement?> checkAndAwardLiderRanking({required int userId}) async {
    // Simpler, robust approach: agregar localmente por usuario y tomar Top10.
    try {
      // Use RPC to compute Top10 on the server (avoids RLS/permission issues)
      final topRes = await Supabase.instance.client.rpc('rpc_get_top10').maybeSingle();
  final dynamic topMap = topRes;
  final List<dynamic> topList = (topMap is Map && topMap['data'] is List) ? (topMap['data'] as List<dynamic>) : <dynamic>[];
      final Map<int, int> sums = {};
      for (final row in topList) {
        if (row is Map<String, dynamic>) {
          final uid = row['user_id'];
          final total = row['total'];
          if (uid is int && total is int) sums[uid] = total;
        }
      }
      final sorted = sums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topUsers = sorted.take(10).map((e) => e.key).toSet();
      debugPrint('checkAndAwardLiderRanking -> top10 users=${topUsers.toList()} sums=${sorted.take(10).map((e)=>e.value).toList()} userSum=${sums[userId]}');
      if (topUsers.contains(userId)) {
        debugPrint('checkAndAwardLiderRanking -> user $userId is in top10, awarding');
        return await unlock('lider_ranking', userId: userId);
      } else {
        debugPrint('checkAndAwardLiderRanking -> user $userId not in top10');
      }
    } catch (e) {
      debugPrint('Error checking leader ranking in app (fallback): $e');
    }
    return null;
  }
}
