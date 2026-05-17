import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showSender;

  const MessageBubble({super.key, required this.message, this.showSender = true});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2.5),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // --- Sender label (AI only) ---
          if (showSender && !isMe && message.isAI)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3, top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 11, color: const Color(0xFF0088cc)),
                    const SizedBox(width: 4),
                    Text(
                      message.sender,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0088cc),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showSender && !isMe && !message.isAI)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2, top: 4),
              child: Text(
                message.sender,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF707579),
                ),
              ),
            ),

          // --- Content bubble ---
          if (message.isLoading)
            _buildBubble(
              isMe: isMe,
              context: context,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isMe ? Colors.white : const Color(0xFF0088cc),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '생각 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE8F4FD) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(message.imagePaths.first),
                          width: 200, height: 200, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: isMe ? const Color(0xFF000000) : const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? const Color(0xFF8E989F) : const Color(0xFFA1A5A8),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: message.isRead ? const Color(0xFF0088cc) : const Color(0xFF8E989F),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble({required bool isMe, required Widget child, required BuildContext context}) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE8F4FD) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
