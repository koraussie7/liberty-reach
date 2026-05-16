import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../services/commerce_service.dart';

class LiveCommerceScreen extends StatefulWidget {
  const LiveCommerceScreen({super.key});

  @override
  State<LiveCommerceScreen> createState() => _LiveCommerceScreenState();
}

class _LiveCommerceScreenState extends State<LiveCommerceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cs = context.read<CommerceService>();
      cs.startLiveCommerce('live_01', []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CommerceService>(
        builder: (context, commerce, _) {
          final products = commerce.currentRecommendation?.products ?? [];
          final trending = commerce.trendingProductsCache;

          return Stack(
            children: [
              // Video Background
              Image.network(
                "https://picsum.photos/id/1015/800/1200",
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),

              // Top Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 10, color: Colors.white),
                                SizedBox(width: 6),
                                Text(AppConstants.liveLabel, style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Badge(
                              label: Text('${commerce.cartCount}', style: const TextStyle(fontSize: 9, color: Colors.white)),
                              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/commerce/cart'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Hermes AI Floating Panel
              Positioned(
                top: 100,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.smart_toy, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 6),
                          Text(AppConstants.hermesAI, style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        commerce.currentRecommendation?.hermesAnalysis ?? AppConstants.analyzingStream,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Product Bar
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.strongGlass,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(AppConstants.featuredProducts,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${products.length} ${AppConstants.items}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (products.isEmpty && trending.isEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _productChip("\u{1F3A7} Earphones", "45,000P"),
                            const SizedBox(width: 12),
                            _productChip("\u{1F45F} Sneakers", "89,000P"),
                          ],
                        )
                      else
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: (products.isNotEmpty ? products : trending).length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final p = (products.isNotEmpty ? products : trending)[i];
                              return _productCard(p.name, '${p.price}P', p.imageUrl);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Buy & Chat Button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text(AppConstants.purchaseInitiated)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text(AppConstants.buyNow, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.chat_bubble),
                            label: const Text(AppConstants.chatWithHermes),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/commerce/catalog'),
                        icon: const Icon(Icons.store, color: Colors.white70),
                        label: const Text(AppConstants.fullCatalog, style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _productChip(String name, String price) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 13)),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _productCard(String name, String price, String imageUrl) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, height: 40, width: 60, fit: BoxFit.cover),
            ),
          if (imageUrl.isNotEmpty) const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
