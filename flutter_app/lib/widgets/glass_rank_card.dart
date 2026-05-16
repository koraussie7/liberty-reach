import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';

class GlassRankCard extends StatelessWidget {
  final RankEntry entry;

  const GlassRankCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.isTop3;
    final trophyColors = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop3 ? Colors.yellow.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop3 ? trophyColors[entry.rank - 1].withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isTop3 ? trophyColors[entry.rank - 1] : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTop3
                  ? Icon(Icons.emoji_events, size: 20, color: entry.rank == 1 ? Colors.white : Colors.black87)
                  : Text(
                      '${entry.rank}',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar circle
          CircleAvatar(
            radius: 22,
            backgroundColor: isTop3 ? trophyColors[entry.rank - 1].withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
            child: Text(
              entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: isTop3 ? trophyColors[entry.rank - 1] : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _BadgeLabel(badge: entry.badge),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'DADA',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  final String badge;
  const _BadgeLabel({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = switch (badge) {
      'Legend' => Colors.purpleAccent,
      'Star' => Colors.cyanAccent,
      'Active' => Colors.orangeAccent,
      _ => Colors.grey,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 10, color: color),
        const SizedBox(width: 3),
        Text(badge, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
