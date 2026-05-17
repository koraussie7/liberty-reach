import 'package:flutter/material.dart';
import '../core/design_system/app_colors.dart';
import '../core/design_system/app_text_styles.dart';
import '../services/loops_service.dart';
import '../widgets/tiktok_video_player.dart';

class LoopsScreen extends StatefulWidget {
  const LoopsScreen({super.key});

  @override
  State<LoopsScreen> createState() => _LoopsScreenState();
}

class _LoopsScreenState extends State<LoopsScreen> {
  final LoopsService _service = LoopsService();
  List<LoopVideo> _videos = [];
  bool _loading = true;

  static const _fallbackVideos = [
    _FallbackVideo(
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      title: 'Bigger Blazes',
      uploader: 'Google Samples',
    ),
    _FallbackVideo(
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      title: 'Bigger Escapes',
      uploader: 'Google Samples',
    ),
    _FallbackVideo(
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      title: 'Bigger Fun',
      uploader: 'Google Samples',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final feed = await _service.getFeed();
    if (mounted) {
      setState(() {
        _videos = feed;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Widget _buildFeaturedCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primaryDark.withValues(alpha: 0.5),
            AppColors.background,
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Color(0xFFFF6B35), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '지금 가장 핫한 Loop',
                        style: AppTextStyles.labelLarge(color: const Color(0xFFFF6B35)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liberty Reach AI',
                    style: AppTextStyles.headlineMedium(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI P2P 탈중앙 메신저',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoopCard(LoopVideo v) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: TikTokVideoPlayer(
              videoUrl: v.videoUrl ?? v.thumbnailUrl ?? '',
              title: v.title,
              uploader: v.creator,
              loopVideo: v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        style: AppTextStyles.titleMedium(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.creator,
                        style: AppTextStyles.bodyMedium(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${v.viewCount}',
                      style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, color: Color(0xFFF02C56), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${v.rewardPoints}',
                      style: AppTextStyles.bodySmall(color: AppColors.primary),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: const _LoopsAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_videos.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: const _LoopsAppBar(),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _videos.length,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(bottom: i < _videos.length - 1 ? 20 : 0),
            child: _buildLoopCard(_videos[i]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const _LoopsAppBar(),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _fallbackVideos.length + 1, // +1 for featured card
        itemBuilder: (_, i) {
          if (i == 0) return _buildFeaturedCard();
          final v = _fallbackVideos[i - 1];
          return Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: TikTokVideoPlayer(
                      videoUrl: v.url,
                      title: v.title,
                      uploader: v.uploader,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.title,
                                style: AppTextStyles.titleMedium(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                v.uploader,
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.visibility_outlined, color: Color(0xFF64748B), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${120 + i * 15}',
                              style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.local_fire_department, color: Color(0xFFF02C56), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${i * 15 + 15}',
                              style: AppTextStyles.bodySmall(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoopsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LoopsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Color(0xFFF02C56), size: 22),
          SizedBox(width: 8),
          Text(
            'DADA-AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _FallbackVideo {
  final String url;
  final String title;
  final String uploader;

  const _FallbackVideo({
    required this.url,
    required this.title,
    required this.uploader,
  });
}
