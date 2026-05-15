import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';

class VoiceInputButton extends StatelessWidget {
  final Function(String) onVoiceResult;

  const VoiceInputButton({super.key, required this.onVoiceResult});

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();

    return GestureDetector(
      onLongPressStart: (_) async {
        await speech.startListening('한국어', onVoiceResult);
      },
      onLongPressEnd: (_) async {
        await speech.stopListening();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: speech.isListening ? Colors.red.shade400 : Colors.deepPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (speech.isListening ? Colors.red : Colors.deepPurple)
                  .withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: speech.isListening ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          speech.isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
