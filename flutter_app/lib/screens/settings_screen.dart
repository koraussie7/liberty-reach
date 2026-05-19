import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/business_dashboard_screen.dart';
import '../services/p2p_service.dart';
import '../services/liberty_bridge.dart';
import '../core/constants/app_constants.dart';
import '../core/design_system/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _aiEnabled = true;
  bool _e2eeEnabled = true;
  String _localAiUrl = AppConstants.defaultAIUrl;

  @override
  Widget build(BuildContext context) {
    final p2p = context.watch<P2PService>();
    final bridge = context.watch<LibertyBridge>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = context.watch<ValueNotifier<ThemeMode>>();
    final themeMode = themeNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(20),
            color: isDark ? AppColors.surfaceLight : Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE8F4FD),
                  child: const Icon(Icons.person, size: 32, color: Color(0xFF0088cc)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Node',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peer ID: ${bridge.peerId ?? p2p.localPeerId ?? '12D3KooW...abcd'}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Appearance
          _sectionHeader('Appearance'),
          _settingTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Theme',
            subtitle: isDark ? 'Dark Mode' : 'Light Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (v) {
                if (v) {
                  context.read<ValueNotifier<ThemeMode>>().value = ThemeMode.dark;
                } else {
                  context.read<ValueNotifier<ThemeMode>>().value = ThemeMode.light;
                }
              },
              activeColor: const Color(0xFFFEE500),
            ),
          ),

          const SizedBox(height: 12),

          // P2P settings
          _sectionHeader('P2P Network'),
          _settingTile(
            icon: Icons.wifi,
            title: 'Connected Peers',
            subtitle: '${p2p.connectedPeers.length} peers connected',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (p2p.isConnected ? const Color(0xFF4CAF50) : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8,
                      color: p2p.isConnected ? const Color(0xFF4CAF50) : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    p2p.isConnected ? 'Online' : 'Offline',
                    style: TextStyle(fontSize: 12,
                        color: p2p.isConnected ? const Color(0xFF4CAF50) : Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (!p2p.isConnected)
            _settingTile(
              icon: Icons.link,
              title: 'Connect to Server',
              subtitle: p2p.isConnecting ? 'Connecting...' : 'Tap to connect',
              onTap: p2p.isConnecting ? null : () => p2p.connect(AppConstants.apiBaseUrl),
            ),
          _settingTile(
            icon: Icons.shield,
            title: 'End-to-End Encryption',
            subtitle: 'Noise Protocol + X25519',
            trailing: Switch(
              value: _e2eeEnabled,
              onChanged: (v) => setState(() => _e2eeEnabled = v),
              activeThumbColor: const Color(0xFF0088cc),
            ),
          ),
          _settingTile(
            icon: Icons.storage,
            title: 'Message Storage',
            subtitle: 'Local persistence (SharedPreferences)',
          ),

          const SizedBox(height: 12),

          // Wallet
          _sectionHeader('Wallet & Account'),
          _settingTile(
            icon: Icons.account_balance_wallet,
            title: 'Wallet Login',
            subtitle: 'Login with your crypto wallet',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.pushNamed(context, '/auth/wallet-login'),
          ),

          const SizedBox(height: 12),

          // AI settings
          _sectionHeader('AI Settings'),
          _settingTile(
            icon: Icons.auto_awesome,
            title: 'AI Assistant',
            subtitle: 'Gemini 2.5 Flash + LocalAI',
            trailing: Switch(
              value: _aiEnabled,
              onChanged: (v) => setState(() => _aiEnabled = v),
              activeThumbColor: const Color(0xFF0088cc),
            ),
          ),
          _settingTile(
            icon: Icons.link,
            title: 'AI Server URL',
            subtitle: _localAiUrl,
            trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
            onTap: () => _editAiUrl(context),
          ),

          const SizedBox(height: 12),

          // About
          _sectionHeader('About'),
          _settingTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: 'Liberty Reach v0.1.0',
          ),
          _settingTile(
            icon: Icons.menu_book,
            title: 'Docs',
            subtitle: 'Obsidian Vault',
          ),

          const SizedBox(height: 12),

          // CS (Customer Service) for Business Owners
          _sectionHeader('CS (Customer Service)'),
          _settingTile(
            icon: Icons.dashboard_customize,
            title: '사업자 대시보드',
            subtitle: '배달 · 호텔 · 식당 매출 및 주문 관리',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey[600], size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ),
      trailing: trailing ?? const SizedBox(),
    );
  }

  void _editAiUrl(BuildContext context) {
    final controller = TextEditingController(text: _localAiUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:8080',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _localAiUrl = controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
