// lib/screens/market_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/hybrid_ai_service.dart';
import '../services/p2p_service.dart';
import '../core/theme/app_theme.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  File? _selectedImage;
  Position? _currentPosition;
  Map<String, dynamic>? _aiResult;
  bool _isAnalyzing = false;

  final HybridAIService _aiService = HybridAIService();
  final P2PService _p2pService = P2PService();

  Future<void> _takePhoto() async {
    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null) return;

    setState(() {
      _selectedImage = File(photo.path);
      _isAnalyzing = true;
    });

    _currentPosition = await Geolocator.getCurrentPosition();

    final result = await _aiService.analyzeProductWithLocation(
      _selectedImage!,
      _currentPosition!,
    );

    setState(() {
      _aiResult = result;
      _isAnalyzing = false;
    });
  }

  Future<void> _uploadToMarket() async {
    if (_aiResult == null) return;

    final success = await _p2pService.propagateToNearby(
      contentId: "market_${DateTime.now().millisecondsSinceEpoch}",
      contentType: "market_product",
      location: _currentPosition!,
      radiusKm: 10.0,
      metadata: _aiResult,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 P2P Market에 등록 및 주변 전파 완료!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏪 Market"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Camera / Photo Section ---
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 320,
                decoration: AppTheme.strongGlass,
                child: _selectedImage == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 80, color: Colors.white54),
                            SizedBox(height: 16),
                            Text(
                              "📸 사진 찍어서 바로 판매",
                              style: TextStyle(fontSize: 20, color: Colors.white70),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "AI가 자동 분석 + 위치 기반 P2P 전파",
                              style: TextStyle(fontSize: 14, color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // --- AI Analysis Loading ---
            if (_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassDecoration,
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: 16),
                    Text(
                      "🤖 AI가 사진을 분석하고 있어요...",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "제품명, 가격, 카테고리를 자동 추출합니다",
                      style: TextStyle(fontSize: 13, color: Colors.white38),
                    ),
                  ],
                ),
              ),

            // --- AI Result Card ---
            if (_aiResult != null && !_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _aiResult!['category'] ?? '기타',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.location_on, size: 16, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          "${_aiResult!['location']['lat'].toStringAsFixed(4)}, ${_aiResult!['location']['lng'].toStringAsFixed(4)}",
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      _aiResult!['title'] ?? '제품',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      _aiResult!['description'] ?? '',
                      style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary.withOpacity(0.3), AppTheme.accent.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("💰 ", style: TextStyle(fontSize: 20)),
                          Text(
                            "${_aiResult!['price']} DADA Point",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hashtags
                    Text(
                      _aiResult!['hashtags'] ?? '',
                      style: const TextStyle(fontSize: 14, color: AppTheme.accent),
                    ),
                    const SizedBox(height: 24),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _uploadToMarket,
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text("🚀 P2P Market에 등록하기", style: TextStyle(fontSize: 17)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // --- Info Section ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("💡 Tip", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text(
                    "• 사진을 찍으면 AI가 제품명, 가격, 카테고리를 자동 분석합니다\n"
                    "• 위치 정보가 함께 등록되어 주변 P2P 네트워크로 전파됩니다\n"
                    "• 등록된 제품은 반경 10km 내 사용자에게 자동 노출됩니다\n"
                    "• DADA Point로 거래가 이루어집니다",
                    style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aiService.dispose();
    _p2pService.dispose();
    super.dispose();
  }
}
