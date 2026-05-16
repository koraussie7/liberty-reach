import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';

class SpeechLanguageSettings extends StatelessWidget {
  const SpeechLanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Recognition Language'),
      ),
      body: ListView.separated(
        itemCount: speech.supportedLocales.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final lang = speech.supportedLocales.keys.elementAt(index);
          final locale = speech.supportedLocales.values.elementAt(index);
          final isSelected = locale == speech.currentLocale;

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
            onTap: () => speech.setLocale(lang),
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
