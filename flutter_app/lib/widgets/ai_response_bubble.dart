import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../core/design_system/design_system.dart';

class AIResponseBubble extends StatelessWidget {
  final String text;
  final String agentType;
  final double confidence;
  final DateTime time;
  final bool isLoading;

  const AIResponseBubble({
    super.key,
    required this.text,
    required this.agentType,
    this.confidence = 0.0,
    required this.time,
    this.isLoading = false,
  });

  Color get _agentColor {
    switch (agentType) {
      case 'Gemini AI':
        return AppColors.agentGemini;
      case 'Hyperspace P2P':
        return AppColors.agentHyperspaceP2P;
      case 'Hyperspace':
        return AppColors.agentHyperspace;
      default:
        return AppColors.agentHermes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          padding: const EdgeInsets.all(16),
          decoration: GlassStyle.defaultStyle(
            borderRadius: 20,
            borderWidth: 1.0,
            borderColor: Colors.white.withOpacity(0.12),
            glowColor: _agentColor,
            glowRadius: 24,
            gradientColors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.03)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _agentColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: _agentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    agentType,
                    style: TextStyle(
                      color: _agentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (confidence > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _agentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(confidence * 100).toInt()}%',
                        style: TextStyle(fontSize: 11, color: _agentColor.withOpacity(0.9)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                    SizedBox(width: 10),
                    Text('Thinking...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                )
              else
                SelectableText(
                  text,
                  style: AppTextStyles.bodyMedium,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ControlButton(icon: Icons.volume_up, label: 'Voice', onTap: () {
                    context.read<TTSService>().speak(text);
                  }),
                  const SizedBox(width: 8),
                  _ControlButton(icon: Icons.copy, label: 'Copy', onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                    );
                  }),
                  const Spacer(),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
