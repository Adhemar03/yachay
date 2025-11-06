import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_mode_screen.dart';
import 'question_widgets.dart';

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math';

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
  // Powers state
  int fiftyCount = 3;
  int autoAnswerCount = 2;
  bool powerUsedThisQuestion = false;
  final Set<int> hiddenOptions = {};
  bool lockOptions = false;

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
      List<Map<String, dynamic>> preguntasListRaw = [];
      try {
        preguntasListRaw = List<Map<String, dynamic>>.from(
          (res as List).map((e) => Map<String, dynamic>.from(e)),
        );
      } catch (e) {
        debugPrint('Warning converting preguntas list: $e');
        preguntasListRaw = <Map<String, dynamic>>[];
      }
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
        // reset powers state for next question
        powerUsedThisQuestion = false;
        hiddenOptions.clear();
        lockOptions = false;
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
        final correctAnswer = answerData['correct_answer']
            .toString()
            .toLowerCase();
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
                                      hiddenOptions: hiddenOptions,
                                      lockOptions: lockOptions,
                                      onSelected: (i) async {
                                        if (lockOptions) return;
                                        timer?.cancel();
                                        setState(() {
                                          selectedIndex = i;
                                          showFeedback = true;
                                          lockOptions = true;
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
                                      hiddenOptions: hiddenOptions,
                                      lockOptions: lockOptions,
                                      onSelected: (i) async {
                                        if (lockOptions) return;
                                        timer?.cancel();
                                        setState(() {
                                          selectedIndex = i;
                                          showFeedback = true;
                                          lockOptions = true;
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
                                      hiddenOptions: hiddenOptions,
                                      lockOptions: lockOptions,
                                      onDropped: (i) async {
                                        if (lockOptions) return;
                                        timer?.cancel();
                                        setState(() {
                                          selectedIndex = i;
                                          showFeedback = true;
                                          lockOptions = true;
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
                                  }

                                  if (type == 'true_false') {
                                    final correctBool =
                                        _getCorrectBoolForCurrent();
                                    return TrueFalseQuestion(
                                      question: q['question_text'],
                                      selectedAnswer: selectedBool,
                                      correctAnswer: correctBool,
                                      showFeedback: showFeedback,
                                      onSelected: (bool ans) async {
                                        if (lockOptions) return;
                                        timer?.cancel();
                                        setState(() {
                                          selectedBool = ans;
                                          showFeedback = true;
                                          lockOptions = true;
                                        });
                                        if (correctBool != null &&
                                            ans == correctBool)
                                          correctAnswers++;
                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );
                                        if (!mounted) return;
                                        _nextQuestion();
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
                                    hiddenOptions: hiddenOptions,
                                    lockOptions: lockOptions,
                                    onSelected: (i) async {
                                      if (lockOptions) return;
                                      timer?.cancel();
                                      setState(() {
                                        selectedIndex = i;
                                        showFeedback = true;
                                        lockOptions = true;
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
                              const SizedBox(height: 12),
                              // ROW DE PODERES
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _PowerButton(
                                    icon: Icons.percent,
                                    label: '50/50',
                                    counter: fiftyCount,
                                    disabled:
                                        powerUsedThisQuestion ||
                                        fiftyCount <= 0 ||
                                        lockOptions,
                                    onTap: _useFifty,
                                  ),
                                  _PowerButton(
                                    icon: Icons.flash_on,
                                    label: 'Auto',
                                    counter: autoAnswerCount,
                                    disabled:
                                        powerUsedThisQuestion ||
                                        autoAnswerCount <= 0 ||
                                        lockOptions,
                                    onTap: _useAutoAnswer,
                                  ),
                                ],
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
        final noAnswer = curType == 'true_false'
            ? (selectedBool == null)
            : (selectedIndex == null);
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

  // ======= Poderes ========
  void _useFifty() {
    if (powerUsedThisQuestion || fiftyCount <= 0) return;
    final q = preguntas[current];
    final answerData = q['answer_data'];
    if (answerData is Map && answerData['options'] is List) {
      final opts = answerData['options'] as List;
      final correct = _getCorrectIndexForCurrent();
      final incorrects = <int>[];
      for (int i = 0; i < opts.length; i++) {
        if (i != correct) incorrects.add(i);
      }
      incorrects.shuffle();
      final toHide = incorrects.take(
        incorrects.length >= 2 ? 2 : incorrects.length,
      );
      setState(() {
        hiddenOptions.addAll(toHide);
        fiftyCount -= 1;
        powerUsedThisQuestion = true;
      });
    }
  }

  void _useAutoAnswer() {
    if (powerUsedThisQuestion || autoAnswerCount <= 0) return;
    final q = preguntas[current];
    final type = q['question_type'] as String? ?? '';
    setState(() {
      autoAnswerCount -= 1;
      powerUsedThisQuestion = true;
      lockOptions = true;
    });
    if (type == 'true_false') {
      final correct = _getCorrectBoolForCurrent();
      if (correct != null) {
        setState(() {
          selectedBool = correct;
          showFeedback = true;
          if (correct) correctAnswers++;
        });
      }
    } else {
      final correct = _getCorrectIndexForCurrent();
      if (correct != null) {
        setState(() {
          selectedIndex = correct;
          showFeedback = true;
          correctAnswers++;
        });
      }
    }
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }
  // ...existing code...

  // ...existing code...
}

// Modelo mínimo del item de pregunta esperado por esta página
class GameQuestion {
  final String text;
  final List<String> options; // 4 opciones
  final int correctIndex; // índice 0..3 correcto

  GameQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
  });
}

class GamePageWithPowers extends StatefulWidget {
  const GamePageWithPowers({super.key, required this.questions});
  final List<GameQuestion> questions;

  @override
  State<GamePageWithPowers> createState() => _GamePageWithPowersState();
}

class _GamePageWithPowersState extends State<GamePageWithPowers> {
  int qIndex = 0;
  int score = 0;

  // --- Poderes (puedes cargar estos contadores desde BD/SharedPreferences) ---
  int fiftyCount = 3; // cantidad disponible de 50/50
  int autoAnswerCount = 2; // cantidad disponible de Respuesta Automática

  // Control por pregunta
  bool powerUsedThisQuestion = false; // Solo 1 poder por pregunta
  final Set<int> hiddenOptions = {}; // índices ocultos por 50/50
  bool lockOptions = false; // bloquea taps luego de responder

  GameQuestion get current => widget.questions[qIndex];

  // =============== LÓGICA PRINCIPAL ===============

  void _onTapOption(int index) {
    if (lockOptions) return;

    final isCorrect = index == current.correctIndex;
    setState(() {
      lockOptions = true;
      if (isCorrect) score += 100; // suma que uses
    });

    // Simula delay y avanza
    Future.delayed(const Duration(milliseconds: 600), _goNext);
  }

  void _goNext() {
    if (qIndex < widget.questions.length - 1) {
      setState(() {
        qIndex++;
        // reset por nueva pregunta
        powerUsedThisQuestion = false;
        hiddenOptions.clear();
        lockOptions = false;
      });
    } else {
      // fin del juego: navega o muestra dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Fin!'),
          content: Text('Puntaje: $score'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // =============== PODER 50/50 ===============
  void _useFifty() {
    if (powerUsedThisQuestion || fiftyCount <= 0) return;

    final incorrects = <int>[];
    for (int i = 0; i < current.options.length; i++) {
      if (i != current.correctIndex) incorrects.add(i);
    }

    // elige 2 incorrectas aleatorias para ocultar
    incorrects.shuffle(Random());
    final toHide = incorrects.take(2);

    setState(() {
      hiddenOptions.addAll(toHide);
      fiftyCount -= 1;
      powerUsedThisQuestion = true; // ya no se puede usar otro poder
    });
  }

  // =============== PODER RESPUESTA AUTOMÁTICA ===============
  void _useAutoAnswer() {
    if (powerUsedThisQuestion || autoAnswerCount <= 0) return;

    setState(() {
      autoAnswerCount -= 1;
      powerUsedThisQuestion = true;
      lockOptions = true;
      score += 100; // lo marcas como correcta
    });

    // Avanza a la siguiente
    Future.delayed(const Duration(milliseconds: 400), _goNext);
  }

  // =============== UI ===============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0F1F2A).withOpacity(1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER SIMPLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('YACHAY', style: TextStyle(color: Colors.white)),
                  Text(
                    'Puntos: $score',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Pregunta
              Text(
                current.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // Opciones
              for (int i = 0; i < current.options.length; i++)
                AnswerOption(
                  label: current.options[i],
                  index: i,
                  isHidden: hiddenOptions.contains(i),
                  isDisabled: lockOptions,
                  onTap: () => _onTapOption(i),
                ),

              const Spacer(),

              // ====== PODERES EN LA PARTE INFERIOR ======
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PowerButton(
                    icon: Icons.percent, // usa tu ícono 50/50
                    label: '50/50',
                    counter: fiftyCount,
                    disabled:
                        powerUsedThisQuestion || fiftyCount <= 0 || lockOptions,
                    onTap: _useFifty,
                  ),
                  _PowerButton(
                    icon: Icons.flash_on, // usa tu ícono de “auto”
                    label: 'Auto',
                    counter: autoAnswerCount,
                    disabled:
                        powerUsedThisQuestion ||
                        autoAnswerCount <= 0 ||
                        lockOptions,
                    onTap: _useAutoAnswer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Botón redondo con contador
class _PowerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int counter;
  final bool disabled;
  final VoidCallback onTap;

  const _PowerButton({
    required this.icon,
    required this.label,
    required this.counter,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: disabled
                  ? const Color(0xFF1B3A4B)
                  : const Color(0xFF00D1C1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text('$label  $counter', style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
