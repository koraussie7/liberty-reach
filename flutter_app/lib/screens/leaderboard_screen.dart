import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';
import '../widgets/glass_rank_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final LeaderboardService _service = LeaderboardService();
  late TabController _tabController;
  Map<String, List<RankEntry>> _cache = {};
  Map<String, bool> _loading = {};
  LeaderboardStats? _stats;
  bool _statsLoading = true;

  final _periods = ['all', 'monthly', 'weekly', 'creators'];
  final _labels = ['All-Time', 'Monthly', 'Weekly', 'Creators'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final p = _periods[_tabController.index];
        if (!_cache.containsKey(p)) _load(p);
      }
    });
    _loadStats();
    _load('all');
  }

  Future<void> _loadStats() async {
    final s = await _service.getStats();
    if (mounted) setState(() { _stats = s; _statsLoading = false; });
  }

  Future<void> _load(String period) async {
    setState(() => _loading[period] = true);
    final data = await _service.getLeaderboard(period, limit: 50);
    setState(() {
      _cache[period] = data;
      _loading[period] = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 22, color: Colors.amber),
            SizedBox(width: 8),
            Text('DADA Point Ranking'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              _buildStatsBar(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.fill,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xFFFEE500),
                tabs: _labels.map((l) => Tab(text: l)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _periods.map((period) => _buildTab(period)).toList(),
      ),
    );
  }

  Widget _buildTab(String period) {
    final isLoading = _loading[period] ?? false;
    final entries = _cache[period] ?? [];

    if (isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No rankings yet', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('Watch Loops or chat with AI to earn DADA Points',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(period),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: entries.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildMyRankCard();
          return GlassRankCard(entry: entries[i - 1]);
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    if (_statsLoading) {
      return const SizedBox(
        height: 40,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final s = _stats;
    if (s == null) return const SizedBox(height: 4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _statItem(Icons.account_balance_wallet, 'Treasury', '${s.onchainBalance}', Colors.amber),
          Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.15)),
          _statItem(Icons.people, 'Users', '${s.totalUsers}', Colors.cyanAccent),
          Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.15)),
          _statItem(Icons.pie_chart, 'Remaining', '${s.remaining}', Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildMyRankCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFEE500).withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE500).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE500),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Rank', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                SizedBox(height: 2),
                Text('Connect wallet to see your rank', style: TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
