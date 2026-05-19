import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// ISEK Agent Fusion Service
///
/// Bridges DADA-AI's existing agents (Hermes AI, Commerce Agent, Loops Agent)
/// into the ISEK network by registering them as ISEK AgentCards, managing
/// their on-chain identities, and discovering other ISEK agents.
class ISEKFusionService extends ChangeNotifier {
  final http.Client _client;
  final String baseUrl;

  bool _registered = false;
  String? _agentId;
  String? _walletAddress;
  String? _error;
  List<Map<String, dynamic>> _discoveredAgents = [];

  ISEKFusionService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get registered => _registered;
  String? get agentId => _agentId;
  String? get walletAddress => _walletAddress;
  String? get error => _error;
  List<Map<String, dynamic>> get discoveredAgents => _discoveredAgents;

  // ---------------------------------------------------------------------------
  // Agent definitions
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> _agentDefinitions = [
    {
      'name': 'Hermes AI',
      'model': 'gpt-4o-mini',
      'description':
          'DADA-AI primary assistant with vision, code, and chat capabilities',
      'skills': [
        {
          'id': 'chat',
          'name': 'Chat',
          'desc': 'General conversation',
          'tags': ['general', 'chat'],
        },
        {
          'id': 'vision',
          'name': 'Vision',
          'desc': 'Image analysis',
          'tags': ['vision', 'multimodal'],
        },
        {
          'id': 'code',
          'name': 'Code',
          'desc': 'Code generation & assistance',
          'tags': ['code', 'programming'],
        },
      ],
    },
    {
      'name': 'Commerce Agent',
      'model': 'gpt-4o-mini',
      'description': 'DADA-AI commerce assistant for product recommendations',
      'skills': [
        {
          'id': 'product_search',
          'name': 'Product Search',
          'desc': 'Find products',
          'tags': ['commerce', 'search'],
        },
        {
          'id': 'recommendations',
          'name': 'Recommendations',
          'desc': 'Personalized picks',
          'tags': ['commerce', 'recommend'],
        },
      ],
    },
    {
      'name': 'Loops Agent',
      'model': 'gpt-4o-mini',
      'description': 'DADA-AI short video content assistant',
      'skills': [
        {
          'id': 'content_discovery',
          'name': 'Content Discovery',
          'desc': 'Find trending content',
          'tags': ['loops', 'video'],
        },
        {
          'id': 'trends',
          'name': 'Trends',
          'desc': 'Analyze trending topics',
          'tags': ['loops', 'trends'],
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get agentDefinitions =>
      _agentDefinitions.map((a) => Map<String, dynamic>.from(a)).toList();

  // ---------------------------------------------------------------------------
  // Register all DADA agents as ISEK AgentCards
  // ---------------------------------------------------------------------------

  /// Register DADA's AI agents (Hermes, Commerce, Loops) as ISEK A2A agents.
  Future<bool> registerAgents() async {
    bool allOk = true;

    for (final agent in _agentDefinitions) {
      try {
        final resp = await _client
            .post(
              Uri.parse('$baseUrl/isek/agent/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(agent),
            )
            .timeout(const Duration(seconds: 10));

        if (resp.statusCode != 200) {
          allOk = false;
          debugPrint(
            '[ISEKFusion] Failed to register ${agent['name']}: '
            '${resp.statusCode}',
          );
        } else {
          debugPrint('[ISEKFusion] Registered ${agent['name']} successfully');
        }
      } catch (e) {
        allOk = false;
        _error = e.toString();
        debugPrint('[ISEKFusion] Error registering ${agent['name']}: $e');
      }
    }

    _registered = allOk;
    notifyListeners();
    return allOk;
  }

  // ---------------------------------------------------------------------------
  // On-chain identity
  // ---------------------------------------------------------------------------

  /// Register an ERC-8004 on-chain identity for an agent.
  Future<Map<String, dynamic>> registerOnChainIdentity({
    String agentUrl = '',
  }) async {
    try {
      final url = agentUrl.isNotEmpty ? agentUrl : '$baseUrl/isek';
      final resp = await _client
          .post(
            Uri.parse('$baseUrl/isek/identity/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'agent_url': url}),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _agentId = data['agent_id']?.toString();
        _walletAddress = data['address']?.toString();
        _error = null;
        notifyListeners();
        return data;
      }
    } catch (e) {
      _error = e.toString();
    }
    return {};
  }

  // ---------------------------------------------------------------------------
  // Agent discovery
  // ---------------------------------------------------------------------------

  /// Discover agents on the ISEK network.
  Future<List<Map<String, dynamic>>> discoverISEKAgents() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/isek/agents/discover'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _discoveredAgents =
            List<Map<String, dynamic>>.from(data['agents'] as List? ?? []);
        _error = null;
        notifyListeners();
        return _discoveredAgents;
      }
    } catch (e) {
      _error = e.toString();
    }
    return [];
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
