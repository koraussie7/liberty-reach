import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/loops_service.dart';
import '../services/hybrid_ai_service.dart';

/// Full TikTok-style video player card embedded directly in the Loops feed.
/// All controls (like, comment, AI, share) and info are shown inline —
/// no navigation to a separate player screen needed.
class TikTokVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String uploader;
  final LoopVideo? loopVideo;

  const TikTokVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title = 'Untitled Video',
    this.uploader = 'Anonymous',
    this.loopVideo,
  });

  @override
  State<TikTokVideoPlayer> createState() => _TikTokVideoPlayerState();
}

class _TikTokVideoPlayerState extends State<TikTokVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isAnalyzing = false;
  final HybridAIService _ai = HybridAIService();

  @override
  void initState() {
    super.initState();
    _likeCount = 120 + (widget.loopVideo?.id.hashCode.abs() ?? 0) % 200;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.videoUrl;
    if (url.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: false,
        showOptions: false,
        allowFullScreen: false,
        allowMuting: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (ctx, msg) => const Center(
          child: Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
        ),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[TikTokCard] Init error: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _ai.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithAI() async {
    setState(() => _isAnalyzing = true);
    final result = await _ai.process(
      'Analyze this video: ${widget.title}',
    );
    setState(() => _isAnalyzing = false);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ]),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            SelectableText(
              result,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int c) =>
      c >= 1000 ? '${(c / 1000).toStringAsFixed(1)}K' : c.toString();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 16 / 9;

    return SizedBox(
      height: cardHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video / placeholder ──
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_hasError)
            Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
            ),

          // ── Bottom gradient overlay ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Right action buttons ──
          Positioned(
            right: 12,
            bottom: cardHeight * 0.28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_outlined,
                  color: _isLiked ? Colors.red : Colors.white,
                  label: _formatCount(_likeCount),
                  onTap: () => setState(() {
                    _isLiked = !_isLiked;
                    _likeCount += _isLiked ? 1 : -1;
                  }),
                ),
                const SizedBox(height: 16),
                const _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.white,
                  label: '댓글',
                ),
                const SizedBox(height: 16),
                _ActionBtn(
                  icon: Icons.auto_awesome,
                  color: _isAnalyzing ? Colors.amber : Colors.white,
                  label: 'AI',
                  onTap: _analyzeWithAI,
                ),
                const SizedBox(height: 16),
                const _ActionBtn(
                  icon: Icons.share_outlined,
                  color: Colors.white,
                  label: '공유',
                ),
              ],
            ),
          ),

          // ── Bottom info strip ──
          Positioned(
            left: 16,
            right: 80,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Creator row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.6),
                      child: Text(
                        (widget.uploader)[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.uploader,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Description (from loopVideo)
                if (widget.loopVideo?.description != null &&
                    widget.loopVideo!.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.loopVideo!.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                // Reward & views
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+${widget.loopVideo?.rewardPoints ?? 15} DADA',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${_formatCount(widget.loopVideo?.viewCount ?? 0)} views',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
