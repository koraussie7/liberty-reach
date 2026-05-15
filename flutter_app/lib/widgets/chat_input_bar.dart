import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/design_system/design_system.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isAiChat;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final ValueChanged<String> onVoiceResult;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.isLoading = false,
    this.isAiChat = false,
    required this.onSend,
    required this.onPickImage,
    required this.onVoiceResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(left: 4, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          // Loops upload button
          _IconBtn(icon: Icons.video_library, color: AppColors.primary, onTap: () => _uploadLoopsVideo(context)),
          const SizedBox(width: 2),
          // Image picker
          _IconBtn(icon: Icons.add_circle_outline, color: Colors.grey, onTap: isAiChat ? onPickImage : null),
          const SizedBox(width: 4),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isAiChat ? 'AI 채팅 또는 Loops 업로드...' : 'Message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Voice button
          VoiceInputButton(onVoiceResult: onVoiceResult),
          const SizedBox(width: 4),
          // Send button
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey[700] : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(isLoading ? Icons.hourglass_top : Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadLoopsVideo(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
    if (video == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 12), Text('업로드 중...')]),
      backgroundColor: AppColors.primary,
      duration: Duration(seconds: 30),
    ));

    try {
      final bytes = await video.readAsBytes();
      final b64 = base64Encode(bytes);
      final caption = controller.text.isNotEmpty ? controller.text : 'Loops 영상 공유';

      final resp = await http.post(
        Uri.parse('http://185.55.243.225:8000/loops/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video': b64, 'caption': caption, 'user_id': 'current_user'}),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final points = data['reward_points'] ?? 50;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Loops 업로드 완료! (+$points DADA Point)'),
            backgroundColor: AppColors.primary,
          ));
          controller.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드 실패'), backgroundColor: AppColors.error));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드 실패 - 서버 연결 오류'), backgroundColor: AppColors.error));
      }
    }
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, color: color), onPressed: onTap);
  }
}

class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onVoiceResult;
  const VoiceInputButton({super.key, required this.onVoiceResult});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => debugPrint('[Voice] recording...'),
      onLongPressEnd: (_) => debugPrint('[Voice] stopped'),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
        child: const Icon(Icons.mic, color: Colors.white70, size: 18),
      ),
    );
  }
}
