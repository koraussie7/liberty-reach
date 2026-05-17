import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/loops_service.dart';

class LoopsListScreen extends StatefulWidget {
  const LoopsListScreen({super.key});

  @override
  State<LoopsListScreen> createState() => _LoopsListScreenState();
}

class _LoopsListScreenState extends State<LoopsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoopsService>().getFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Loops')),
      body: Consumer<LoopsService>(
        builder: (context, loops, _) {
          if (loops.feed.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => loops.getFeed(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: loops.feed.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.66,
              ),
              itemBuilder: (context, index) => _LoopCard(
                video: loops.feed[index],
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoopCard extends StatelessWidget {
  final LoopVideo video;
  final int index;

  const _LoopCard({required this.video, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/loops/player', arguments: video),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: video.thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(video.thumbnailUrl!),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(Colors.black26, BlendMode.darken),
                )
              : null,
          gradient: video.thumbnailUrl == null
              ? LinearGradient(
                  colors: [
                    Colors.primaries[index % Colors.primaries.length].withOpacity(0.4),
                    Colors.primaries[(index + 3) % Colors.primaries.length].withOpacity(0.6),
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (video.thumbnailUrl == null) ...[
              const Icon(Icons.videocam, color: Colors.white70, size: 28),
              const SizedBox(height: 6),
            ],
            Text(video.title ?? 'Loop ${index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${video.viewCount} views',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
