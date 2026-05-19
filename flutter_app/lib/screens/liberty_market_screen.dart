import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'shopping_home_screen.dart';

class LibertyMarketScreen extends StatefulWidget {
  const LibertyMarketScreen({super.key});

  @override
  State<LibertyMarketScreen> createState() => _LibertyMarketScreenState();
}

class _LibertyMarketScreenState extends State<LibertyMarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.fastfood, 'label': 'Food Delivery', 'color': const Color(0xFFF97316)},
    {'icon': Icons.local_taxi, 'label': 'Taxi / Ride', 'color': const Color(0xFF3B82F6)},
    {'icon': Icons.self_improvement, 'label': 'Massage & Spa', 'color': const Color(0xFFA855F7)},
    {'icon': Icons.hotel, 'label': 'Hotel Booking', 'color': const Color(0xFF14B8A6)},
  ];

  final List<Map<String, dynamic>> _orders = [
    {'user': '서울 → 부산', 'price': '₩45,000', 'distance': '320km', 'bids': 3, 'time': '5분 전', 'rating': 4.8, 'lat': 37.5665, 'lng': 126.9780},
    {'user': '강남 삼겹살', 'price': '₩12,000', 'distance': '2km', 'bids': 7, 'time': '2분 전', 'rating': 4.5, 'lat': 37.4979, 'lng': 127.0276},
    {'user': '홈케어 60분', 'price': '₩65,000', 'distance': '1.5km', 'bids': 2, 'time': '10분 전', 'rating': 4.9, 'lat': 37.5512, 'lng': 126.9882},
    {'user': '호텔 A 특가', 'price': '₩89,000', 'distance': '3km', 'bids': 5, 'time': '1분 전', 'rating': 4.7, 'lat': 37.5794, 'lng': 126.9910},
    {'user': '제주 → 서울', 'price': '₩55,000', 'distance': '450km', 'bids': 4, 'time': '15분 전', 'rating': 4.6, 'lat': 37.5665, 'lng': 126.9780},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Liberty Market', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('통합 마켓플레이스', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Live', style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFF02C56),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: const Color(0xFFF02C56),
          unselectedLabelColor: Colors.grey[500],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: '📦 경매', iconMargin: EdgeInsets.only(right: 4)),
            Tab(text: '🛒 쇼핑', iconMargin: EdgeInsets.only(right: 4)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab 1: 경매 (기존 Market) ──
          _buildAuctionTab(isDark),
          // ── Tab 2: 쇼핑 (AiRi 스타일) ──
          const ShoppingHomeScreen(),
        ],
      ),
    );
  }

  Widget _buildAuctionTab(bool isDark) {
    final cat = _categories[_selectedCategory];
    return Column(
      children: [
        // Category Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: _categories.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              final isSelected = i == _selectedCategory;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? c['color'].withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: c['color'].withValues(alpha: 0.3)) : null,
                    ),
                    child: Column(
                      children: [
                        Icon(c['icon'], color: isSelected ? c['color'] : Colors.grey[500], size: 20),
                        const SizedBox(height: 3),
                        Text(c['label'], style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w600,
                          color: isSelected ? c['color'] : Colors.grey[500],
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Map + Orders split view
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildMap(cat)),
              Expanded(flex: 2, child: _buildOrdersList(cat)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(Map<String, dynamic> cat) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(37.5665, 126.9780),
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.privseai.dada',
              ),
              MarkerLayer(
                markers: _orders.map((o) => Marker(
                  point: LatLng(o['lat'], o['lng']),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cat['color'],
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: cat['color'].withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                    child: Text('₩', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )).toList(),
              ),
            ],
          ),
          Positioned(top: 8, right: 8,
            child: FloatingActionButton.small(
              heroTag: 'post_order_map',
              backgroundColor: Colors.deepPurpleAccent,
              onPressed: () {},
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          Positioned(top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat['icon'], size: 12, color: cat['color']),
                  const SizedBox(width: 4),
                  Text('${_orders.length} active', style: const TextStyle(fontSize: 10, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(Map<String, dynamic> cat) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        return Card(
          color: const Color(0xFF1A1A2E),
          margin: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(o['rating'] >= 4.8 ? Icons.bolt : Icons.local_offer, size: 14, color: cat['color']),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(o['user'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      Text(o['price'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cat['color'])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(o['distance'], style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                        child: Text('${o['bids']} bids', style: const TextStyle(fontSize: 9, color: Colors.green)),
                      ),
                      const Spacer(),
                      Icon(Icons.star, size: 10, color: Colors.amber[300]),
                      Text('${o['rating']}', style: TextStyle(fontSize: 9, color: Colors.amber[300])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
