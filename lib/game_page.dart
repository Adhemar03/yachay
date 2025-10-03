import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'question_widgets.dart';

import 'dart:async';

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
      .eq('question_type', 'multiple_choice');
      if (widget.nivel != null && widget.nivel!.isNotEmpty) {
        query = query.eq('difficulty', widget.nivel!.toLowerCase() as Object);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      //debugPrint('Parámetros de consulta: nivel=${widget.nivel?.toLowerCase()}, categoryId=$categoryId');
      final res = await query.limit(10); // Trae más para barajar
      //debugPrint('Resultado de preguntas: $res');
      final preguntasList = List<Map<String, dynamic>>.from(res);
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

  void _nextQuestion() {
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
      // Fin de la partida
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Fin de la partida!'),
          content: const Text('Has respondido todas las preguntas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      );
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
                          MultipleChoiceQuestion(
                            question: preguntas[current]['question_text'],
                            options: (preguntas[current]['answer_data']['options'] as List)
                                .map<String>((opt) => opt['text'] as String)
                                .toList(),
                            selectedIndex: selectedIndex,
                            correctIndex: _getCorrectIndex(),
                            showFeedback: showFeedback,
                            onSelected: (i) async {
                              timer?.cancel();
                              final correct = _getCorrectIndex();
                              debugPrint('Índice de la opción correcta: $correct');
                              setState(() {
                                selectedIndex = i;
                                showFeedback = true;
                              });
                              await Future.delayed(const Duration(seconds: 2));
                              setState(() {
                                showingExplanation = true;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          Text('Pregunta ${current + 1} de ${preguntas.length}'),
                          // const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                timer?.cancel();
                                Navigator.of(context).popUntil((r) => r.isFirst);
                              },
                              child: const Text('Terminar partida y volver al inicio'),
                            ),
                          ),
                        ],
                      )),
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

  int? _getCorrectIndex() {
    final options = (preguntas[current]['answer_data']['options'] as List);
    for (int i = 0; i < options.length; i++) {
      if (options[i]['isCorrect'] == true) {
        debugPrint('Índice de la opción correcta: $i');
        return i;
      }
    }
    return null;
  }
}