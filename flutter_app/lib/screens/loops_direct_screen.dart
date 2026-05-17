import 'package:flutter/material.dart';
import '../services/loops_service.dart';
import 'loops_player_screen.dart';

/// Directly opens the first available Loop video in the player.
/// Loads from API first, falls back to demo videos.
class LoopsDirectScreen extends StatefulWidget {
  const LoopsDirectScreen({super.key});

  @override
  State<LoopsDirectScreen> createState() => _LoopsDirectScreenState();
}

class _LoopsDirectScreenState extends State<LoopsDirectScreen> {
  final LoopsService _service = LoopsService();
  List<LoopVideo> _videos = [];
  bool _loading = true;

  // Demo videos for when API is unavailable
  static final List<LoopVideo> _demoVideos = [
    LoopVideo(
      id: 'demo_1',
      title: 'Bigger Blazes',
      description: 'Liberty Reach AI P2P Messenger',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      viewCount: 120,
      rewardPoints: 15,
      creator: 'Liberty Reach',
    ),
    LoopVideo(
      id: 'demo_2',
      title: 'Bigger Escapes',
      description: 'Liberty Reach AI P2P Messenger',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      viewCount: 87,
      rewardPoints: 10,
      creator: 'Liberty Reach',
    ),
    LoopVideo(
      id: 'demo_3',
      title: 'Bigger Fun',
      description: 'Liberty Reach AI P2P Messenger',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      viewCount: 200,
      rewardPoints: 25,
      creator: 'Liberty Reach',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final feed = await _service.getFeed();
    if (!mounted) return;
    setState(() {
      _videos = feed.isNotEmpty ? feed : _demoVideos;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF02C56)),
        ),
      );
    }

    // Show first video
    return LoopsPlayerScreen(videoIndex: 0, video: _videos.isNotEmpty ? _videos[0] : null);
  }
}
