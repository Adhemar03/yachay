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

  const GamePage({Key? key, required this.modo, this.nivel, this.categoria})
    : super(key: key);

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
        final currentPoints =
            (userData != null && userData['in_game_points'] != null)
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
  bool? selectedBool;
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
    setState(() {
      loading = true;
    });
    try {
      // normalizar categoría recibida
      final rawCategoria = widget.categoria?.trim();
      final categoriaSelected = (rawCategoria == null || rawCategoria.isEmpty)
          ? null
          : rawCategoria;
      debugPrint(
        'Categoria recibida en GamePage: $categoriaSelected, nivel: ${widget.nivel}',
      );

      // 1. Obtener category_id desde Categories solo si hay categoría seleccionada
      int? categoryId;
      if (categoriaSelected != null) {
        final catRes = await Supabase.instance.client
            .from('categories')
            .select('category_id, name')
            .ilike('name', '%$categoriaSelected%')
            .maybeSingle();
        debugPrint('Resultado consulta categoría: $catRes');
        categoryId = catRes?['category_id'] as int?;
      }

      // 2. Consultar preguntas filtrando solo si corresponde
      var query = Supabase.instance.client.from('questions').select();

      if (widget.nivel != null && widget.nivel!.isNotEmpty) {
        // asegúrate que la dificultad en la BD está en minúsculas
        query = query.eq('difficulty', widget.nivel!.toLowerCase());
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      // Traer un conjunto amplio (sin limitar a 10) para poder barajar y elegir 5
      // Ajusta el rango si tu tabla es enorme; aquí traemos hasta 1000 registros como ejemplo.
      final res = await query.range(0, 999);

      // Convertir resultado a lista y filtrar solo tipos soportados
      final preguntasListRaw = (res is List)
          ? List<Map<String, dynamic>>.from(res)
          : <Map<String, dynamic>>[];
      final allowed = [
        'multiple_choice',
        'image_recognition',
        'audio_recognition',
        'fill_in_blank',
        'true_false',
      ];
      final preguntasList = preguntasListRaw
          .where((q) => allowed.contains((q['question_type'] as String?) ?? ''))
          .toList();

      // Mezclar y tomar 5 preguntas aleatorias que mantengan su nivel y (si aplica) su categoría
      preguntasList.shuffle();
      final selected = preguntasList.take(5).toList();

      debugPrint(
        'Preguntas encontradas: ${preguntasList.length}, seleccionadas: ${selected.length}',
      );

      setState(() {
        preguntas = selected;
        loading = false;
        current = 0;
        selectedIndex = null;
        selectedBool = null;
        showFeedback = false;
        showingExplanation = false;
        timeLeft = questionDuration;
      });

      // Iniciar timer sólo si hay preguntas
      if (preguntas.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint('Error al cargar preguntas: $e');
    }
  }

  Future<void> _nextQuestion() async {
    timer?.cancel();
    if (current < preguntas.length - 1) {
      setState(() {
        current++;
        selectedIndex = null;
        selectedBool = null;
        showFeedback = false;
        showingExplanation = false;
        timeLeft = questionDuration;
      });
      _startTimer();
    } else {
      // Mostrar inmediatamente la pantalla de fin de partida
      setState(() {
        finished = true;
      });

      // Ejecutar actualización de puntos y registro de sesión en background
      _showScoreAndUpdateUser()
          .then((sessionPoints) {
            // registrar sesión (no bloqueamos la UI)
            _recordGameSession(sessionPoints).catchError((e) {
              debugPrint('Error recording game session (background): $e');
            });
          })
          .catchError((e) {
            debugPrint('Error updating user points (background): $e');
          });
    }
  }

  Widget _buildExplanationScreen() {
    final explanation =
        preguntas[current]['explanation'] ?? 'Sin explicación disponible.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 64),
        const Text(
          'Explicación:',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
            child: Text(
              current < preguntas.length - 1
                  ? 'Siguiente pregunta'
                  : 'Finalizar',
            ),
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
      } else if (type == 'fill_in_blank') {
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

  /// Devuelve true/false para preguntas de tipo `true_false` si se puede determinar
  bool? _getCorrectBoolForCurrent() {
    try {
      final q = preguntas[current];
      final answerData = q['answer_data'];
      if (answerData == null) return null;
      
      // Manejo del nuevo formato de respuesta
      if (answerData is Map && answerData.containsKey('correct_answer')) {
        final correctAnswer = answerData['correct_answer'].toString().toLowerCase();
        return correctAnswer == 'true' || correctAnswer == 'verdadero';
      }
    } catch (e) {
      debugPrint('Error parsing correct bool: $e');
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
                          Text(
                            '¡Fin de la partida!',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Puntaje obtenido: ${correctAnswers * 100}',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.tealAccent,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const GameModeScreen(),
                                ),
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
                                    width:
                                        (MediaQuery.of(context).size.width -
                                            48) *
                                        (timeLeft / questionDuration),
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: timeLeft > 3
                                          ? Colors.teal
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        'Tiempo: $timeLeft s',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Render según el tipo de pregunta
                              Builder(
                                builder: (_) {
                                  final q = preguntas[current];
                                  final type =
                                      q['question_type'] as String? ??
                                      'multiple_choice';
                                  final answerData = q['answer_data'];

                                  if (type == 'image_recognition') {
                                    final imageUrls =
                                        (answerData['options'] as List)
                                            .map<String>(
                                              (o) => o['imageUrl'] as String,
                                            )
                                            .toList();
                                    return ImageRecognitionQuestion(
                                      question: q['question_text'],
                                      imageUrls: imageUrls,
                                      selectedIndex: selectedIndex,
                                      correctIndex:
                                          _getCorrectIndexForCurrent(),
                                      showFeedback: showFeedback,
                                      onSelected: (i) async {
                                        timer?.cancel();
                                        setState(() {
                                          selectedIndex = i;
                                          showFeedback = true;
                                        });
                                        final correct =
                                            _getCorrectIndexForCurrent();
                                        if (i == correct) correctAnswers++;
                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          showingExplanation = true;
                                        });
                                      },
                                    );
                                  }

                                  if (type == 'audio_recognition') {
                                    // intenta obtener audio desde media_url o desde answer_data si aplica
                                    final mediaUrl = q['media_url'] as String?;
                                    final audioUrls = <String>[];
                                    if (mediaUrl != null && mediaUrl.isNotEmpty)
                                      audioUrls.add(mediaUrl);
                                    // opciones de texto
                                    final options =
                                        (answerData['options'] as List)
                                            .map<String>(
                                              (opt) => opt['text'] as String,
                                            )
                                            .toList();
                                    return AudioRecognitionQuestion(
                                      question: q['question_text'],
                                      audioUrls: audioUrls,
                                      options: options,
                                      selectedIndex: selectedIndex,
                                      correctIndex:
                                          _getCorrectIndexForCurrent(),
                                      showFeedback: showFeedback,
                                      onSelected: (i) async {
                                        timer?.cancel();
                                        setState(() {
                                          selectedIndex = i;
                                          showFeedback = true;
                                        });
                                        final correct =
                                            _getCorrectIndexForCurrent();
                                        if (i == correct) correctAnswers++;
                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          showingExplanation = true;
                                        });
                                      },
                                    );
                                  }

                                  if (type == 'fill_in_blank') {
                                    final options =
                                        (answerData['options'] as List)
                                            .map<String>(
                                              (opt) => opt['text'] as String,
                                            )
                                            .toList();
                                    return FillInTheBlankDragQuestion(
                                      question: q['question_text'],
                                      options: options,
                                      selectedIndex: selectedIndex,
                                      correctIndex:
                                          _getCorrectIndexForCurrent(),
                                      showFeedback: showFeedback,
                                      onDropped: (i) async {
                                        // comportamiento idéntico al de las otras preguntas: parar timer, mostrar feedback y contar aciertos
                                        timer?.cancel();
                                        setState(() {
                                          selectedIndex = i;
                                          showFeedback = true;
                                        });
                                        final correct =
                                            _getCorrectIndexForCurrent();
                                        if (i == correct) correctAnswers++;
                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          showingExplanation = true;
                                        });
                                      },
                                    );
                                  }

                                    if (type == 'true_false') {
                                      final correctBool = _getCorrectBoolForCurrent();
                                      return TrueFalseQuestion(
                                        question: q['question_text'],
                                        selectedAnswer: selectedBool,
                                        correctAnswer: correctBool,
                                        showFeedback: showFeedback,
                                        onSelected: (bool ans) async {
                                          timer?.cancel();
                                          setState(() {
                                            selectedBool = ans;
                                            showFeedback = true;
                                          });
                                          if (correctBool != null && ans == correctBool) correctAnswers++;
                                          await Future.delayed(const Duration(seconds: 2));
                                          if (!mounted) return;
                                          setState(() {
                                            showingExplanation = true;
                                          });
                                        },
                                      );
                                    }

                                  // por defecto multiple choice
                                  final options =
                                      (answerData['options'] as List)
                                          .map<String>(
                                            (opt) => opt['text'] as String,
                                          )
                                          .toList();
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
                                      final correct =
                                          _getCorrectIndexForCurrent();
                                      if (i == correct) correctAnswers++;
                                      await Future.delayed(
                                        const Duration(seconds: 2),
                                      );
                                      if (!mounted) return;
                                      _nextQuestion();
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Pregunta ${current + 1} de ${preguntas.length}',
                              ),
                              const SizedBox(
                                height: 12,
                              ), // baja un poco el botón
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    timer?.cancel();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const GameModeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text(
                                    'Terminar partida y volver al inicio',
                                  ),
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
        final curType = (preguntas.isNotEmpty && current < preguntas.length)
            ? (preguntas[current]['question_type'] as String? ?? '')
            : '';
        final noAnswer = curType == 'true_false' ? (selectedBool == null) : (selectedIndex == null);
        if (noAnswer) {
          setState(() {
            showFeedback = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _nextQuestion();
            }
          });
        }
      }
    });
  }
  // ...existing code...

  // ...existing code...
}
