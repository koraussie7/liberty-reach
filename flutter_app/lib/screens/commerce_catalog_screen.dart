import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/commerce_service.dart';

class CommerceCatalogScreen extends StatefulWidget {
  const CommerceCatalogScreen({super.key});

  @override
  State<CommerceCatalogScreen> createState() => _CommerceCatalogScreenState();
}

class _CommerceCatalogScreenState extends State<CommerceCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommerceService>().trendingProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CommerceService>().cart.length}', style: TextStyle(fontSize: 10, color: Colors.white)),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.pushNamed(context, '/commerce/cart'),
          ),
        ],
      ),
      body: Consumer<CommerceService>(
        builder: (context, commerce, _) {
          final products = commerce.trendingProductsCache;
          if (products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(
                product: product,
                onAddToCart: () {
                  commerce.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const _ProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, fit: BoxFit.cover)
                  : Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (product.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(product.badge!,
                            style: const TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${product.price} DADA',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (product.rewardPoints > 0)
                  Text('+${product.rewardPoints} pts',
                      style: TextStyle(color: Colors.green[600], fontSize: 11)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAddToCart,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
