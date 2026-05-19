import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EarningsEntry {
  final double points;
  final DateTime timestamp;
  final String description;

  EarningsEntry({
    required this.points,
    required this.timestamp,
    required this.description,
  });

  factory EarningsEntry.fromJson(Map<String, dynamic> json) {
    return EarningsEntry(
      points: (json['points'] as num?)?.toDouble() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String? ?? '',
    );
  }
}

class LeaderboardEntry {
  final String name;
  final double points;
  final int rank;

  LeaderboardEntry({
    required this.name,
    required this.points,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] as String? ?? 'Anonymous',
      points: (json['points'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class HyperspaceEarningsService extends ChangeNotifier {
  final String _baseUrl;
  final http.Client _client;

  HyperspaceEarningsService({
    String baseUrl = 'https://muhantube.com/ai/hyperspace/earnings',
  })  : _baseUrl = baseUrl,
        _client = http.Client();

  double _totalPoints = 0;
  List<EarningsEntry> _history = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _loading = false;
  String _error = '';

  double get totalPoints => _totalPoints;
  List<EarningsEntry> get history => List.unmodifiable(_history);
  List<LeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  bool get loading => _loading;
  String get error => _error;

  Future<void> fetchEarnings() async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _totalPoints = (data['total_points'] as num?)?.toDouble() ?? 0;

        final rawHistory = data['history'] as List? ?? [];
        _history = rawHistory
            .map((e) => EarningsEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawLeaderboard = data['leaderboard'] as List? ?? [];
        _leaderboard = rawLeaderboard
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        _error = '';
      } else {
        _error = 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('HyperspaceEarningsService fetchEarnings error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
