import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/home_service.dart';
import '../widgets/p2p_video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _service = HomeService();
  List<HomeVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final feed = await _service.getFeed();
      if (mounted) {
        setState(() {
          _videos = feed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("DADA-AI", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final featured = _videos.isNotEmpty ? _videos[0] : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured != null)
            _FeaturedCard(video: featured, onTap: () => _playVideo(featured)),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Trending Loops",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 280,
            child: _videos.isEmpty
                ? const Center(child: Text("No videos yet", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return _VideoCard(
                        video: video,
                        onTap: () => _playVideo(video),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _playVideo(HomeVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(video.title, style: const TextStyle(fontSize: 16)),
          ),
          body: Center(
            child: P2PVideoPlayer(
              videoUrl: video.videoUrl,
              title: video.title,
              uploader: 'DADA-AI',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Feature Card ────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final HomeVideo video;
  final VoidCallback onTap;

  const _FeaturedCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = video.thumbnailUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
          image: thumbUrl != null
              ? DecorationImage(
                  image: NetworkImage(thumbUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 6),
                  Text("🔥 지금 가장 핫한 Loop", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "커플 챌린지 ${video.title}",
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("▶ 지금 보기", style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Video Card ───────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final HomeVideo video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = video.thumbnailUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: AppTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbUrl != null)
                      Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => const _PlaceholderThumb(),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      )
                    else
                      const _PlaceholderThumb(),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#커플챌린지",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.title,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Colors.grey, size: 40),
      ),
    );
  }
}
