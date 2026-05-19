import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Model representing an ISEK Agent Card.
class ISEKAgentCard {
  final String name;
  final String url;
  final String description;
  final String version;
  final List<String> skills;

  const ISEKAgentCard({
    required this.name,
    required this.url,
    required this.description,
    required this.version,
    required this.skills,
  });

  factory ISEKAgentCard.fromJson(Map<String, dynamic> j) {
    final rawSkills = j['skills'] as List? ?? [];
    return ISEKAgentCard(
      name: j['name']?.toString() ?? '',
      url: j['url']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      version: j['version']?.toString() ?? '1.0',
      skills: rawSkills.map((s) {
        if (s is Map) return s['name']?.toString() ?? 'skill';
        return s.toString();
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'description': description,
        'version': version,
        'skills': skills,
      };

  @override
  String toString() => 'ISEKAgentCard($name v$version)';
}

/// Central service for communicating with the ISEK network via the DADA-AI
/// server proxy endpoints.
class ISEKService extends ChangeNotifier {
  final http.Client _client;
  final String baseUrl;

  bool _relayRunning = false;
  List<ISEKAgentCard> _discoveredAgents = [];
  String? _relayPeerId;
  String? _error;

  ISEKService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get relayRunning => _relayRunning;
  List<ISEKAgentCard> get discoveredAgents => _discoveredAgents;
  String? get relayPeerId => _relayPeerId;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Relay management
  // ---------------------------------------------------------------------------

  /// Start the ISEK relay on the server.
  Future<bool> startRelay() async {
    try {
      final resp = await _client
          .post(Uri.parse('$baseUrl/isek/relay/start'))
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        _relayRunning = true;
        _error = null;
        notifyListeners();
        return true;
      }
      _error = 'relay/start returned ${resp.statusCode}';
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  /// Poll relay status from the server.
  Future<bool> checkRelay() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/isek/relay/status'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _relayRunning = data['running'] as bool? ?? false;
        _error = null;
        notifyListeners();
        return _relayRunning;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Agent registration
  // ---------------------------------------------------------------------------

  /// Register a DADA agent as an ISEK AgentCard.
  Future<bool> registerAgent(
    String name,
    String model,
    List<Map<String, dynamic>> skills,
  ) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/isek/agent/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'model': model,
          'skills': skills,
        }),
      ).timeout(const Duration(seconds: 15));
      _error = null;
      return resp.statusCode == 200;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // A2A messaging
  // ---------------------------------------------------------------------------

  /// Send a message to an ISEK agent via the A2A protocol.
  ///
  /// [targetUrl] is the agent's HTTP endpoint (e.g. http://agent-host:9999).
  /// Returns the agent's response text.
  Future<String> sendA2A(String targetUrl, String query) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/isek/a2a/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'target_url': targetUrl, 'query': query}),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // Try to extract a readable result
        final result = data['result']?.toString() ??
            data['message']?.toString() ??
            jsonEncode(data);
        return result;
      }
      return '(ISEK error: ${resp.statusCode})';
    } catch (e) {
      return '(error: $e)';
    }
  }

  // ---------------------------------------------------------------------------
  // ERC-8004 identity
  // ---------------------------------------------------------------------------

  /// Register an on-chain identity for an agent via ERC-8004.
  ///
  /// [agentUrl] is the agent's base URL.
  /// Returns a map with address / agent_id / tx_hash.
  Future<Map<String, dynamic>> registerIdentity(String agentUrl) async {
    try {
      final resp = await _client.post(
        Uri.parse('$baseUrl/isek/identity/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'agent_url': agentUrl}),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      _error = e.toString();
    }
    return {};
  }

  // ---------------------------------------------------------------------------
  // Agent discovery
  // ---------------------------------------------------------------------------

  /// Discover agents on the current ISEK network.
  Future<void> discoverAgents() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/isek/agents/discover'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final rawList = data['agents'] as List? ?? [];
        _discoveredAgents = rawList
            .map((a) => ISEKAgentCard.fromJson(a as Map<String, dynamic>))
            .toList();
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
