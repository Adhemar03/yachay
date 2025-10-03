import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'question_widgets.dart';

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

class _GamePageState extends State<GamePage> {
  List<Map<String, dynamic>> preguntas = [];
  bool loading = true;
  int current = 0;

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
        debugPrint('Buscando categoría por nombre: "${widget.categoria}"');
        final catRes = await Supabase.instance.client
            .from('categories')
            .select('category_id, name')
            .ilike('name', '%${widget.categoria ?? ''}%')
            .maybeSingle();
        debugPrint('Resultado consulta categoría: $catRes');
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
      debugPrint('Parámetros de consulta: nivel=${widget.nivel?.toLowerCase()}, categoryId=$categoryId');
      final res = await query.limit(10); // Trae más para barajar
      debugPrint('Resultado de preguntas: $res');
      final preguntasList = List<Map<String, dynamic>>.from(res);
      preguntasList.shuffle();
      setState(() {
        preguntas = preguntasList.take(5).toList();
        loading = false;
        current = 0;
      });
    } catch (e) {
      setState(() { loading = false; });
      debugPrint('Error al cargar preguntas: $e');
    }
  }

  void _nextQuestion() {
    if (current < preguntas.length - 1) {
      setState(() { current++; });
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      const SizedBox(height: 32),
                      MultipleChoiceQuestion(
                        question: preguntas[current]['question_text'],
                        options: (preguntas[current]['answer_data']['options'] as List)
                            .map<String>((opt) => opt['text'] as String)
                            .toList(),
                        onSelected: (i) {
                          // Aquí puedes validar la respuesta y mostrar feedback
                          _nextQuestion();
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Pregunta ${current + 1} de ${preguntas.length}'),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: const Text('Terminar partida y volver al inicio'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
