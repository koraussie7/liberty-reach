import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/hyperspace_payment_service.dart';

class HyperspaceWalletScreen extends StatefulWidget {
  const HyperspaceWalletScreen({super.key});
  @override
  State<HyperspaceWalletScreen> createState() =>
      _HyperspaceWalletScreenState();
}

class _HyperspaceWalletScreenState extends State<HyperspaceWalletScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = '0x...';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pay = context.watch<HyperspacePaymentService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('HYPE Wallet')),
      body: RefreshIndicator(
        onRefresh: () => pay.fetchBalance(pay.hypeAddress),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text('HYPE Balance',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${(pay.hypeBalance / 1e18).toStringAsFixed(4)}',
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('HYPE',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 16),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(
                              text: pay.hypeAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Address copied')),
                          );
                        },
                        child: Text(
                          '${pay.hypeAddress.substring(0, 8)}...${pay.hypeAddress.substring(pay.hypeAddress.length - 6)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // Send HYPE Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Send HYPE',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (HYPE)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          labelText: 'Memo (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: pay.loading
                              ? null
                              : () async {
                                  final to =
                                      _addressController.text.trim();
                                  final amount =
                                      double.tryParse(
                                            _amountController
                                                .text.trim(),
                                          ) ??
                                          0;
                                  if (to.isEmpty || amount <= 0) {
                                    return;
                                  }
                                  final ok = await context
                                      .read<
                                          HyperspacePaymentService>()
                                      .sendPayment(
                                        to,
                                        (amount * 1e18).toInt(),
                                        memo: _memoController
                                            .text
                                            .trim(),
                                      );
                                  if (ok && mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Payment sent!')),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.send),
                          label: Text(pay.loading
                              ? 'Sending...'
                              : 'Send'),
                        ),
                      ),
                    ]),
              ),
            ),
            const SizedBox(height: 16),
            // Payment Channels
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Channels',
                              style: theme.textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => context
                                .read<HyperspacePaymentService>()
                                .fetchChannels(),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (pay.channels.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No payment channels.'),
                        )
                      else
                        ...pay.channels.map((c) => ListTile(
                              dense: true,
                              leading: Icon(
                                c.isOpen
                                    ? Icons.link
                                    : Icons.link_off,
                                color: c.isOpen
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              title: Text(
                                  '${c.peerId.substring(0, 12)}...'),
                              subtitle: Text(
                                  '${c.balance} HYPE / ${c.capacity} HYPE'),
                            )),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
