import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/isek_service.dart';

/// A2A Chat — communicate with any ISEK agent via the Google A2A protocol.
///
/// Supports manual URL entry, a chat-like message history, and re-sending
/// messages to the same agent.
class ISEKA2AChatScreen extends StatefulWidget {
  /// Optional pre-filled target agent URL.
  final String? initialTargetUrl;

  /// Optional pre-filled agent name.
  final String? initialAgentName;

  const ISEKA2AChatScreen({
    super.key,
    this.initialTargetUrl,
    this.initialAgentName,
  });

  @override
  State<ISEKA2AChatScreen> createState() => _ISEKA2AChatScreenState();
}

class _ISEKA2AChatScreenState extends State<ISEKA2AChatScreen> {
  final _urlController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatEntry> _messages = [];
  bool _sending = false;

  String get _targetUrl => _urlController.text.trim();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialTargetUrl ?? 'http://localhost:9999';
    if (widget.initialAgentName != null) {
      _messages.add(_ChatEntry(
        text: 'Connected to ${widget.initialAgentName}',
        isUser: false,
        isSystem: true,
      ));
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final query = _messageController.text.trim();
    if (query.isEmpty || _targetUrl.isEmpty) return;

    setState(() {
      _messages.add(_ChatEntry(text: query, isUser: true));
      _sending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final isek = context.read<ISEKService>();
    final response = await isek.sendA2A(_targetUrl, query);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatEntry(
        text: response,
        isUser: false,
        error: response.startsWith('(ISEK error') || response.startsWith('(error'),
      ));
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ISEK A2A Chat')),
      body: Column(
        children: [
          // ── Target URL field ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            color: theme.colorScheme.surfaceContainerHighest,
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Target Agent URL',
                hintText: 'http://host:port',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: 'Connect & send',
                  onPressed: _sending ? null : _sendMessage,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          // ── Message list ─────────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Enter a target agent URL above, then\n'
                          'type your message below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _MessageBubble(
                      entry: _messages[i],
                      theme: theme,
                    ),
                  ),
          ),

          // ── Input bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sending ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

class _ChatEntry {
  final String text;
  final bool isUser;
  final bool isSystem;
  final bool error;
  final DateTime timestamp;

  _ChatEntry({
    required this.text,
    required this.isUser,
    this.isSystem = false,
    this.error = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ---------------------------------------------------------------------------
// Message bubble widget
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, required this.theme});

  final _ChatEntry entry;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (entry.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.text,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final align = entry.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = entry.isUser
        ? theme.colorScheme.primary
        : (entry.error ? Colors.red.shade100 : Colors.grey.shade100);
    final textColor = entry.isUser ? Colors.white : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: entry.isUser ? const Radius.circular(16) : Radius.zero,
                bottomRight: entry.isUser ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: entry.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(entry.timestamp),
                  style: TextStyle(
                    color: textColor?.withOpacity(0.7) ?? Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
