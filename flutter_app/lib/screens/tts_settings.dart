import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';

class TTSSettingsScreen extends StatelessWidget {
  const TTSSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tts = context.watch<TTSService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Response Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('AI Voice Response'),
            subtitle: const Text('Automatically speak AI replies aloud'),
            value: tts.isEnabled,
            onChanged: (val) => tts.toggle(),
          ),
          const Divider(),
          ListTile(
            title: const Text('Speed'),
            subtitle: Slider(
              value: tts.speechRate,
              min: 0.5,
              max: 1.5,
              divisions: 10,
              label: tts.speechRate.toStringAsFixed(1),
              onChanged: tts.setSpeechRate,
            ),
          ),
          ListTile(
            title: const Text('Pitch'),
            subtitle: Slider(
              value: tts.pitch,
              min: 0.8,
              max: 1.2,
              divisions: 8,
              label: tts.pitch.toStringAsFixed(1),
              onChanged: tts.setPitch,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Current Language'),
            subtitle: Text(tts.currentLanguage),
          ),
        ],
      ),
    );
  }
}
