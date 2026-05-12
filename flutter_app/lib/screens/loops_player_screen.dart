import 'package:flutter/material.dart';
import '../services/loops_service.dart';

class LoopsPlayerScreen extends StatelessWidget {
  final int videoIndex;
  final LoopVideo? video;

  const LoopsPlayerScreen({super.key, required this.videoIndex, this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.3), size: 80),
                  const SizedBox(height: 16),
                  Text(
                    video?.title ?? 'Loop ${videoIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video?.description ?? (video != null ? '' : 'Video player ready'),
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 160,
            child: Column(
              children: [
                _ActionButton(icon: Icons.thumb_up, label: '좋아요'),
                const SizedBox(height: 20),
                _ActionButton(icon: Icons.chat_bubble_outline, label: '댓글'),
                const SizedBox(height: 20),
                _ActionButton(icon: Icons.auto_awesome, label: 'AI 분석'),
                const SizedBox(height: 20),
                _ActionButton(icon: Icons.share_outlined, label: '공유'),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text('+${video?.rewardPoints ?? (videoIndex + 1) * 15} DADA', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${video?.viewCount ?? 120 + videoIndex * 15} views', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video?.title ?? 'Loop ${videoIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text(
                    video?.creator ?? 'Liberty Reach',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
        ],
      ),
    );
  }
}
