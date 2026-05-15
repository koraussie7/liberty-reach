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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // --- Sender Label ---
          if (showSender && !isMe && message.isAI)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4, top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEE500), Color(0xFFFFD54F)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 11, color: Colors.brown),
                    const SizedBox(width: 4),
                    Text(
                      message.sender,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.brown,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showSender && !isMe && !message.isAI)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2, top: 6),
              child: Text(
                message.sender,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),

          // --- Content (No Bubble!) ---
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Loading indicator
                    if (message.isLoading)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFFEE500),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '생각 중...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Image preview
                      if (message.hasImages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(message.imagePaths.first),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                            ),
                          ),
                        ),
                      // Text (no bubble, no background!)
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isMe ? const Color(0xFF1A1A2E) : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                    // Timestamp
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
