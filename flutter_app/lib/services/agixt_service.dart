import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class AGiXTService extends ChangeNotifier {
  final http.Client _client = http.Client();
  final String baseUrl = AppConstants.apiBaseUrl;
  bool _healthy = false;
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _chains = [];
  List<Map<String, dynamic>> _extensions = [];
  String? _error;
  bool _loading = false;

  bool get healthy => _healthy;
  List<Map<String, dynamic>> get agents => _agents;
  List<Map<String, dynamic>> get conversations => _conversations;
  List<Map<String, dynamic>> get chains => _chains;
  List<Map<String, dynamic>> get extensions => _extensions;
  String? get error => _error;
  bool get loading => _loading;

  Future<bool> checkHealth() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/agixt/health'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        _healthy = (jsonDecode(resp.body)['status'] == 'ok');
        notifyListeners();
        return _healthy;
      }
    } catch (e) {
      _error = e.toString();
    }
    _healthy = false;
    notifyListeners();
    return false;
  }

  Future<List<Map<String, dynamic>>> listAgents() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/agixt/agents'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        _agents = List<Map<String, dynamic>>.from(jsonDecode(resp.body));
        notifyListeners();
        return _agents;
      }
    } catch (e) {
      _error = e.toString();
    }
    return [];
  }

  Future<bool> createAgent(String name,
      {String model = 'gpt-4o-mini',
      String provider = 'openai',
      double temperature = 0.7}) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/agixt/agent/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agent_name': name,
          'settings': {
            'provider': provider,
            'AI_MODEL': model,
            'AI_TEMPERATURE': temperature,
          },
          'commands': {
            'Web Search': true,
            'Read Website': true,
            'Execute Python Code': false,
          },
        }),
      ).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        await listAgents();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  Future<String> promptAgent(String agentName, String userInput,
      {String promptName = 'Chat'}) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/agixt/agent/$agentName/prompt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt_name': promptName,
          'prompt_args': {'user_input': userInput},
        }),
      ).timeout(const Duration(seconds: 120));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['response']?.toString() ?? data.toString();
      }
      return '(AGiXT error: ${resp.statusCode})';
    } catch (e) {
      return '(error: $e)';
    }
  }

  Future<String> runChain(String chainName, String userInput,
      {String agentName = 'default'}) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/agixt/chain/$chainName/run'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_input': userInput,
          'agent_name': agentName,
        }),
      ).timeout(const Duration(seconds: 120));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['response']?.toString() ?? data.toString();
      }
      return '(Chain error: ${resp.statusCode})';
    } catch (e) {
      return '(error: $e)';
    }
  }

  Future<bool> learnText(
      String agentName, String text, String userInput) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/agixt/agent/$agentName/learn/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_input': userInput, 'text': text}),
      ).timeout(const Duration(seconds: 30));
      return resp.statusCode == 200;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
