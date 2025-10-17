import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_mode_screen.dart';
import 'question_widgets.dart';

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class GamePage extends StatefulWidget {
  final String modo;
  final String? nivel;
  final String? categoria;

  const GamePage({
    Key? key,
    required this.modo,
    this.nivel,
    this.categoria,
  }) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

// Clase State separada correctamente
class _GamePageState extends State<GamePage> {
  /// Updates the user's total points and returns the session points (finalScore)
  Future<int> _showScoreAndUpdateUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return 0;
    final pointsToAdd = correctAnswers * 100;
    if (pointsToAdd > 0) {
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('in_game_points')
            .eq('user_id', userId)
            .maybeSingle();
        final currentPoints = (userData != null && userData['in_game_points'] != null)
            ? userData['in_game_points'] as int
            : 0;
        final newPoints = currentPoints + pointsToAdd;
        await Supabase.instance.client
            .from('users')
            .update({'in_game_points': newPoints})
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Error updating user points: $e');
      }
    }
    return pointsToAdd;
  }

  /// Records a game session row in GameSessions (game_mode will be NULL)
  Future<void> _recordGameSession(int finalScore) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;
      await Supabase.instance.client.from('gamesessions').insert({
        'user_id': userId,
        'game_mode': null,
        'final_score': finalScore,
      });
    } catch (e) {
      debugPrint('Error recording game session: $e');
    }
  }
  int correctAnswers = 0;
  bool finished = false;
  static const int questionDuration = 10; // segundos por pregunta
  int timeLeft = questionDuration;
  Timer? timer;

  List<Map<String, dynamic>> preguntas = [];
  bool loading = true;
  int current = 0;
  int? selectedIndex;
  bool showFeedback = false;
  bool showingExplanation = false;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ...existing code...

  // (mueve esta función justo antes de build)

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { loading = true; });
    try {
      // 1. Obtener category_id desde Categories
      int? categoryId;
      if (widget.categoria != null && widget.categoria!.isNotEmpty) {
        //debugPrint('Buscando categoría por nombre: "${widget.categoria}"');
        final catRes = await Supabase.instance.client
            .from('categories')
            .select('category_id, name')
            .ilike('name', '%${widget.categoria ?? ''}%')
            .maybeSingle();
        //debugPrint('Resultado consulta categoría: $catRes');
        categoryId = catRes?['category_id'];
      }

      // 2. Consultar preguntas filtrando solo si corresponde
    var query = Supabase.instance.client
      .from('questions')
      .select()
      ;
      if (widget.nivel != null && widget.nivel!.isNotEmpty) {
        query = query.eq('difficulty', widget.nivel!.toLowerCase() as Object);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      //debugPrint('Parámetros de consulta: nivel=${widget.nivel?.toLowerCase()}, categoryId=$categoryId');
      final res = await query.limit(10); // Trae más para barajar
      //debugPrint('Resultado de preguntas: $res');
      final preguntasListRaw = List<Map<String, dynamic>>.from(res);
      // Filtrar solo tipos soportados y mezclar
      final allowed = ['multiple_choice', 'image_recognition', 'audio_recognition', 'fill_in_blank'];
      final preguntasList = preguntasListRaw.where((q) => allowed.contains(q['question_type'] as String? ?? '')).toList();
      preguntasList.shuffle();
      setState(() {
        preguntas = preguntasList.take(5).toList();
        loading = false;
        current = 0;
        selectedIndex = null;
        showFeedback = false;
        showingExplanation = false;
        timeLeft = questionDuration;
      });
      _startTimer();
    } catch (e) {
      setState(() { loading = false; });
      debugPrint('Error al cargar preguntas: $e');
    }
  }

  Future<void> _nextQuestion() async {
    timer?.cancel();
    if (current < preguntas.length - 1) {
      setState(() {
        current++;
        selectedIndex = null;
        showFeedback = false;
        showingExplanation = false;
        timeLeft = questionDuration;
      });
      _startTimer();
    } else {
      // Finalizar: actualizar puntos y registrar sesión
      final sessionPoints = await _showScoreAndUpdateUser();
      await _recordGameSession(sessionPoints);
      setState(() {
        finished = true;
      });
    }
  }


  Widget _buildExplanationScreen() {
    final explanation = preguntas[current]['explanation'] ?? 'Sin explicación disponible.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 64),
        const Text(
          'Explicación:',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          explanation,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                showingExplanation = false;
                showFeedback = false;
                selectedIndex = null;
              });
              _nextQuestion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(current < preguntas.length - 1 ? 'Siguiente pregunta' : 'Finalizar'),
          ),
        ),
      ],
    );
  }

  int? _getCorrectIndexForCurrent() {
    final q = preguntas[current];
    final type = q['question_type'] as String? ?? 'multiple_choice';
    final answerData = q['answer_data'];
    try {
      if (type == 'multiple_choice') {
        final options = (answerData['options'] as List);
        for (int i = 0; i < options.length; i++) {
          if (options[i]['isCorrect'] == true) return i;
        }
      } else if (type == 'image_recognition') {
        final options = (answerData['options'] as List);
        for (int i = 0; i < options.length; i++) {
          if (options[i]['isCorrect'] == true) return i;
        }
      } else if (type == 'audio_recognition') {
        final options = (answerData['options'] as List);
        for (int i = 0; i < options.length; i++) {
          if (options[i]['isCorrect'] == true) return i;
        }
      }
    } catch (e) {
      debugPrint('Error parsing correct index: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F3240),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : preguntas.isEmpty
                ? const Center(child: Text('No hay preguntas disponibles.'))
                : (finished
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¡Fin de la partida!', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            Text('Puntaje obtenido: ${correctAnswers * 100}', style: TextStyle(fontSize: 22, color: Colors.tealAccent)),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const GameModeScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text('Volver al inicio'),
                            ),
                          ],
                        ),
                      )
                    : (showingExplanation
                        ? _buildExplanationScreen()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Barra de progreso y cronómetro
                              Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: (MediaQuery.of(context).size.width - 48) * (timeLeft / questionDuration),
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: timeLeft > 3 ? Colors.teal : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        'Tiempo: $timeLeft s',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Render según el tipo de pregunta
                              Builder(builder: (_) {
                                final q = preguntas[current];
                                final type = q['question_type'] as String? ?? 'multiple_choice';
                                final answerData = q['answer_data'];
                                if (type == 'image_recognition') {
                                  final imageUrls = (answerData['options'] as List)
                                      .map<String>((o) => o['imageUrl'] as String)
                                      .toList();
                                  return ImageRecognitionQuestion(
                                    question: q['question_text'],
                                    imageUrls: imageUrls,
                                    selectedIndex: selectedIndex,
                                    correctIndex: _getCorrectIndexForCurrent(),
                                    showFeedback: showFeedback,
                                    onSelected: (i) async {
                                      timer?.cancel();
                                      setState(() {
                                        selectedIndex = i;
                                        showFeedback = true;
                                      });
                                      final correct = _getCorrectIndexForCurrent();
                                      if (i == correct) correctAnswers++;
                                      await Future.delayed(const Duration(seconds: 2));
                                      setState(() { showingExplanation = true; });
                                    },
                                  );
                                }
                                // por defecto multiple choice
                                final options = (answerData['options'] as List).map<String>((opt) => opt['text'] as String).toList();
                                return MultipleChoiceQuestion(
                                  question: q['question_text'],
                                  options: options,
                                  selectedIndex: selectedIndex,
                                  correctIndex: _getCorrectIndexForCurrent(),
                                  showFeedback: showFeedback,
                                  onSelected: (i) async {
                                    timer?.cancel();
                                    setState(() {
                                      selectedIndex = i;
                                      showFeedback = true;
                                    });
                                    final correct = _getCorrectIndexForCurrent();
                                    if (i == correct) correctAnswers++;
                                    await Future.delayed(const Duration(seconds: 2));
                                    setState(() { showingExplanation = true; });
                                  },
                                );
                              }),
                              const SizedBox(height: 24),
                              Text('Pregunta ${current + 1} de ${preguntas.length}'),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    timer?.cancel();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const GameModeScreen()),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Terminar partida y volver al inicio'),
                                ),
                              ),
                            ],
                          ))),
      ),
    );
  }

  void _startTimer() {
    timer?.cancel();
    setState(() {
      timeLeft = questionDuration;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (showFeedback || showingExplanation) {
        t.cancel();
        return;
      }
      if (timeLeft > 1) {
        setState(() {
          timeLeft--;
        });
      } else {
        t.cancel();
        // Si no se seleccionó opción, mostrar explicación automáticamente
        if (selectedIndex == null && !showingExplanation) {
          setState(() {
            showFeedback = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                showingExplanation = true;
              });
            }
          });
        }
      }
    });
  }
  // ...existing code...

  // ...existing code...
}