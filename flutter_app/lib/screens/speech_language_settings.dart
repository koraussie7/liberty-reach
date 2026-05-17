import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';

class SpeechLanguageSettings extends StatelessWidget {
  const SpeechLanguageSettings({super.key});

  static const Map<String, String> _supportedLocales = {
    'English (US)': 'en-US',
    'Korean': 'ko-KR',
    'Japanese': 'ja-JP',
    'Chinese': 'zh-CN',
    'Vietnamese': 'vi-VN',
    'Thai': 'th-TH',
    'Spanish': 'es-ES',
    'French': 'fr-FR',
  };

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Recognition Language'),
      ),
      body: ListView.separated(
        itemCount: _supportedLocales.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final lang = _supportedLocales.keys.elementAt(index);
          final locale = _supportedLocales.values.elementAt(index);
          final isSelected = locale == speech.language;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? Colors.deepPurple.withValues(alpha: 0.1)
                  : Colors.grey[100],
              child: Text(
                _flagFor(locale),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(locale, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                : null,
            onTap: () => speech.setLanguage(locale),
          );
        },
      ),
    );
  }

  String _flagFor(String locale) {
    if (locale.contains('KR')) return '🇰🇷';
    if (locale.contains('US')) return '🇺🇸';
    if (locale.contains('JP')) return '🇯🇵';
    if (locale.contains('CN')) return '🇨🇳';
    if (locale.contains('VN')) return '🇻🇳';
    if (locale.contains('TH')) return '🇹🇭';
    if (locale.contains('ES')) return '🇪🇸';
    if (locale.contains('FR')) return '🇫🇷';
    return '🌐';
  }
}
