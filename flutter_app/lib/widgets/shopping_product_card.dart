import 'package:flutter/material.dart';
import '../screens/shopping_home_screen.dart';

/// 쇼핑몰 상품 카드 위젯
class ShoppingProductCard extends StatelessWidget {
  final ShopProduct product;
  final VoidCallback onTap;

  const ShoppingProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.image, color: Colors.grey[600], size: 32),
                  ),
                ),
              ),
            ),
            // 상품 정보
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₩${_formatPrice(product.price)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (product.originalPrice > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₩${_formatPrice(product.originalPrice)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star, size: 10, color: Colors.amber[400]),
                        const SizedBox(width: 2),
                        Text('${product.rating}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        const SizedBox(width: 6),
                        Text('${_formatSales(product.sales)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) => p >= 1000 ? '${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}' : p.toStringAsFixed(0);
  String _formatSales(int s) => s >= 10000 ? '${(s / 10000).toStringAsFixed(1)}만+' : '$s';
}
