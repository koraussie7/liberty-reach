import 'package:flutter/material.dart';
import '../services/loops_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/hybrid_ai_service.dart';

class LoopsPlayerScreen extends StatefulWidget {
  final int videoIndex;
  final LoopVideo? video;

  const LoopsPlayerScreen({super.key, required this.videoIndex, this.video});

  @override
  State<LoopsPlayerScreen> createState() => _LoopsPlayerScreenState();
}

class _LoopsPlayerScreenState extends State<LoopsPlayerScreen> {
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
    _likeCount = 120 + widget.videoIndex * 7;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.video?.videoUrl;
    if (url == null || url.isEmpty) {
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
        placeholder: Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        errorBuilder: (ctx, msg) => const Center(
          child: Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        ),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_isLoading)
            const ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator(color: Colors.white)))
          else if (_hasError)
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(widget.video?.title ?? 'Loop ${widget.videoIndex + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _initPlayer,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text('Retry', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (_videoController!.value.isPlaying) _videoController!.pause();
                else _videoController!.play();
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

          // Bottom gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Right action buttons
          Positioned(
            right: 16,
            bottom: size.height * 0.3,
            child: Column(
              children: [
                _ActionBtn(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_outlined,
                  color: _isLiked ? Colors.red : Colors.white,
                  label: _formatCount(_likeCount),
                  onTap: () => setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; }),
                ),
                const SizedBox(height: 20),
                const _ActionBtn(icon: Icons.chat_bubble_outline, color: Colors.white, label: '댓글'),
                const SizedBox(height: 20),
                _ActionBtn(
                  icon: Icons.auto_awesome, color: _isAnalyzing ? Colors.amber : Colors.white,
                  label: 'AI', onTap: _analyzeWithAI,
                ),
                const SizedBox(height: 20),
                const _ActionBtn(icon: Icons.share_outlined, color: Colors.white, label: '공유'),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 16, right: 80,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14, backgroundColor: Colors.blueAccent.withValues(alpha: 0.6),
                      child: Text(
                        (widget.video?.creator ?? 'L')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.video?.creator ?? 'Liberty Reach',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.video?.title ?? 'Loop ${widget.videoIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.video?.description ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 4),
                    Text('+${widget.video?.rewardPoints ?? 15} DADA',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Icon(Icons.visibility, color: Colors.white.withValues(alpha: 0.4), size: 14),
                    const SizedBox(width: 4),
                    Text('${_formatCount(widget.video?.viewCount ?? 0)} views',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeWithAI() async {
    setState(() => _isAnalyzing = true);
    final result = await _ai.process('Analyze this video: ${widget.video?.title ?? "Loop ${widget.videoIndex + 1}"}');
    setState(() => _isAnalyzing = false);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              const Text('AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.grey)),
            ]),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            SelectableText(result, style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int c) => c >= 1000 ? '${(c / 1000).toStringAsFixed(1)}K' : c.toString();
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final Color color; final String label; final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.color, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
    ]),
  );
}
