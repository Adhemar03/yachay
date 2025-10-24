import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
    debugPrint('Render MCQ: correctIndex=$correctIndex, selectedIndex=$selectedIndex, showFeedback=$showFeedback');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24), // reducido desde 64 a 24
        TextField(
          controller: TextEditingController(text: question),
          readOnly: true,
          minLines: 3,
          maxLines: 3,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(options.length, (i) {
          final letras = ['A', 'B', 'C', 'D'];
          final letra = (i < letras.length) ? letras[i] : String.fromCharCode(65 + i);
          Color bgColor = Colors.white;
          Color fgColor = Colors.black;
          if (showFeedback) {
            // If feedback is showing, highlight the correct option green.
            if (i == correctIndex) {
              bgColor = Colors.green;
              fgColor = Colors.white;
            } else if (selectedIndex != null && i == selectedIndex && selectedIndex != correctIndex) {
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
              onPressed: (showFeedback && selectedIndex != null) ? null : () => onSelected(i),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                : (selectedIndex != null && i == selectedIndex && selectedIndex != correctIndex)
                  ? Colors.red
                  : Colors.grey)
              : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                        ),
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
                  Expanded(child: Text(options[i], style: TextStyle(color: fgColor))),
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
                if (i == correctIndex) borderColor = Colors.green;
                // If user selected a wrong one, mark it red
                else if (selectedIndex != null && i == selectedIndex && selectedIndex != correctIndex) borderColor = Colors.red;
                else borderColor = Colors.white.withOpacity(0.12);
              }
              return GestureDetector(
                onTap: (showFeedback && selectedIndex != null) ? null : () => onSelected(i),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: borderColor == Colors.transparent ? 0 : 4),
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
  State<AudioRecognitionQuestion> createState() => _AudioRecognitionQuestionState();
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
        (oldWidget.audioUrls.isNotEmpty && widget.audioUrls.isNotEmpty && oldWidget.audioUrls.first != widget.audioUrls.first)) {
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
    debugPrint('Render AudioQ: correctIndex=${widget.correctIndex}, selectedIndex=${widget.selectedIndex}, showFeedback=${widget.showFeedback}');
    final letras = ['A', 'B', 'C', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48), // reducido desde 128 a 48
        Text(
          widget.question,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
            const Text('Reproduciendo...', style: TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.options.length, (i) {
          final letra = (i < letras.length) ? letras[i] : String.fromCharCode(65 + i);
          Color bgColor = Colors.white;
          Color fgColor = Colors.black;
          if (widget.showFeedback) {
            if (i == widget.correctIndex) {
              bgColor = Colors.green;
              fgColor = Colors.white;
            } else if (widget.selectedIndex != null && i == widget.selectedIndex && widget.selectedIndex != widget.correctIndex) {
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
              onPressed: (widget.showFeedback && widget.selectedIndex != null) ? null : () => widget.onSelected(i),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                              : (widget.selectedIndex != null && i == widget.selectedIndex && widget.selectedIndex != widget.correctIndex)
                                  ? Colors.red
                                  : Colors.grey)
                          : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                        ),
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
                  Expanded(child: Text(widget.options[i], style: TextStyle(color: fgColor))),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class FillInTheBlankQuestion extends StatelessWidget {
  final String question;
  final void Function(String) onSubmitted;

  const FillInTheBlankQuestion({
    Key? key,
    required this.question,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48), // reducido desde 128 a 48
        Text(
          question,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Completa la frase',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => onSubmitted(controller.text),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
