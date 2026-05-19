import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hyperspace_service.dart';
import '../services/isek_service.dart';
import '../services/agixt_service.dart';
import '../screens/hyperspace_dashboard.dart';
import '../screens/hyperspace_earnings_screen.dart';
import '../screens/hyperspace_pod_screen.dart';
import '../screens/hyperspace_wallet_screen.dart';
import '../screens/hyperspace_ai_chat_screen.dart';
import '../screens/isek_explorer_screen.dart';
import '../screens/isek_identity_screen.dart';
import '../screens/isek_a2a_chat_screen.dart';
import '../screens/agixt_agents_screen.dart';
import '../screens/blockchain_dashboard_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/point_charge_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/reward_dashboard.dart';
import '../screens/commerce_catalog_screen.dart';
import '../screens/commerce_cart_screen.dart';
import '../screens/live_commerce_screen.dart';
import '../screens/business_dashboard_screen.dart';
import '../screens/admin_point_approval_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/loops_screen.dart';
import '../screens/liberty_market_screen.dart';
import '../screens/market_screen.dart';
import '../screens/ai_preference_screen.dart';
import '../screens/supplier_orders_screen.dart';
import '../screens/point_history_screen.dart';

class DSScreen extends StatelessWidget {
  const DSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hs = context.watch<HyperspaceService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 DADA 런처'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 서비스 카테고리 ──
          _sectionHeader(context, '📱 서비스'),
          _wrap([
            _navCard(context, '🍜 음식 배달', 'Food Delivery', Icons.restaurant, '/food/request', null),
            _navCard(context, '🚕 택시', 'Taxi Service', Icons.local_taxi, '/taxi/request', null),
            _navCard(context, '💆 마사지', 'Massage Service', Icons.spa, '/massage/request', null),
            _navCard(context, '🏨 호텔', 'Hotel Booking', Icons.hotel, '/hotel/request', null),
            _navCard(context, '💞 SparkMatch', 'Dating', Icons.favorite, '/discover', Colors.pink),
          ]),

          const SizedBox(height: 20),
          // ── AI & 블록체인 ──
          _sectionHeader(context, '🤖 AI & 블록체인'),
          _wrap([
            _navCard(context, '🔲 Hyperspace', 'P2P AI Network · ${hs.nodeRunning ? "Running" : "Stopped"}', Icons.dns, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HyperspaceDashboard()));
            }, hs.nodeRunning ? Colors.green : Colors.grey),
            _navCard(context, '💬 Hyperspace Chat', 'AI Chat', Icons.chat_bubble, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HyperspaceAIChatScreen()));
            }, null),
            _navCard(context, '👥 Hyperspace Pod', 'Pod Management', Icons.groups, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HyperspacePodScreen()));
            }, null),
            _navCard(context, '💰 Hyperspace 수익', 'Earnings', Icons.monetization_on, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HyperspaceEarningsScreen()));
            }, Colors.amber),
            _navCard(context, '💳 Hyperspace 지갑', 'Wallet', Icons.account_balance_wallet, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HyperspaceWalletScreen()));
            }, null),
            _navCard(context, '🔗 ISEK 에이전트', 'Agent-to-Agent', Icons.hub, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ISEKExplorerScreen()));
            }, null),
            _navCard(context, '🆔 ISEK Identity', 'Identity', Icons.badge, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ISEKIdentityScreen()));
            }, null),
            _navCard(context, '🔐 ISEK A2A Chat', 'Secure Chat', Icons.lock, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ISEKA2AChatScreen()));
            }, null),
            _navCard(context, '🤖 AGiXT', 'AI Agent Automation', Icons.smart_toy, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AGiXTAgentsScreen()));
            }, null),
            _navCard(context, '🧠 AI Preference', 'Predict / Train / Feedback', Icons.tune, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPreferenceScreen()));
            }, Colors.purple),
            _navCard(context, '⛓️ 블록체인', 'Blockchain Dashboard', Icons.link, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainDashboard()));
            }, Colors.cyan),
            _navCard(context, '🏆 리더보드', 'Leaderboard', Icons.leaderboard, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            }, Colors.amber),
          ]),

          const SizedBox(height: 20),
          // ── 커머스 & 마켓 ──
          _sectionHeader(context, '🛒 커머스 & 마켓'),
          _wrap([
            _navCard(context, '🛍️ Liberty Market', 'P2P Market', Icons.store, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LibertyMarketScreen()));
            }, null),
            _navCard(context, '📦 Commerce', 'Product Catalog', Icons.inventory_2, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceCatalogScreen()));
            }, null),
            _navCard(context, '🛒 장바구니', 'Cart', Icons.shopping_cart, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceCartScreen()));
            }, null),
            _navCard(context, '📺 라이브 커머스', 'Live Shopping', Icons.live_tv, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveCommerceScreen()));
            }, Colors.red),
            _navCard(context, '🏪 마켓', 'Marketplace', Icons.storefront, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketScreen()));
            }, null),
          ]),

          const SizedBox(height: 20),
          // ── 파이낸스 ──
          _sectionHeader(context, '💰 파이낸스'),
          _wrap([
            _navCard(context, '💳 지갑', 'Vultisig Wallet', Icons.account_balance_wallet, '/auth/signup', const Color(0xFF6B46C1)),
            _navCard(context, '🔗 Vultisig Join', 'Account Join', Icons.person_add_alt_1, '/auth/signup', const Color(0xFF8B5CF6)),
            _navCard(context, '⚡ 포인트 충전', 'Dada Point', Icons.bolt, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PointChargeScreen()));
            }, Colors.yellow),
            _navCard(context, '📜 포인트 내역', 'Point History', Icons.history, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PointHistoryScreen()));
            }, Colors.amber),
            _navCard(context, '💵 결제', 'Payment Methods', Icons.payment, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen(amount: 0, productId: '', description: '')));
            }, Colors.green),
            _navCard(context, '🎁 리워드', 'Rewards', Icons.card_giftcard, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardDashboard()));
            }, Colors.purple),
          ]),

          const SizedBox(height: 20),
          // ── 어드민 & 비즈니스 ──
          _sectionHeader(context, '⚙️ 어드민 & 비즈니스'),
          _wrap([
            _navCard(context, '📊 비즈니스', 'Supplier Dashboard', Icons.business, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()));
            }, Colors.blue),
            _navCard(context, '📋 주문 관리', 'Supplier Orders', Icons.receipt_long, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierOrdersScreen()));
            }, Colors.indigo),
            _navCard(context, '🛠️ 포인트 승인', 'Admin: Approve Charges', Icons.admin_panel_settings, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPointApprovalScreen()));
            }, Colors.orange),
          ]),

          const SizedBox(height: 20),
          // ── 소셜 & 컨텐츠 ──
          _sectionHeader(context, '💬 소셜 & 컨텐츠'),
          _wrap([
            _navCard(context, '💬 채팅', 'Chat List', Icons.chat, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
            }, null),
            _navCard(context, '▶️ Loops', 'Shorts & Videos', Icons.play_circle, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoopsScreen()));
            }, Colors.red),
          ]),

          const SizedBox(height: 20),
          // ── Puter Apps ──
          _sectionHeader(context, '🖥️ Puter Apps'),
          _wrap([
            _puterCard(context, '💬 Team Chat', 'privseai.com/teamchat/', Icons.chat),
            _puterCard(context, '🖥️ Terminal', 'privseai.com/hermes/', Icons.terminal),
            _puterCard(context, '📊 Dashboard', 'privseai.com/dashboard/', Icons.dashboard),
            _puterCard(context, '⛓️ Blockchain', 'privseai.com/blockchain/dashboard/', Icons.link),
            _puterCard(context, '🔭 NEMU', 'privseai.com/nemu/', Icons.monitor_heart),
            _puterCard(context, '🖥️ Puter Desktop', 'puter.privseai.com/', Icons.desktop_windows),
          ]),

          const SizedBox(height: 20),
          // ── 서버 상태 ──
          _sectionHeader(context, '📡 서버 상태'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statusRow('Hyperspace', Icons.dns, hs.agentOnline, hs.agentOnline ? 'Connected' : 'Offline'),
                  const Divider(),
                  _statusRow('Puter', Icons.cloud, true, 'puter.privseai.com'),
                  const Divider(),
                  _statusRow('Caddy', Icons.web, true, 'privseai.com'),
                  const Divider(),
                  _statusRow('Backend API', Icons.code, true, 'localhost:8000'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.grey[400],
        fontWeight: FontWeight.w700,
      )),
    );
  }

  Widget _wrap(List<Widget> children) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }

  Widget _puterCard(BuildContext context, String title, String url, IconData icon) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => launchUrl(Uri.parse('https://$url'), webOnlyWindowName: '_blank'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 36, color: Colors.deepPurpleAccent),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navCard(BuildContext context, String title, String subtitle, IconData icon, dynamic onTap, Color? dotColor) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2 - 4,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onTap is Function()) {
              onTap();
            } else if (onTap is String) {
              Navigator.pushNamed(context, onTap as String);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: dotColor ?? Colors.deepPurpleAccent),
                    if (dotColor != null) ...[
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String label, IconData icon, bool active, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: active ? Colors.green : Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, color: active ? Colors.green : Colors.grey)),
      ],
    );
  }

}
