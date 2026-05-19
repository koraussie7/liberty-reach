import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// AGiXTFusionService bridges DADA's native agents with AGiXT's agent
/// automation platform, enabling:
/// - Sync DADA agents (Hermes AI, Commerce Agent, Loops Agent) to AGiXT
/// - Run multi-agent chains via AGiXT
/// - Learn from DADA chat history (memory bridge)
/// - Query AGiXT agent capabilities as DADA command lists
class AGiXTFusionService extends ChangeNotifier {
  final http.Client _client = http.Client();
  final String baseUrl = AppConstants.apiBaseUrl;
  bool _synced = false;
  String? _error;

  bool get synced => _synced;
  String? get error => _error;

  /// Sync all DADA agents → AGiXT.
  /// Creates Hermes AI, Commerce Agent, and Loops Agent with their
  /// respective model settings and command capabilities.
  Future<bool> syncDadaAgentsToAGiXT() async {
    final dadaAgents = [
      {
        'agent_name': 'Hermes AI',
        'settings': {
          'provider': 'openai',
          'AI_MODEL': 'gpt-4o-mini',
          'AI_TEMPERATURE': 0.7,
          'max_tokens': 4096,
        },
        'commands': {
          'Web Search': true,
          'Read Website': true,
          'Execute Python Code': false,
          'Image Generation': true,
        },
      },
      {
        'agent_name': 'Commerce Agent',
        'settings': {
          'provider': 'openai',
          'AI_MODEL': 'gpt-4o-mini',
          'AI_TEMPERATURE': 0.3,
          'max_tokens': 2048,
        },
        'commands': {
          'Web Search': true,
          'Read Website': true,
        },
      },
      {
        'agent_name': 'Loops Agent',
        'settings': {
          'provider': 'openai',
          'AI_MODEL': 'gpt-4o-mini',
          'AI_TEMPERATURE': 0.8,
          'max_tokens': 1024,
        },
        'commands': {
          'Web Search': true,
        },
      },
    ];

    bool allOk = true;
    for (final agent in dadaAgents) {
      try {
        final resp = await _client.post(
          Uri.parse('$baseUrl/agixt/agent/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(agent),
        ).timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) allOk = false;
      } catch (e) {
        allOk = false;
        _error = e.toString();
      }
    }
    _synced = allOk;
    notifyListeners();
    return allOk;
  }

  /// Run a chain across multiple DADA agents via AGiXT.
  /// The chain `dada_multi_agent` should be defined in AGiXT to
  /// orchestrate Hermes AI → Commerce Agent → Loops Agent.
  Future<String> runMultiAgentChain(String task) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/agixt/chain/dada_multi_agent/run'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_input': task,
          'agent_name': 'Hermes AI',
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

  /// Make DADA agent learn from AGiXT memory.
  /// Takes a list of message maps with 'user' and 'assistant' keys,
  /// and persists each as a learning text for the given agent.
  Future<bool> learnFromChatHistory(
      String agentName, List<Map<String, dynamic>> messages) async {
    for (final msg in messages) {
      final ok = await _client.post(
        Uri.parse('$baseUrl/agixt/agent/$agentName/learn/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_input': msg['user']?.toString() ?? '',
          'text': msg['assistant']?.toString() ?? '',
        }),
      ).timeout(const Duration(seconds: 10));
      if (ok.statusCode != 200) return false;
    }
    return true;
  }

  /// Get AGiXT agent capabilities as a list of DADA-compatible command names.
  /// Parses the agent's 'commands' map and returns only enabled commands.
  Future<List<String>> getAgentCommands(String agentName) async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/agixt/agents'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final agents = jsonDecode(resp.body) as List;
        for (final a in agents) {
          if ((a['name']?.toString() ?? '') == agentName) {
            final cmds = a['commands'] as Map? ?? {};
            return cmds.entries
                .where((e) => e.value == true)
                .map<String>((e) => e.key as String)
                .toList();
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    return [];
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
