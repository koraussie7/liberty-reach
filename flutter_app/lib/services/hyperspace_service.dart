import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HyperspaceService extends ChangeNotifier {
  final String _baseUrl;
  final String _wsUrl;
  final http.Client _client;

  HyperspaceService({
    String baseUrl = 'https://muhantube.com/ai/hyperspace',
    String wsUrl = 'wss://muhantube.com/ai/hyperspace/ws',
  })  : _baseUrl = baseUrl,
        _wsUrl = wsUrl,
        _client = http.Client();

  // --- Dashboard state ---
  bool _nodeRunning = false;
  bool _agentOnline = false;
  bool _chainOnline = false;
  String _chainBlock = '0';
  List<Map<String, dynamic>> _models = [];
  String _error = '';
  bool _loading = false;
  Timer? _pollTimer;

  // Getters
  bool get nodeRunning => _nodeRunning;
  bool get agentOnline => _agentOnline;
  bool get chainOnline => _chainOnline;
  String get chainBlock => _chainBlock;
  List<Map<String, dynamic>> get models => List.unmodifiable(_models);
  String get error => _error;
  bool get loading => _loading;

  // --- Chat state ---
  final List<ChatMessage> _messages = [];
  bool _chatLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get chatLoading => _chatLoading;

  // --- Polling ---
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollTimer?.cancel();
    fetchStatus();
    _pollTimer = Timer.periodic(interval, (_) => fetchStatus());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // --- Node control ---
  Future<void> fetchStatus() async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/status'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _nodeRunning = data['node_running'] as bool? ?? false;
        _agentOnline = data['agent_online'] as bool? ?? false;
        _chainOnline = data['chain_online'] as bool? ?? false;
        _chainBlock = (data['chain_block'] ?? '0').toString();
        final rawModels = data['models'];
        if (rawModels is List) {
          _models = rawModels
              .map((e) => e is Map<String, dynamic>
                  ? e
                  : <String, dynamic>{'id': e.toString()})
              .toList();
        }
        _error = '';
      } else {
        _error = 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Hyperspace fetchStatus error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> startNode() async {
    try {
      final resp = await _client
          .post(Uri.parse('$_baseUrl/node/start'))
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        _nodeRunning = true;
        _agentOnline = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('startNode error: $e');
    }
  }

  Future<void> stopNode() async {
    try {
      final resp = await _client
          .post(Uri.parse('$_baseUrl/node/stop'))
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        _nodeRunning = false;
        _agentOnline = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('stopNode error: $e');
    }
  }

  // --- Chat ---
  Future<HyperspaceResponse> infer(String prompt,
      {bool p2p = true, String model = 'gemma-2-2b-it'}) async {
    try {
      final resp = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt,
              'model': model,
              'p2p': p2p,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('response')) {
          return HyperspaceResponse(
            text: data['response'] as String,
            model: data['model'] as String? ?? model,
            isP2P: data['p2p'] as bool? ?? p2p,
          );
        }
        return HyperspaceResponse.error(
            data['error'] as String? ?? 'Unknown error');
      }
      return HyperspaceResponse.error('HTTP ${resp.statusCode}');
    } catch (e) {
      debugPrint('Hyperspace infer error: $e');
      return HyperspaceResponse.error(e.toString());
    }
  }

  Future<void> chat(String text, {String model = 'gemma-2-2b-it'}) async {
    _chatLoading = true;
    _messages.add(ChatMessage(text: text, isUser: true));
    notifyListeners();

    final response = await infer(text, model: model);
    _messages.add(ChatMessage(
      text: response.text,
      isUser: false,
      isError: response.isError,
      model: response.model,
    ));
    _chatLoading = false;
    notifyListeners();
  }

  List<String> get availableModels =>
      _models.map((m) => (m['id'] ?? m['name'] ?? 'unknown').toString()).toList();

  @override
  void dispose() {
    stopPolling();
    _client.close();
    super.dispose();
  }
}

class HyperspaceResponse {
  final String text;
  final String model;
  final bool isP2P;
  final bool isError;
  final String? errorMessage;

  HyperspaceResponse({
    required this.text,
    this.model = 'gemma-2-2b-it',
    this.isP2P = true,
    this.isError = false,
    this.errorMessage,
  });

  HyperspaceResponse.error(this.errorMessage)
      : text = errorMessage ?? 'Error',
        model = '',
        isP2P = false,
        isError = true;
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final String model;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.model = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
