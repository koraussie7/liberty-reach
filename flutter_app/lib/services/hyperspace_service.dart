import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HyperspaceService {
  final String _baseUrl;
  final http.Client _client;

  HyperspaceService({String baseUrl = 'https://muhantube.com/ai/hyperspace'})
      : _baseUrl = baseUrl,
        _client = http.Client();

  Future<HyperspaceResponse> infer(String prompt, {bool p2p = true, String model = 'gemma-2-2b-it'}) async {
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
        return HyperspaceResponse.error(data['error'] as String? ?? 'Unknown error');
      }
      return HyperspaceResponse.error('HTTP ${resp.statusCode}');
    } catch (e) {
      debugPrint('Hyperspace error: $e');
      return HyperspaceResponse.error(e.toString());
    }
  }

  void dispose() => _client.close();
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
