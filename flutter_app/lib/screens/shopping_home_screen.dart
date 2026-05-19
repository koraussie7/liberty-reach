import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/shopping_product_card.dart';
import 'shopping/shopping_product_detail_screen.dart';

/// 샘플 상품 모델
class ShopProduct {
  final String id;
  final String name;
  final String image;
  final double price;
  final double originalPrice;
  final int sales;
  final double rating;
  final String shop;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice = 0,
    this.sales = 0,
    this.rating = 4.5,
    this.shop = 'DADA Shop',
  });
}

/// 샘플 상품 데이터
final List<ShopProduct> _demoProducts = [
  ShopProduct(id: 'p1', name: '프리미엄 블루투스 이어폰', image: 'https://picsum.photos/seed/p1/400/400', price: 45000, originalPrice: 89000, sales: 1234, rating: 4.8),
  ShopProduct(id: 'p2', name: '스마트 워치 프로', image: 'https://picsum.photos/seed/p2/400/400', price: 129000, originalPrice: 199000, sales: 856, rating: 4.6),
  ShopProduct(id: 'p3', name: '미니 무선 충전기', image: 'https://picsum.photos/seed/p3/400/400', price: 15000, originalPrice: 25000, sales: 3210, rating: 4.4),
  ShopProduct(id: 'p4', name: '노이즈 캔슬링 헤드셋', image: 'https://picsum.photos/seed/p4/400/400', price: 89000, originalPrice: 159000, sales: 567, rating: 4.9),
  ShopProduct(id: 'p5', name: '휴대용 파워뱅크 20000mAh', image: 'https://picsum.photos/seed/p5/400/400', price: 35000, originalPrice: 55000, sales: 1890, rating: 4.5),
  ShopProduct(id: 'p6', name: 'LED 키보드 (기계식)', image: 'https://picsum.photos/seed/p6/400/400', price: 67000, originalPrice: 99000, sales: 723, rating: 4.7),
  ShopProduct(id: 'p7', name: '4K 웹캠', image: 'https://picsum.photos/seed/p7/400/400', price: 78000, originalPrice: 120000, sales: 445, rating: 4.3),
  ShopProduct(id: 'p8', name: '슬림 노트북 파우치', image: 'https://picsum.photos/seed/p8/400/400', price: 22000, originalPrice: 39000, sales: 2567, rating: 4.6),
];

/// 쇼핑 카테고리
const List<Map<String, dynamic>> _categories = [
  {'icon': Icons.phone_iphone, 'label': '전자기기', 'color': Color(0xFF6366F1)},
  {'icon': Icons.headphones, 'label': '오디오', 'color': Color(0xFF8B5CF6)},
  {'icon': Icons.watch, 'label': '웨어러블', 'color': Color(0xFF06B6D4)},
  {'icon': Icons.kitchen, 'label': '주방용품', 'color': Color(0xFF10B981)},
  {'icon': Icons.checkroom, 'label': '패션', 'color': Color(0xFFF43F5E)},
  {'icon': Icons.sports_esports, 'label': '게임', 'color': Color(0xFFF97316)},
  {'icon': Icons.home, 'label': '홈데코', 'color': Color(0xFF84CC16)},
  {'icon': Icons.auto_awesome, 'label': '기타', 'color': Color(0xFFA855F7)},
];

class ShoppingHomeScreen extends StatefulWidget {
  const ShoppingHomeScreen({super.key});

  @override
  State<ShoppingHomeScreen> createState() => _ShoppingHomeScreenState();
}

class _ShoppingHomeScreenState extends State<ShoppingHomeScreen> {
  final _searchController = TextEditingController();
  final List<ShopProduct> _products = _demoProducts;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('DADA 쇼핑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingCartScreen())),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── 검색 바 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingSearchScreen())),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Text('검색어를 입력하세요', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 배너 스와이퍼 ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: _BannerSwiper(),
            ),
          ),

          // ── 카테고리 그리드 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 90,
                child: Row(
                  children: _categories.map((c) => Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: (c['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(c['icon'], color: c['color'], size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(c['label'], style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),

          // ── 섹션 헤더: 인기상품 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(width: 3, height: 16, decoration: BoxDecoration(
                    color: const Color(0xFFF02C56), borderRadius: BorderRadius.circular(2),
                  )),
                  const SizedBox(width: 8),
                  const Text('🔥 인기 상품', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text('전체보기', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ),
                ],
              ),
            ),
          ),

          // ── 상품 그리드 ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => ShoppingProductCard(
                  product: _products[i],
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ShoppingProductDetailScreen(product: _products[i]),
                  )),
                ),
                childCount: _products.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ── 배너 스와이퍼 ──
class _BannerSwiper extends StatefulWidget {
  @override
  State<_BannerSwiper> createState() => _BannerSwiperState();
}

class _BannerSwiperState extends State<_BannerSwiper> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  final List<String> _banners = [
    'https://picsum.photos/seed/b1/800/400',
    'https://picsum.photos/seed/b2/800/400',
    'https://picsum.photos/seed/b3/800/400',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _current = i),
          children: _banners.map((url) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.cover, width: double.infinity,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.image, color: Colors.grey))),
                loadingBuilder: (_, child, progress) => progress == null ? child : Container(color: Colors.grey[850], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            ),
          )).toList(),
        ),
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _banners.asMap().entries.map((e) => Container(
              width: _current == e.key ? 20 : 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _current == e.key ? const Color(0xFFF02C56) : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// ── 장바구니 스크린 (간단 버전) ──
class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('장바구니')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('장바구니가 비어있습니다', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ── 검색 스크린 ──
class ShoppingSearchScreen extends StatelessWidget {
  const ShoppingSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상품 검색')),
      body: const Center(
        child: Text('검색 기능 준비 중'),
      ),
    );
  }
}
