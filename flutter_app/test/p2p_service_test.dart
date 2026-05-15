import 'package:flutter_test/flutter_test.dart';
import 'package:liberty_reach/services/p2p_service.dart';

void main() {
  group('P2PMessage', () {
    test('should create from JSON', () {
      final json = {
        'type': 'chat',
        'sender': 'peer1',
        'content': 'hello',
        'timestamp': '2026-05-14T08:00:00.000',
      };
      final msg = P2PMessage.fromJson(json);
      expect(msg.type, 'chat');
      expect(msg.sender, 'peer1');
      expect(msg.content, 'hello');
      expect(msg.timestamp, '2026-05-14T08:00:00.000');
    });

    test('should serialize to JSON', () {
      final msg = P2PMessage(
        type: 'chat',
        sender: 'peer1',
        content: 'hello',
        timestamp: '2026-05-14T08:00:00.000',
      );
      final json = msg.toJson();
      expect(json['type'], 'chat');
      expect(json['sender'], 'peer1');
      expect(json['content'], 'hello');
    });
  });

  group('P2PService', () {
    test('should start disconnected', () {
      final p2p = P2PService();
      expect(p2p.isConnected, false);
      expect(p2p.connectedPeers, isEmpty);
      expect(p2p.localPeerId, isNull);
    });

    test('should set local peer ID', () {
      final p2p = P2PService();
      p2p.setLocalPeerId('test-peer');
      expect(p2p.localPeerId, 'test-peer');
    });

    test('should parse incoming messages', () {
      final p2p = P2PService();
      String? received;
      p2p.incoming.listen((msg) => received = msg.content);
      p2p.onMessage('{"type":"chat","sender":"peer","content":"hi","timestamp":"2026-01-01T00:00:00"}');
      expect(received, 'hi');
    });

    test('should handle invalid JSON gracefully', () {
      final p2p = P2PService();
      expect(() => p2p.onMessage('not json'), returnsNormally);
    });
  });
}
