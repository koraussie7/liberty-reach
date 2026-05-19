import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design_system/design_system.dart';
import '../services/blockchain_service.dart';

class BlockchainDashboard extends StatefulWidget {
  const BlockchainDashboard({super.key});

  @override
  State<BlockchainDashboard> createState() => _BlockchainDashboardState();
}

class _BlockchainDashboardState extends State<BlockchainDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockchainService>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Don't stop the timer here — the service manages its own lifecycle via Provider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bc = context.watch<BlockchainService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF020617) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Blockchain'),
        automaticallyImplyLeading: false,
        actions: [
          if (bc.loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => bc.refresh(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => bc.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(bc, isDark),
            const SizedBox(height: 16),
            _buildBalanceCard(bc, isDark),
            const SizedBox(height: 16),
            _buildInfoCard(bc, isDark),
            const SizedBox(height: 16),
            _buildLeaderboardCard(bc, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BlockchainService bc, bool isDark) {
    return _Card(
      isDark: isDark,
      children: [
        Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bc.healthy ? const Color(0xFF4CAF50) : Colors.red,
                boxShadow: bc.healthy
                    ? [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              bc.healthy ? 'Network Healthy' : 'Network Offline',
              style: AppTextStyles.titleLarge(
                color: bc.healthy ? const Color(0xFF4CAF50) : Colors.red,
              ),
            ),
            const Spacer(),
            Text(
              'Minima',
              style: AppTextStyles.labelSmall(color: isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ],
        ),
        if (bc.error != null) ...[
          const SizedBox(height: 8),
          Text('Error: ${bc.error}', style: AppTextStyles.bodySmall(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _buildBalanceCard(BlockchainService bc, bool isDark) {
    return _Card(
      isDark: isDark,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 8),
            Text('Wallet', style: AppTextStyles.titleLarge()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'DADAPOINT',
                value: _formatNum(bc.balance.dadaPointBalance),
                icon: Icons.token,
                color: const Color(0xFFFFD700),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                label: 'Minima',
                value: bc.balance.coins,
                icon: Icons.monetization_on,
                color: const Color(0xFF0088cc),
                isDark: isDark,
              ),
            ),
          ],
        ),
        if (bc.balance.connected) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.link, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                bc.balance.shortAddress,
                style: AppTextStyles.bodySmall(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(BlockchainService bc, bool isDark) {
    return _Card(
      isDark: isDark,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 8),
            Text('Network Info', style: AppTextStyles.titleLarge()),
          ],
        ),
        const SizedBox(height: 16),
        _infoRow('Version', bc.info.version, isDark),
        _infoRow('Blocks', _formatNum(bc.info.blocks), isDark),
        _infoRow('Minima', bc.info.minima, isDark),
        _infoRow('Coins', bc.info.coins, isDark),
        if (bc.info.uptime.isNotEmpty) _infoRow('Uptime', bc.info.uptime, isDark),
      ],
    );
  }

  Widget _buildLeaderboardCard(BlockchainService bc, bool isDark) {
    return _Card(
      isDark: isDark,
      children: [
        Row(
          children: [
            Icon(Icons.leaderboard, size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 8),
            Text('Leaderboard', style: AppTextStyles.titleLarge()),
          ],
        ),
        const SizedBox(height: 16),
        _infoRow('Total Users', '${bc.stats.totalUsers}', isDark),
        _infoRow('Points Distributed', '${bc.stats.totalPoints}', isDark),
        _infoRow('Transactions', '${bc.stats.totalTxs}', isDark),
        _infoRow('Supply Remaining', _formatNum(bc.stats.remaining), isDark),
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          Text(value, style: AppTextStyles.bodyLarge()),
        ],
      ),
    );
  }

  String _formatNum(dynamic n) {
    final num = int.tryParse(n.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _Card({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
