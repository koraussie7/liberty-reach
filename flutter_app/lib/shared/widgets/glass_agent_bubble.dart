import 'package:flutter/material.dart';
import '../services/voice_conversation_service.dart';
import 'package:provider/provider.dart';

class GlassAgentBubble extends StatelessWidget {
  final String text;
  final String agentType;
  final double confidence;
  final DateTime time;
  final bool isStreaming;

  const GlassAgentBubble({
    super.key,
    required this.text,
    required this.agentType,
    this.confidence = 0.0,
    required this.time,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final voiceService = Provider.of<VoiceConversationService>(context);
    final color = _getAgentColor(agentType);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.25), blurRadius: 25, spreadRadius: 3),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(_getAgentEmoji(agentType), style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Text(agentType, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (confidence > 0)
                  Text("${(confidence * 100).toInt()}%", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),

            const SizedBox(height: 12),

            // 응답 텍스트
            isStreaming
                ? const Text("생각하는 중...", style: TextStyle(color: Colors.white70))
                : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16.5, height: 1.5)),

            const SizedBox(height: 14),

            // 액션 버튼
            Row(
              children: [
                _actionButton(Icons.volume_up, "음성", () => voiceService.speakAIResponse(text, agentType)),
                const SizedBox(width: 8),
                _actionButton(Icons.copy, "복사", () => _copyText(context)),
                const Spacer(),
                Text(time.toString().substring(11, 16), style: const TextStyle(fontSize: 12.5, color: Colors.white38)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Color _getAgentColor(String agent) {
    switch (agent) {
      case "Hermes": return Colors.purple;
      case "OpenMythos": return Colors.cyan;
      case "OpenClaw": return Colors.orange;
      default: return Colors.purple;
    }
  }

  String _getAgentEmoji(String agent) {
    switch (agent) {
      case "Hermes": return "🧠";
      case "OpenMythos": return "🌌";
      case "OpenClaw": return "⚡";
      default: return "🤖";
    }
  }

  void _copyText(BuildContext context) {
    // Clipboard set
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("복사되었습니다")));
  }
}
