import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/commerce_service.dart';

class CommerceCartScreen extends StatelessWidget {
  const CommerceCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: Consumer<CommerceService>(
        builder: (context, commerce, _) {
          final cart = commerce.cart;
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Cart is empty', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/commerce/catalog'),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }

          final total = cart.fold<int>(0, (sum, item) => sum + item.product.price * item.quantity);
          final totalPoints = cart.fold<int>(0, (sum, item) => sum + item.product.rewardPoints * item.quantity);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.product.imageUrl.isNotEmpty
                                  ? Image.network(item.product.imageUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${item.product.price} DADA × ${item.quantity}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle, size: 20),
                                  onPressed: () => commerce.updateQuantity(item.product.id, item.quantity + 1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, size: 20),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      commerce.updateQuantity(item.product.id, item.quantity - 1);
                                    } else {
                                      commerce.removeFromCart(item.product.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 16)),
                          Text('$total DADA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (totalPoints > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reward Points:', style: TextStyle(fontSize: 13, color: Colors.green[600])),
                            Text('+$totalPoints pts', style: TextStyle(fontSize: 13, color: Colors.green[600])),
                          ],
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _checkout(context, commerce),
                          icon: const Icon(Icons.payment),
                          label: const Text('Checkout'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _checkout(BuildContext context, CommerceService commerce) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Complete your purchase?'),
            const SizedBox(height: 16),
            Text('${commerce.cart.length} items', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              commerce.checkout();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchase complete! +Rewards earned')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
