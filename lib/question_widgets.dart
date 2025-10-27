import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui' as ui;
import 'package:yachay/core/app_colors.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final int? correctIndex;
  final void Function(int) onSelected;
  final bool showFeedback;

  const MultipleChoiceQuestion({
    Key? key,
    required this.question,
    required this.options,
    required this.onSelected,
    this.selectedIndex,
    this.correctIndex,
    this.showFeedback = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Render MCQ: correctIndex=$correctIndex, selectedIndex=$selectedIndex, showFeedback=$showFeedback',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24), // reducido desde 64 a 24
        TextField(
          controller: TextEditingController(text: question),
          readOnly: true,
          minLines: 3,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(options.length, (i) {
          final letras = ['A', 'B', 'C', 'D'];
          final letra = (i < letras.length)
              ? letras[i]
              : String.fromCharCode(65 + i);
          Color bgColor = Colors.white;
          Color fgColor = Colors.black;
          if (showFeedback) {
            // If feedback is showing, highlight the correct option green.
            if (i == correctIndex) {
              bgColor = Colors.green;
              fgColor = Colors.white;
            } else if (selectedIndex != null &&
                i == selectedIndex &&
                selectedIndex != correctIndex) {
              // If the user selected a wrong answer, mark it red.
              bgColor = Colors.red;
              fgColor = Colors.white;
            } else {
              bgColor = Colors.white;
              fgColor = Colors.black;
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: (showFeedback && selectedIndex != null)
                  ? null
                  : () => onSelected(i),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                disabledBackgroundColor: bgColor,
                disabledForegroundColor: fgColor,
                elevation: 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (showFeedback)
                          ? (i == correctIndex
                                ? Colors.green
                                : (selectedIndex != null &&
                                      i == selectedIndex &&
                                      selectedIndex != correctIndex)
                                ? Colors.red
                                : Colors.grey)
                          : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 2),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letra,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(options[i], style: TextStyle(color: fgColor)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class ImageRecognitionQuestion extends StatelessWidget {
  final String question;
  final List<String> imageUrls;
  final int? selectedIndex;
  final int? correctIndex;
  final bool showFeedback;
  final void Function(int) onSelected;

  const ImageRecognitionQuestion({
    Key? key,
    required this.question,
    required this.imageUrls,
    required this.onSelected,
    this.selectedIndex,
    this.correctIndex,
    this.showFeedback = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12), // reducido desde 32 a 12
        Text(
          question,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(imageUrls.length, (i) {
              Color borderColor = Colors.transparent;
              if (showFeedback) {
                // Always highlight correct answer when showing feedback
                if (i == correctIndex)
                  borderColor = Colors.green;
                // If user selected a wrong one, mark it red
                else if (selectedIndex != null &&
                    i == selectedIndex &&
                    selectedIndex != correctIndex)
                  borderColor = Colors.red;
                else
                  borderColor = Colors.white.withOpacity(0.12);
              }
              return GestureDetector(
                onTap: (showFeedback && selectedIndex != null)
                    ? null
                    : () => onSelected(i),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: borderColor == Colors.transparent ? 0 : 4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(imageUrls[i], fit: BoxFit.cover),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class AudioRecognitionQuestion extends StatefulWidget {
  final String question;
  // se acepta una lista de urls o una sola; aquí usamos la primera si vienen varias
  final List<String> audioUrls;
  final List<String> options;
  final int? selectedIndex;
  final int? correctIndex;
  final bool showFeedback;
  final void Function(int) onSelected;

  const AudioRecognitionQuestion({
    Key? key,
    required this.question,
    required this.audioUrls,
    required this.options,
    required this.onSelected,
    this.selectedIndex,
    this.correctIndex,
    this.showFeedback = false,
  }) : super(key: key);

  @override
  State<AudioRecognitionQuestion> createState() =>
      _AudioRecognitionQuestionState();
}

class _AudioRecognitionQuestionState extends State<AudioRecognitionQuestion> {
  late final AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _startPlayback();
  }

  Future<void> _startPlayback() async {
    final url = (widget.audioUrls.isNotEmpty) ? widget.audioUrls.first : '';
    if (url.isEmpty) return;
    try {
      // Autoplay audio when question is shown
      await _player.setSourceUrl(url);
      await _player.resume();
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
    }
  }

  @override
  void didUpdateWidget(covariant AudioRecognitionQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia la pregunta/audio reiniciamos reproducción
    if (oldWidget.audioUrls.isEmpty && widget.audioUrls.isNotEmpty ||
        (oldWidget.audioUrls.isNotEmpty &&
            widget.audioUrls.isNotEmpty &&
            oldWidget.audioUrls.first != widget.audioUrls.first)) {
      _player.stop();
      _startPlayback();
    }
    // Si mostramos feedback, podemos pausar el audio
    if (widget.showFeedback && _isPlaying) {
      _player.pause();
      setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Render AudioQ: correctIndex=${widget.correctIndex}, selectedIndex=${widget.selectedIndex}, showFeedback=${widget.showFeedback}',
    );
    final letras = ['A', 'B', 'C', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48), // reducido desde 128 a 48
        Text(
          widget.question,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Indicador de reproducción simple
        Row(
          children: [
            IconButton(
              onPressed: () async {
                if (_isPlaying) {
                  await _player.pause();
                  setState(() => _isPlaying = false);
                } else {
                  await _player.resume();
                  setState(() => _isPlaying = true);
                }
              },
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Reproduciendo...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.options.length, (i) {
          final letra = (i < letras.length)
              ? letras[i]
              : String.fromCharCode(65 + i);
          Color bgColor = Colors.white;
          Color fgColor = Colors.black;
          if (widget.showFeedback) {
            if (i == widget.correctIndex) {
              bgColor = Colors.green;
              fgColor = Colors.white;
            } else if (widget.selectedIndex != null &&
                i == widget.selectedIndex &&
                widget.selectedIndex != widget.correctIndex) {
              bgColor = Colors.red;
              fgColor = Colors.white;
            } else {
              bgColor = Colors.white;
              fgColor = Colors.black;
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: (widget.showFeedback && widget.selectedIndex != null)
                  ? null
                  : () => widget.onSelected(i),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                disabledBackgroundColor: bgColor,
                disabledForegroundColor: fgColor,
                elevation: 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (widget.showFeedback)
                          ? (i == widget.correctIndex
                                ? Colors.green
                                : (widget.selectedIndex != null &&
                                      i == widget.selectedIndex &&
                                      widget.selectedIndex !=
                                          widget.correctIndex)
                                ? Colors.red
                                : Colors.grey)
                          : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 2),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letra,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.options[i],
                      style: TextStyle(color: fgColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Reemplaza la implementación anterior con esta nueva clase en question_widgets.dart
class FillInTheBlankDragQuestion extends StatefulWidget {
  final String question;
  final List<String> options;
  final int?
  selectedIndex; // índice seleccionado por el jugador (desde GamePage)
  final int? correctIndex; // índice correcto (desde GamePage)
  final bool
  showFeedback; // si hay que mostrar feedback (GamePage controla esto)
  final void Function(int)
  onDropped; // callback cuando el usuario suelta una opción

  const FillInTheBlankDragQuestion({
    Key? key,
    required this.question,
    required this.options,
    required this.onDropped,
    this.selectedIndex,
    this.correctIndex,
    this.showFeedback = false,
  }) : super(key: key);

  @override
  State<FillInTheBlankDragQuestion> createState() =>
      _FillInTheBlankDragQuestionState();
}

class _FillInTheBlankDragQuestionState
    extends State<FillInTheBlankDragQuestion> {
  int? _localDroppedIndex;

  @override
  void initState() {
    super.initState();
    _localDroppedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant FillInTheBlankDragQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza estado local si cambió desde el padre
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _localDroppedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar qué mostrar en el "espacio en blanco" cuando se muestran feedback
    int? displayIndex;
    if (widget.showFeedback) {
      // Si el usuario ya seleccionó, mostrar su selección (y colorear según correcto/incorrecto).
      // Si no seleccionó y showFeedback es true (tiempo acabado), mostrar la opción correcta.
      displayIndex = widget.selectedIndex ?? widget.correctIndex;
    } else {
      // en modo normal mostrar lo que el usuario haya arrastrado localmente
      displayIndex = _localDroppedIndex;
    }

    // Color del espacio en blanco según estado
    Color blankColor = Colors.white;
    if (widget.showFeedback && displayIndex != null) {
      if (displayIndex == widget.correctIndex) {
        blankColor = Colors.green;
      } else {
        blankColor = Colors.red;
      }
    }

    // estilo del texto de la pregunta (reutilizable para medir ancho de puntos)
    final questionStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    // buscar la primera secuencia de puntos (2 o más)
    final match = RegExp(r'\.{2,}').firstMatch(widget.question);

    Widget buildDragTargetInline(double width) {
      final texto =
          (displayIndex != null && displayIndex < widget.options.length)
          ? widget.options[displayIndex]
          : null;

      return DragTarget<int>(
        onWillAccept: (data) {
          // No aceptar si ya mostramos feedback (bloqueo)
          return !widget.showFeedback && widget.selectedIndex == null;
        },
        onAccept: (data) {
          if (widget.showFeedback) return;
          setState(() {
            _localDroppedIndex = data;
          });
          widget.onDropped(data);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: width,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            // uso padding más pequeño para que quepa inline
            decoration: BoxDecoration(
              color: blankColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(
                texto ?? '__________',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: (widget.showFeedback && displayIndex != null)
                      ? Colors.white
                      : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }

    // Si hay una secuencia de puntos, renderizamos inline con WidgetSpan
    if (match != null) {
      final before = widget.question.substring(0, match.start);
      final dotStr = match.group(0) ?? '';
      final after = widget.question.substring(match.end);

      // Medir ancho visual de la secuencia de puntos para que el recuadro se ajuste
      final tp = TextPainter(
        text: TextSpan(text: dotStr, style: questionStyle),
        textDirection: Directionality.of(context),
        maxLines: 1,
      );
      tp.layout();
      // Ajustes mínimos/máximos para que no quede demasiado pequeño o demasiado largo inline
      final maxWidth = MediaQuery.of(context).size.width * 0.7;
      double inlineWidth = tp.width.clamp(80.0, maxWidth);

      // Construir el RichText con WidgetSpan
      final rich = RichText(
        text: TextSpan(
          children: [
            TextSpan(text: before, style: questionStyle),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: buildDragTargetInline(inlineWidth),
              ),
            ),
            TextSpan(text: after, style: questionStyle),
          ],
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Aquí se muestra la pregunta con el DragTarget reemplazando los puntos inline
          rich,
          const SizedBox(height: 18),
          // Opciones (Draggable) - mantenemos igual que antes
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(widget.options.length, (i) {
              // Determinar color visual de la opción según feedback
              Color bg = Colors.white;
              Color textColor = Colors.black;
              if (widget.showFeedback) {
                if (i == widget.correctIndex) {
                  bg = Colors.green;
                  textColor = Colors.white;
                } else if (widget.selectedIndex != null &&
                    i == widget.selectedIndex &&
                    widget.selectedIndex != widget.correctIndex) {
                  bg = Colors.red;
                  textColor = Colors.white;
                } else {
                  bg = Colors.white;
                  textColor = Colors.black;
                }
              }

              final optionChip = Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                constraints: const BoxConstraints(minWidth: 120),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: Text(
                  widget.options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              );

              // Desactivar draggable si ya mostramos feedback o si ya se ha seleccionado
              final disabled =
                  widget.showFeedback || widget.selectedIndex != null;

              return Opacity(
                opacity:
                    disabled && widget.selectedIndex != i && widget.showFeedback
                    ? 0.8
                    : 1.0,
                child: Draggable<int>(
                  data: i,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: optionChip,
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.4, child: optionChip),
                  maxSimultaneousDrags: disabled ? 0 : 1,
                  child: optionChip,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          if (!widget.showFeedback)
            const Text(
              'Arrastra una opción al recuadro.',
              style: TextStyle(color: Colors.white70),
            ),
          if (widget.showFeedback)
            const Text(
              'La respuesta correcta era',
              style: TextStyle(color: Colors.white70),
            ),
        ],
      );
    }

    // Si no hay puntos en la pregunta, se comporta como antes (drag target debajo)
    final texto = (displayIndex != null && displayIndex < widget.options.length)
        ? widget.options[displayIndex]
        : 'Arrastra la respuesta aquí';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Mostrar la pregunta
        Text(widget.question, style: questionStyle),
        const SizedBox(height: 16),
        // Espacio en blanco (DragTarget) debajo (comportamiento legacy)
        Center(
          child: DragTarget<int>(
            onWillAccept: (data) {
              // No aceptar si ya mostramos feedback (bloqueo)
              return !widget.showFeedback && widget.selectedIndex == null;
            },
            onAccept: (data) {
              if (widget.showFeedback) return;
              setState(() {
                _localDroppedIndex = data;
              });
              widget.onDropped(data);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: blankColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: (widget.showFeedback && displayIndex != null)
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        // Opciones (Draggable) - igual que antes
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(widget.options.length, (i) {
            Color bg = Colors.white;
            Color textColor = Colors.black;
            if (widget.showFeedback) {
              if (i == widget.correctIndex) {
                bg = Colors.green;
                textColor = Colors.white;
              } else if (widget.selectedIndex != null &&
                  i == widget.selectedIndex &&
                  widget.selectedIndex != widget.correctIndex) {
                bg = Colors.red;
                textColor = Colors.white;
              } else {
                bg = Colors.white;
                textColor = Colors.black;
              }
            }

            final optionChip = Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              constraints: const BoxConstraints(minWidth: 120),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2),
                ],
              ),
              child: Text(
                widget.options[i],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            );

            final disabled =
                widget.showFeedback || widget.selectedIndex != null;

            return Opacity(
              opacity:
                  disabled && widget.selectedIndex != i && widget.showFeedback
                  ? 0.8
                  : 1.0,
              child: Draggable<int>(
                data: i,
                feedback: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: optionChip,
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.4, child: optionChip),
                maxSimultaneousDrags: disabled ? 0 : 1,
                child: optionChip,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        if (!widget.showFeedback)
          const Text(
            'Arrastra una opción al recuadro.',
            style: TextStyle(color: Colors.white70),
          ),
        if (widget.showFeedback)
          const Text(
            'Mostrando respuesta correcta.',
            style: TextStyle(color: Colors.white70),
          ),
      ],
    );
  }
}
