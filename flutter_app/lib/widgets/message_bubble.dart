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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSender && !isMe && message.isAI)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEE500).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 10, color: Color(0xFF8B7E00)),
                            const SizedBox(width: 3),
                            Text(message.sender, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8B7E00))),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: EdgeInsets.only(
                    left: 14, right: 14,
                    top: message.hasImages ? 6 : 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isAI ? Colors.grey[100] : isMe ? const Color(0xFFFEE500) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2, offset: const Offset(0, 1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isLoading)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFEE500))),
                            SizedBox(width: 8),
                            Text('분석 중...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        )
                      else ...[
                        if (message.hasImages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(message.imagePaths.first),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                              ),
                            ),
                          ),
                        SelectableText(message.content, style: const TextStyle(fontSize: 15, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateFormat('HH:mm').format(message.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    Icon(message.isRead ? Icons.done_all : Icons.done, size: 14,
                        color: message.isRead ? const Color(0xFFFEE500) : Colors.grey[400]),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
