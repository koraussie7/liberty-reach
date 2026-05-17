import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/localai_service.dart';
import '../services/chat_service.dart';
import '../services/loops_service.dart';
import '../services/hybrid_ai_service.dart';
import '../services/voice_service.dart';
import '../services/speech_service.dart';
import '../services/group_chat_service.dart';
import '../services/video_call_service.dart';
import '../services/p2p_service.dart';
import 'package:provider/provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final bool isAI;
  final String? roomId;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.isAI = false,
    this.roomId,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final LocalAIService _ai = LocalAIService();
  late final ChatService _chat;
  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();
  late final LoopsService _loops;

  bool _isAiReady = false;
  bool _isLoading = false;
  List<String> _pendingImages = [];
  StreamSubscription? _chatSub;

  bool _isRecording = false;
  StreamSubscription? _voiceSub;

  bool _isUploadingVideo = false;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatService>();
    _loops = context.read<LoopsService>();
    _checkHealth();
    _ai.fetchModels();

    if (widget.roomId != null) {
      final groupService = context.read<GroupChatService>();
      _voiceSub = groupService.messageStream(widget.roomId!).listen((msgJson) {
        try {
          final data = jsonDecode(msgJson) as Map<String, dynamic>;
          final chatMsg = ChatMessage(
            id: _uuid.v4(),
            sender: data['sender'] as String? ?? 'unknown',
            content: data['content'] as String? ?? '',
            isMe: false,
            timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ?? DateTime.now(),
          );
          if (mounted) _addMessage(chatMsg);
        } catch (_) {}
      });
    } else {
      _chatSub = _chat.messages.listen((msg) {
        if (mounted) _addMessage(msg);
      });
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _voiceSub?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _ai.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    final ok = await _ai.health();
    if (mounted) setState(() => _isAiReady = ok);
  }

  String get _modelName {
    final m = _ai.selectedModel;
    if (m.startsWith('gemini')) return 'Gemini';
    return m;
  }

  void _addMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      if (mounted) setState(() => _pendingImages.add(b64));
    }
  }

  void _removePendingImage(int index) {
    setState(() => _pendingImages.removeAt(index));
  }

  Future<void> _pickAndUploadVideoToLoops() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null) return;

    setState(() => _isUploadingVideo = true);
    try {
      final bytes = await video.readAsBytes();
      final b64 = base64Encode(bytes);
      final caption = _textController.text.trim();
      final result = await _loops.uploadVideo(b64, caption);
      if (!mounted) return;
      if (result != null) {
        _textController.clear();
        final videoUrl = result['url'] as String? ?? '';
        final reward = result['reward_points'] as int? ?? 0;
        final fullUrl = 'https://muhantube.com$videoUrl';
        _addMessage(ChatMessage(
          id: _uuid.v4(), sender: 'me', content: '\u{1F3AC} $fullUrl', isMe: true,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u2705 Video uploaded! (+$reward DADA Point)'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingVideo = false);
    }
  }

  Future<void> _startVoiceRecording() async {
    final voiceService = context.read<VoiceService>();
    await voiceService.startRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopVoiceRecording() async {
    final voiceService = context.read<VoiceService>();
    final path = await voiceService.stopRecording();
    setState(() => _isRecording = false);
    if (path != null) {
      final bytes = await voiceService.getRecordingBytes();
      if (bytes != null) {
        final b64 = voiceService.encodeToBase64(bytes);
        if (widget.roomId != null) {
          context.read<P2PService>().broadcast(jsonEncode({
            'type': 'voice', 'sender': 'me', 'data': b64, 'room': widget.roomId,
          }), room: widget.roomId);
        } else {
          _chat.send('[Voice message]', widget.peerId);
        }
        _addMessage(ChatMessage(
          id: _uuid.v4(), sender: 'me', content: '\u{1F3A4} Voice message', isMe: true,
        ));
      }
    }
  }

  Future<void> _startSpeechToText() async {
    final speechService = context.read<SpeechService>();
    await speechService.startListening();
    setState(() {});
  }

  Future<void> _stopSpeechToText() async {
    final speechService = context.read<SpeechService>();
    final text = await speechService.stopListening();
    if (text.isNotEmpty) {
      _textController.text = text;
    }
    setState(() {});
  }

  Future<void> _startVideoCall() async {
    final callService = context.read<VideoCallService>();
    await callService.startCall(widget.peerId, widget.peerName);
    if (mounted) {
      Navigator.pushNamed(context, '/video-call');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if ((text.isEmpty && _pendingImages.isEmpty) || _isLoading) return;
    _textController.clear();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sender: 'me',
      content: text,
      isMe: true,
      imagePaths: List.from(_pendingImages),
    );
    _addMessage(userMsg);

    final hadImages = _pendingImages.isNotEmpty;
    final imagesToSend = List<String>.from(_pendingImages);
    setState(() => _pendingImages = []);

    if (widget.isGroup && widget.roomId != null) {
      context.read<P2PService>().broadcast(jsonEncode({
        'type': 'group_chat', 'sender': 'me', 'content': text,
        'room': widget.roomId, 'timestamp': DateTime.now().toIso8601String(),
      }), room: widget.roomId);
      return;
    }

    if (widget.isAI || text.startsWith('@gemma ') || text.startsWith('@ai ') || text.startsWith('@gemini ') || hadImages) {
      final prompt = text.replaceFirst(RegExp(r'^@(gemma|ai|gemini)\s'), '');
      await _getAiResponse(prompt, images: hadImages ? imagesToSend : null);
    } else {
      try {
        _chat.send(text, widget.peerId);
      } catch (e) {
        debugPrint('[Chat] Send error: $e');
      }
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _addMessage(ChatMessage(
            id: _uuid.v4(),
            sender: widget.peerName,
            content: 'Reply: "$text"',
            isMe: false,
          ));
        }
      });
    }
  }

  Future<void> _getAiResponse(String prompt, {List<String>? images}) async {
    setState(() => _isLoading = true);
    final lid = _uuid.v4();
    _addMessage(ChatMessage(
      id: lid,
      sender: _modelName,
      content: '...',
      isMe: false,
      isAI: true,
      isLoading: true,
    ));

    try {
      final resp = await _ai.generate(prompt, images: images);

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == lid);
          _addMessage(ChatMessage(
            id: _uuid.v4(),
            sender: _modelName,
            content: resp,
            isMe: false,
            isAI: true,
          ));
        });
      }
    } catch (e) {
      debugPrint('[Chat] AI error: $e');
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == lid);
          _addMessage(ChatMessage(
            id: _uuid.v4(),
            sender: _modelName,
            content: 'Error: ${e.toString().length > 100 ? "Request failed" : e.toString()}',
            isMe: false,
            isAI: true,
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Timestamp divider ---
  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    final speechService = context.watch<SpeechService>();
    final callService = context.watch<VideoCallService>();

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.isGroup
                  ? const Color(0xFF7B1FA2)
                  : widget.isAI ? const Color(0xFFFEE500) : Colors.grey[300],
              child: Icon(
                widget.isGroup ? Icons.group : widget.isAI ? Icons.auto_awesome : Icons.person,
                color: Colors.black54, size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.isGroup && widget.roomId != null
                        ? () => Navigator.pushNamed(context, '/group/info', arguments: widget.roomId)
                        : null,
                    child: Text(widget.peerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(
                        color: _isAiReady ? const Color(0xFF4CAF50) : Colors.grey[400], shape: BoxShape.circle,
                      )),
                      const SizedBox(width: 4),
                      Text(
                        widget.isGroup ? 'Group' : widget.isAI ? '$_modelName Ready' : 'Online',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!widget.isAI && !widget.isGroup)
              IconButton(
                icon: const Icon(Icons.videocam, size: 20, color: Colors.black54),
                tooltip: 'Video call',
                onPressed: _startVideoCall,
              ),
            if (widget.isGroup && widget.roomId != null)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20, color: Colors.black54),
                tooltip: 'Group info',
                onPressed: () => Navigator.pushNamed(context, '/group/info', arguments: widget.roomId),
              ),
            if (widget.isAI)
              PopupMenuButton<String>(
                icon: const Icon(Icons.model_training, size: 20, color: Colors.black54),
                tooltip: 'Select model',
                onSelected: (m) {
                  _ai.selectModel(m);
                  setState(() {});
                },
                itemBuilder: (ctx) => _ai.availableModels.map((m) {
                  return PopupMenuItem(
                    value: m.id,
                    child: Row(
                      children: [
                        Icon(
                          m.isGemini ? Icons.auto_awesome : Icons.memory,
                          size: 16,
                          color: m.id == _ai.selectedModel ? const Color(0xFFFEE500) : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: m.id == _ai.selectedModel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (m.id == _ai.selectedModel)
                          const Icon(Icons.check, size: 14, color: Color(0xFFFEE500)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- Offline banner ---
          if (!_isAiReady && widget.isAI)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[50],
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('AI server offline', style: TextStyle(fontSize: 12, color: Colors.orange[800])),
                ],
              ),
            ),
          // --- Speech listening bar ---
          if (speechService.isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEE500).withOpacity(0.2),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text(speechService.recognizedText.isNotEmpty
                      ? speechService.recognizedText
                      : 'Listening...'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _stopSpeechToText,
                    child: const Icon(Icons.stop, color: Colors.red),
                  ),
                ],
              ),
            ),
          // --- Incoming call banner ---
          if (callService.state == CallState.ringing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green[50],
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Incoming call from ${callService.remotePeerName ?? "unknown"}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      callService.acceptCall();
                      Navigator.pushNamed(context, '/video-call');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    onPressed: () => callService.rejectCall(),
                  ),
                ],
              ),
            ),
          // --- Message list ---
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.isAI ? Icons.auto_awesome : Icons.chat, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Send a message', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                        if (widget.isAI) ...[
                          const SizedBox(height: 4),
                          Text('Images are analyzed with $_modelName', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final show = i == 0 || _messages[i].sender != _messages[i - 1].sender;
                      return MessageBubble(message: _messages[i], showSender: show);
                    },
                  ),
          ),
          // --- Pending images ---
          if (_pendingImages.isNotEmpty)
            Container(
              height: 80,
              color: Colors.grey[50],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _pendingImages.length,
                itemBuilder: (_, i) => Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(_pendingImages[i]),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removePendingImage(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // --- Input area ---
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                // Image attach button
                if (widget.isAI)
                  PopupMenuButton<String>(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined,
                          size: 18, color: Colors.grey[600]),
                    ),
                    tooltip: 'Add image',
                    onSelected: (v) {
                      if (v == 'gallery') _pickImage();
                      if (v == 'camera') _pickImage();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'gallery',
                        child: ListTile(
                          leading: Icon(Icons.photo_library),
                          title: Text('갤러리'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'camera',
                        child: ListTile(
                          leading: Icon(Icons.camera_alt),
                          title: Text('카메라'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  icon: _isUploadingVideo
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.video_library, color: Color(0xFF7B1FA2)),
                  tooltip: 'Upload video to Loops',
                  onPressed: _isUploadingVideo ? null : _pickAndUploadVideoToLoops,
                ),
                IconButton(
                  icon: _isRecording
                      ? const Icon(Icons.stop, color: Colors.red)
                      : const Icon(Icons.mic, color: Colors.grey),
                  tooltip: _isRecording ? 'Stop recording' : 'Voice message',
                  onPressed: _isRecording ? _stopVoiceRecording : _startVoiceRecording,
                ),
                IconButton(
                  icon: speechService.isListening
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.keyboard_voice, color: Colors.grey),
                  tooltip: speechService.isListening ? 'Stop' : 'Speech to text',
                  onPressed: speechService.isListening ? _stopSpeechToText : _startSpeechToText,
                ),
                const SizedBox(width: 4),
                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isAI ? 'Ask $_modelName...' : widget.isGroup ? 'Message group...' : 'Message...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Send button
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey[300] : const Color(0xFF0088cc),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLoading ? Icons.hourglass_top : Icons.send,
                      color: _isLoading ? Colors.grey : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
