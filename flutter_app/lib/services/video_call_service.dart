import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'p2p_service.dart';

enum CallState { idle, calling, ringing, connected, ended }

class VideoCallService extends ChangeNotifier {
  final P2PService _p2p;
  StreamSubscription? _p2pSub;

  CallState _state = CallState.idle;
  String? _remotePeerId;
  String? _remotePeerName;
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  String? _localSdp;
  String? _remoteSdp;

  CallState get state => _state;
  String? get remotePeerId => _remotePeerId;
  String? get remotePeerName => _remotePeerName;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isInCall => _state == CallState.calling || _state == CallState.ringing || _state == CallState.connected;

  VideoCallService(this._p2p) {
    _p2pSub = _p2p.incoming.listen(_handleSignal);
  }

  Future<void> startCall(String peerId, String peerName) async {
    _remotePeerId = peerId;
    _remotePeerName = peerName;
    _state = CallState.calling;
    notifyListeners();

    _p2p.sendMessage(peerId, jsonEncode({
      'type': 'video_call_offer',
      'caller_name': 'Liberty User',
    }));
  }

  void _handleSignal(P2PMessage msg) {
    try {
      final data = jsonDecode(msg.content);
      final signalType = data['type'] as String?;

      if (signalType == 'video_call_offer') {
        _remotePeerId = msg.sender;
        _remotePeerName = data['caller_name'] as String? ?? msg.sender;
        _state = CallState.ringing;
        notifyListeners();
      } else if (signalType == 'video_call_accept') {
        _state = CallState.connected;
        notifyListeners();
      } else if (signalType == 'video_call_reject') {
        _state = CallState.idle;
        notifyListeners();
      } else if (signalType == 'video_call_end') {
        _state = CallState.ended;
        notifyListeners();
        Future.delayed(const Duration(seconds: 2), () {
          _state = CallState.idle;
          notifyListeners();
        });
      } else if (signalType == 'video_call_ice') {
        debugPrint('[VideoCall] ICE candidate from ${msg.sender}');
      }
    } catch (e) {
      debugPrint('[VideoCall] signal parse error: $e');
    }
  }

  Future<void> acceptCall() async {
    if (_remotePeerId == null) return;
    _state = CallState.connected;
    notifyListeners();

    _p2p.sendMessage(_remotePeerId!, jsonEncode({
      'type': 'video_call_accept',
    }));
  }

  Future<void> rejectCall() async {
    if (_remotePeerId == null) return;
    _p2p.sendMessage(_remotePeerId!, jsonEncode({
      'type': 'video_call_reject',
    }));
    _state = CallState.idle;
    notifyListeners();
  }

  Future<void> endCall() async {
    if (_remotePeerId != null) {
      _p2p.sendMessage(_remotePeerId!, jsonEncode({
        'type': 'video_call_end',
      }));
    }
    _state = CallState.ended;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _state = CallState.idle;
      _remotePeerId = null;
      _remotePeerName = null;
      notifyListeners();
    });
  }

  void toggleVideo() {
    _isVideoEnabled = !_isVideoEnabled;
    notifyListeners();
  }

  void toggleAudio() {
    _isAudioEnabled = !_isAudioEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _p2pSub?.cancel();
    super.dispose();
  }
}
