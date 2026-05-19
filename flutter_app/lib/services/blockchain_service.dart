import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class BlockchainInfo {
  final String version;
  final String uptime;
  final int blocks;
  final String minima;
  final String coins;
  final String address;

  BlockchainInfo({
    this.version = '',
    this.uptime = '',
    this.blocks = 0,
    this.minima = '0',
    this.coins = '0',
    this.address = '',
  });

  factory BlockchainInfo.fromJson(Map<String, dynamic> json) => BlockchainInfo(
    version: json['version'] as String? ?? '',
    uptime: json['uptime'] as String? ?? '',
    blocks: json['blocks'] as int? ?? 0,
    minima: json['minima'] as String? ?? '0',
    coins: json['coins'] as String? ?? '0',
    address: json['address'] as String? ?? '',
  );
}

class BlockchainBalance {
  final String address;
  final String coins;
  final int dadaPointBalance;
  final bool connected;

  BlockchainBalance({
    this.address = '',
    this.coins = '0',
    this.dadaPointBalance = 0,
    this.connected = false,
  });

  factory BlockchainBalance.fromJson(Map<String, dynamic> json) => BlockchainBalance(
    address: json['address'] as String? ?? '',
    coins: json['coins'] as String? ?? '0',
    dadaPointBalance: json['dada_point_balance'] as int? ?? 0,
    connected: json['address'] != null && (json['address'] as String).isNotEmpty,
  );

  String get shortAddress => address.length > 10
      ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
      : address;
}

class LeaderboardStats {
  final int totalUsers;
  final int totalPoints;
  final int totalTxs;
  final int remaining;
  final int onchainBalance;
  final String onchainAddress;

  LeaderboardStats({
    this.totalUsers = 0,
    this.totalPoints = 0,
    this.totalTxs = 0,
    this.remaining = 0,
    this.onchainBalance = 0,
    this.onchainAddress = '',
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    final onchain = json['onchain'] as Map<String, dynamic>? ?? {};
    final offchain = json['offchain'] as Map<String, dynamic>? ?? {};
    return LeaderboardStats(
      totalUsers: offchain['total_users'] as int? ?? 0,
      totalPoints: offchain['total_points_distributed'] as int? ?? 0,
      totalTxs: offchain['total_transactions'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
      onchainBalance: onchain['dada_point_balance'] as int? ?? 0,
      onchainAddress: onchain['address'] as String? ?? '',
    );
  }
}

class BlockchainService extends ChangeNotifier {
  final http.Client _client = http.Client();

  bool _loading = false;
  bool _healthy = false;
  String? _error;
  BlockchainInfo _info = BlockchainInfo();
  BlockchainBalance _balance = BlockchainBalance();
  LeaderboardStats _stats = LeaderboardStats();

  bool get loading => _loading;
  bool get healthy => _healthy;
  String? get error => _error;
  BlockchainInfo get info => _info;
  BlockchainBalance get balance => _balance;
  LeaderboardStats get stats => _stats;

  Timer? _refreshTimer;

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refresh());
    refresh();
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchHealth(),
        _fetchInfo(),
        _fetchBalance(),
        _fetchLeaderboard(),
      ]);
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  Future<void> _fetchHealth() async {
    try {
      final resp = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/blockchain/health'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _healthy = data['status'] == 'healthy';
      }
    } catch (e) {
      _healthy = false;
      debugPrint('[Blockchain] health error: $e');
    }
  }

  Future<void> _fetchInfo() async {
    try {
      final resp = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/blockchain/info'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        _info = BlockchainInfo.fromJson(jsonDecode(resp.body));
      }
    } catch (e) {
      debugPrint('[Blockchain] info error: $e');
    }
  }

  Future<void> _fetchBalance() async {
    try {
      final resp = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/blockchain/balance'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        _balance = BlockchainBalance.fromJson(jsonDecode(resp.body));
      }
    } catch (e) {
      debugPrint('[Blockchain] balance error: $e');
    }
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final resp = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/leaderboard/stats'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        _stats = LeaderboardStats.fromJson(jsonDecode(resp.body));
      }
    } catch (e) {
      debugPrint('[Blockchain] leaderboard error: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _client.close();
    super.dispose();
  }
}
