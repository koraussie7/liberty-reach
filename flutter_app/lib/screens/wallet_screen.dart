import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_service.dart';
import '../core/design_system/design_system.dart';
import 'qr_scan_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 72, color: Colors.white),
                      SizedBox(height: 12),
                      Text('DADA Coin Wallet', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20)],
                    ),
                    child: Column(
                      children: [
                        const Text('Balance', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('${wallet.balance.toStringAsFixed(2)} DADA',
                            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('\u2248 \u20A9${(wallet.balance * 1000).toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.green, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // My QR card
                  if (wallet.isConnected)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          QrImageView(data: 'minima:${wallet.address}', size: 72, backgroundColor: Colors.white, padding: const EdgeInsets.all(4)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Address', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(wallet.maskedAddress, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                  child: const Text('Connected', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!wallet.isConnected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 48, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text('Connect your wallet', style: TextStyle(color: Colors.white54, fontSize: 15)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final ok = await context.read<WalletService>().connect();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? 'Wallet connected' : 'Connection failed'),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                            child: const Text('Connect Wallet', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  // Quick actions
                  Row(
                    children: [
                      _ActionBtn(icon: Icons.qr_code_scanner, label: 'Scan', color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScanScreen()))),
                      const SizedBox(width: 12),
                      _ActionBtn(icon: Icons.send, label: 'Send', color: AppColors.accent, onTap: () {}),
                      const SizedBox(width: 12),
                      _ActionBtn(icon: Icons.history, label: 'History', color: AppColors.secondary, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Disconnect
                  if (wallet.isConnected)
                    TextButton(
                      onPressed: () => context.read<WalletService>().disconnect(),
                      child: const Text('Disconnect', style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
