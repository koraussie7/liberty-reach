import 'package:flutter_test/flutter_test.dart';
import 'package:liberty_reach/services/wallet_service.dart';

void main() {
  group('WalletService', () {
    test('should be a singleton', () {
      final a = WalletService();
      final b = WalletService();
      expect(a, same(b));
    });

    test('should start disconnected', () {
      final wallet = WalletService();
      expect(wallet.connected, false);
      expect(wallet.address, isNull);
      expect(wallet.balance, 0);
    });

    test('disconnect should reset state', () async {
      final wallet = WalletService();
      await wallet.connect();
      await wallet.disconnect();
      expect(wallet.connected, false);
      expect(wallet.address, isNull);
      expect(wallet.balance, 0);
    });

    test('shortAddress should handle null', () {
      final wallet = WalletService();
      expect(wallet.shortAddress, '');
    });
  });
}
