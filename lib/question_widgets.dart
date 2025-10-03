import 'package:flutter/material.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  final String question;
  final List<String> options;
  final void Function(int) onSelected;

  const MultipleChoiceQuestion({
    Key? key,
    required this.question,
    required this.options,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 128),
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => onSelected(i),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
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
                      Expanded(child: Text(options[i], style: const TextStyle(color: Colors.black))),
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
  final void Function(int) onSelected;

  const ImageRecognitionQuestion({
    Key? key,
    required this.question,
    required this.imageUrls,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            const SizedBox(height: 128),
        Text(
          question,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(imageUrls.length, (i) => GestureDetector(
            onTap: () => onSelected(i),
            child: Image.network(imageUrls[i], width: 100, height: 100),
          )),
        ),
      ],
    );
  }
}

class AudioRecognitionQuestion extends StatelessWidget {
  final String question;
  final List<String> audioUrls;
  final List<String> options;
  final void Function(int) onSelected;

  const AudioRecognitionQuestion({
    Key? key,
    required this.question,
    required this.audioUrls,
    required this.options,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nota: Para reproducir audio real, se recomienda usar un paquete como audioplayers
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            const SizedBox(height: 128),
        Text(
          question,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        // Aquí solo se muestra un botón simulado para cada audio
        ...List.generate(audioUrls.length, (i) =>
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: () {
                // Aquí iría la lógica para reproducir el audio
                onSelected(i);
              },
              child: Text('Reproducir audio ${i + 1}'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(options.length, (i) =>
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: () => onSelected(i),
              child: Text(options[i]),
            ),
          ),
        ),
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
            const SizedBox(height: 128),
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
