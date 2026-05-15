import 'package:flutter_test/flutter_test.dart';
import 'package:liberty_reach/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have valid API base URL', () {
      expect(AppConstants.apiBaseUrl, isNotEmpty);
      expect(AppConstants.apiBaseUrl.startsWith('https://'), isTrue);
    });

    test('should have valid WebSocket base URL', () {
      expect(AppConstants.wsBaseUrl, isNotEmpty);
      expect(AppConstants.wsBaseUrl.startsWith('wss://'), isTrue);
    });

    test('should have positive max history', () {
      expect(AppConstants.maxHistoryMessages, greaterThan(0));
    });
  });
}
