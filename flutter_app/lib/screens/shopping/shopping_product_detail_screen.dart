import 'package:flutter/material.dart';
import '../shopping_home_screen.dart';

/// 상품 상세 페이지
class ShoppingProductDetailScreen extends StatefulWidget {
  final ShopProduct product;

  const ShoppingProductDetailScreen({super.key, required this.product});

  @override
  State<ShoppingProductDetailScreen> createState() => _ShoppingProductDetailScreenState();
}

class _ShoppingProductDetailScreenState extends State<ShoppingProductDetailScreen> {
  int _quantity = 1;
  int _selectedImage = 0;

  final List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _images.add(widget.product.image);
    // Add more random images for the detail view
    for (int i = 0; i < 3; i++) {
      _images.add('https://picsum.photos/seed/${widget.product.id}_$i/400/400');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final p = widget.product;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── 상품 이미지 ──
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 380,
                    child: PageView.builder(
                      onPageChanged: (i) => setState(() => _selectedImage = i),
                      itemCount: _images.length,
                      itemBuilder: (_, i) => Image.network(
                        _images[i], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[850], child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey))),
                      ),
                    ),
                  ),
                ),

                // ── 이미지 인디케이터 ──
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _images.asMap().entries.map((e) => Container(
                      width: _selectedImage == e.key ? 20 : 6, height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _selectedImage == e.key ? const Color(0xFFF02C56) : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )).toList(),
                  ),
                ),

                // ── 상품 정보 ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 가격
                        Row(
                          children: [
                            Text(
                              '₩${_formatPrice(p.price)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            if (p.originalPrice > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₩${_formatPrice(p.originalPrice)}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500], decoration: TextDecoration.lineThrough),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF02C56).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${((1 - p.price / p.originalPrice) * 100).toStringAsFixed(0)}% OFF',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFF02C56), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 상품명
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 평점/판매량
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[400]),
                            const SizedBox(width: 4),
                            Text('${p.rating}', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                            Text('  |  ', style: TextStyle(color: Colors.grey[600])),
                            Text('${_formatSales(p.sales)}개 판매', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(p.shop, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                // ── 상품 설명 ──
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 6),
                            Text('상품 상세 정보', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '고품질 제품입니다. DADA-AI가 엄선한 상품만을 판매합니다.\n\n'
                          '• 정품 보장\n'
                          '• 무료 배송 (50,000원 이상)\n'
                          '• 7일 이내 무료 반품\n'
                          '• DADA 포인트 적립 (1%)',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // ── 하단 구매 버튼 ──
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // 장바구니 아이콘
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                        onPressed: () {},
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 구매 버튼
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFF02C56), const Color(0xFFF02C56).withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('장바구니 담기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000000) return '${(p / 10000).toStringAsFixed(0)}만';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}';
    return p.toStringAsFixed(0);
  }
  String _formatSales(int s) => s >= 10000 ? '${(s / 10000).toStringAsFixed(1)}만' : '${s}';
}
