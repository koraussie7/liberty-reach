import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/hybrid_ai_service.dart';
import '../services/reward_service.dart';

class P2PVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String uploader;
  final String? userAddress;

  const P2PVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title = 'Untitled Video',
    this.uploader = 'Anonymous',
    this.userAddress,
  });

  @override
  State<P2PVideoPlayer> createState() => _P2PVideoPlayerState();
}

class _P2PVideoPlayerState extends State<P2PVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  final HybridAIService _ai = HybridAIService();
  final RewardService _reward = RewardService();
  bool _isLoading = true;
  bool _hasError = false;
  int _watchedSeconds = 0;
  Timer? _rewardTimer;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        showControls: true,
        errorBuilder: (ctx, msg) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Playback error', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 8),
                TextButton(onPressed: _initializePlayer, child: const Text('Retry')),
              ],
            ),
          ),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );

      _videoController.addListener(_onVideoStateChange);
      _startRewardTimer();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[P2PVideo] Init error: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _onVideoStateChange() {
    if (!_videoController.value.isPlaying && _videoController.value.isInitialized) {
      final pos = _videoController.value.position;
      final dur = _videoController.value.duration;
      if (dur > Duration.zero && pos >= dur) {
        _rewardTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('+${_watchedSeconds ~/ 15} DADA Points earned!'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.purple.shade700,
            ),
          );
        }
      }
    }
  }

  void _startRewardTimer() {
    _rewardTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!_videoController.value.isPlaying || widget.userAddress == null) return;
      _watchedSeconds += 15;

      final result = await _reward.rewardForWatch(
        userAddress: widget.userAddress!,
        actionId: widget.videoUrl.hashCode.toString(),
        seconds: _watchedSeconds,
      );

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFEE500), size: 18),
                const SizedBox(width: 8),
                Text('+${result.pointsEarned} DADA Point'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _rewardTimer?.cancel();
    _videoController.removeListener(_onVideoStateChange);
    _videoController.dispose();
    _chewieController?.dispose();
    _ai.dispose();
    _reward.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load video', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 8),
                TextButton(onPressed: _initializePlayer, child: const Text('Try Again')),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video player
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),

        // Video info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.uploader,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.auto_awesome,
                label: 'AI Analyze',
                color: Colors.purpleAccent,
                onTap: _isAnalyzing ? null : _analyzeWithAI,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.share,
                label: 'P2P Share',
                color: Colors.cyanAccent,
                onTap: _shareVideo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _analyzeWithAI() async {
    setState(() => _isAnalyzing = true);
    final result = await _ai.process(
      'Analyze this video and summarize its content: ${widget.title} (${widget.videoUrl})',
    );
    setState(() => _isAnalyzing = false);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                const SizedBox(width: 8),
                const Text('AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.grey)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            SelectableText(result, style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _shareVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video shared via P2P network'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
