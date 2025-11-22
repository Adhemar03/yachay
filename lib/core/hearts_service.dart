// lib/core/hearts_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeartsService {
  static final HeartsService _instance = HeartsService._internal();
  factory HeartsService() => _instance;
  HeartsService._internal();

  static const int maxHearts = 5;

  /// Carga vidas desde Supabase + resetea si ya pasó las 7:00 AM
  Future<int> loadHeartsFromSupabase({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return maxHearts;

    try {
      // Primero: llamamos al RPC que resetea si corresponde
      await Supabase.instance.client.rpc('reset_daily_hearts_if_needed');

      // Luego traemos el valor actualizado
      final response = await Supabase.instance.client
          .from('users')
          .select('lives_count')
          .eq('user_id', userId)
          .single();

      final lives = (response['lives_count'] as int?) ?? maxHearts;

      // Guardamos localmente como respaldo
      await prefs.setInt('lives_count', lives);

      return lives;
    } catch (e) {
      print('Error cargando vidas desde Supabase: $e');
      // Fallback local
      return prefs.getInt('lives_count') ?? maxHearts;
    }
  }

  /// Resta una vida y actualiza en Supabase
  Future<int> deductHeart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return maxHearts;

    final current = await loadHeartsFromSupabase();
    if (current <= 0) return 0;

    final newLives = current - 1;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'lives_count': newLives})
          .eq('user_id', userId);

      await prefs.setInt('lives_count', newLives);
      return newLives;
    } catch (e) {
      print('Error restando vida: $e');
      return current;
    }
  }
}
