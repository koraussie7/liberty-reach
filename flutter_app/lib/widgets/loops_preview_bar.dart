import 'package:flutter/material.dart';
import '../services/loops_service.dart';

class LoopsPreviewBar extends StatefulWidget {
  final VoidCallback? onViewAll;

  const LoopsPreviewBar({super.key, this.onViewAll});

  @override
  State<LoopsPreviewBar> createState() => _LoopsPreviewBarState();
}

class _LoopsPreviewBarState extends State<LoopsPreviewBar> {
  final LoopsService _service = LoopsService();
  List<LoopVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final feed = await _service.getFeed();
    if (mounted) {
      setState(() {
        _videos = feed.isNotEmpty ? feed : List.generate(6, (i) => LoopVideo.demo(i));
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 140,
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return Container(
      height: 140,
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                    SizedBox(width: 6),
                    Text("Loops", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                TextButton(
                  onPressed: widget.onViewAll ?? () {},
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                  child: const Text("View All", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _LoopThumbnail(video: _videos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopThumbnail extends StatelessWidget {
  final LoopVideo video;

  const _LoopThumbnail({required this.video});

  @override
  Widget build(BuildContext context) {
    final index = int.tryParse(video.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/loops/player', arguments: video),
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[850],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.4),
                      Colors.primaries[(index + 3) % Colors.primaries.length].withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
            Positioned(
              bottom: 4,
              child: Text(
                video.title.length > 8 ? '${video.title.substring(0, 7)}...' : video.title,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
