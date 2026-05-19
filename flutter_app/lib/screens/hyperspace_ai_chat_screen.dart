import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hyperspace_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class HyperspaceAIChatScreen extends StatefulWidget {
  const HyperspaceAIChatScreen({super.key});

  @override
  State<HyperspaceAIChatScreen> createState() => _HyperspaceAIChatScreenState();
}

class _HyperspaceAIChatScreenState extends State<HyperspaceAIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedModel = 'gemma-2-2b-it';
  int _lastMsgCount = 0;
  bool _autoTts = true;

  final List<String> _defaultModels = [
    'gemma-2-2b-it',
    'gemma-2-9b-it',
    'llama-3-8b-instruct',
    'mistral-7b-instruct',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final hs = context.read<HyperspaceService>();
    hs.chat(text, model: _selectedModel);
    _scrollToBottom();
  }

  // --- STT ---

  Future<void> _startStt() async {
    final stt = context.read<SttService>();
    await stt.startListening(language: 'ko-KR');
  }

  Future<void> _stopStt() async {
    final stt = context.read<SttService>();
    final text = await stt.stopListening();
    if (text.isNotEmpty) {
      _messageController.text = text;
      _sendMessage();
    }
  }

  // --- TTS is handled inline in build() ---

  @override
  Widget build(BuildContext context) {
    final hs = context.watch<HyperspaceService>();
    final sttService = context.watch<SttService>();
    final allModels = [
      ..._defaultModels,
      ...hs.availableModels.where((m) => !_defaultModels.contains(m)),
    ];

    // TTS on new AI response (only once per new message)
    if (_autoTts && hs.messages.length > _lastMsgCount) {
      _lastMsgCount = hs.messages.length;
      final lastMsg = hs.messages.last;
      if (!lastMsg.isUser && lastMsg.text.isNotEmpty && !lastMsg.isError) {
        try {
          context.read<TtsService>().speak(lastMsg.text);
        } catch (_) {}
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          // TTS toggle
          IconButton(
            icon: Icon(
              _autoTts ? Icons.volume_up : Icons.volume_off,
              size: 20,
              color: _autoTts ? Theme.of(context).primaryColor : Colors.grey,
            ),
            tooltip: _autoTts ? 'Voice ON' : 'Voice OFF',
            onPressed: () => setState(() => _autoTts = !_autoTts),
          ),
          // Model selector
          PopupMenuButton<String>(
            initialValue: _selectedModel,
            icon: const Icon(Icons.model_training),
            tooltip: 'Select Model',
            onSelected: (model) {
              setState(() => _selectedModel = model);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Model: $model'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            itemBuilder: (context) => allModels.map((model) {
              return PopupMenuItem<String>(
                value: model,
                child: Row(
                  children: [
                    Icon(
                      model == _selectedModel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        model,
                        style: TextStyle(
                          fontWeight: model == _selectedModel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // STT listening bar
          if (sttService.isListening || sttService.state == SttState.error)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEE500).withOpacity(0.2),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sttService.lastError.isNotEmpty
                          ? '⚠️ ${sttService.lastError}'
                          : sttService.interimText.isNotEmpty
                              ? sttService.interimText
                              : '🎤 말해보세요...',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _stopStt,
                    child: const Icon(Icons.stop, color: Colors.red),
                  ),
                ],
              ),
            ),
          // Chat messages
          Expanded(
            child: hs.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: hs.messages.length,
                    itemBuilder: (context, index) {
                      final msg = hs.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          // Model indicator
          if (_selectedModel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Text(
                'Model: $_selectedModel',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              child: Row(
                children: [
                  // STT button
                  IconButton(
                    icon: sttService.isListening
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.keyboard_voice, color: Colors.grey),
                    tooltip: sttService.isListening ? 'Stop' : 'Speech to text',
                    onPressed: sttService.isListening ? _stopStt : _startStt,
                  ),
                  const SizedBox(width: 4),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask AI anything...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !hs.chatLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 22,
                    child: IconButton(
                      icon: hs.chatLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                      onPressed: hs.chatLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ask the AI anything',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Powered by Hyperspace P2P AI',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  msg.isError ? Colors.red.shade100 : Colors.blue.shade100,
              child: Icon(
                msg.isError ? Icons.error_outline : Icons.smart_toy,
                size: 18,
                color: msg.isError ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                    ),
                  ),
                  if (!isUser && msg.model.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        msg.model,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
