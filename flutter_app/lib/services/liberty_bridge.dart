import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

// Conditional import: use FRB bindings on native, fallback to simulated on web
// import '../src/rust/frb_generated.dart' if (dart.library.html) '../src/rust/frb_generated_web.dart';
// import '../src/rust/api/liberty_api.dart' as rust_api;

/// Bridge between Flutter and Rust Liberty Reach core.
class LibertyBridge extends ChangeNotifier {
  bool _initialized = false;
  String? _peerId;
  final List<String> _peers = [];
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  Timer? _simulationTimer;

  Stream<ChatMessage> get onMessage => _messageController.stream;
  String? get peerId => _peerId;
  List<String> get connectedPeers => List.unmodifiable(_peers);
  bool get isInitialized => _initialized;

  Future<String> init({
    required String peerName,
    String localaiUrl = 'http://localhost:8080',
  }) async {
    try {
      // FRB native: uncomment below and remove simulated fallback
      // await RustLib.init();
      // final result = await rust_api.init(
      //   peerName: peerName,
      //   localaiUrl: localaiUrl,
      //   storagePath: storagePath,
      // );
      // _peerId = await rust_api.getPeerId();
      // _initialized = true;
      // notifyListeners();
      // return result;

      // Web fallback: simulated mode
      _peerId = '12D3KooW${peerName.hashCode.toString().padLeft(8, '0')}';
      _initialized = true;
      debugPrint('[LibertyBridge] Initialized: $_peerId (simulated)');
      notifyListeners();
      _startSimulation();
      return 'Initialized as $peerName';
    } catch (e) {
      return 'Init error: $e';
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_peers.isEmpty) {
        _peers.add('12D3KooWSimPeer1');
        _peers.add('12D3KooWSimPeer2');
        notifyListeners();
      }
    });
  }

  Future<String> sendMessage(String content) async {
    // FRB native: return await rust_api.sendMessage(content: content);
    debugPrint('[LibertyBridge] Sending: $content');
    return content;
  }

  Future<String> askAI(String prompt) async {
    // FRB native: return await rust_api.askAi(prompt: prompt);
    debugPrint('[LibertyBridge] AI ask: $prompt');
    return '(simulated AI response for: $prompt)';
  }

  Future<String> askMultimodal(String prompt, List<String> imagesBase64) async {
    // FRB native: return await rust_api.askAiMultimodal(prompt: prompt, imagesBase64: imagesBase64);
    debugPrint('[LibertyBridge] Multimodal ask: $prompt (${imagesBase64.length} images)');
    return '(simulated multimodal response for: $prompt)';
  }

  Future<String> connectToPeer(String address) async {
    // FRB native: return await rust_api.connectToPeer(address: address);
    if (!_peers.contains(address)) {
      _peers.add(address);
      notifyListeners();
    }
    return 'connecting to $address (simulated)';
  }

  Future<bool> checkAIHealth() async {
    // FRB native: return await rust_api.checkAiHealth();
    return true;
  }

  Future<List<ChatMessage>> getHistory() async {
    // FRB native: final entries = await rust_api.getMessageHistory(limit: 50);
    return [];
  }

  void incomingMessage(ChatMessage msg) {
    _messageController.add(msg);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _messageController.close();
    super.dispose();
  }
}
