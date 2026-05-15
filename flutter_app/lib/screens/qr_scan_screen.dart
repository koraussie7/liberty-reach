import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/wallet_service.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController? controller;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('QR Scan', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (_processing) return;
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      _processScan(barcode!.rawValue!);
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purpleAccent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Scan Minima QR to send DADA', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => controller?.start(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processScan(String code) async {
    _processing = true;
    controller?.stop();

    if (code.startsWith('minima:')) {
      await _processMinimaPayment(code);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not a Minima QR'), backgroundColor: Colors.red));
        Navigator.pop(context, code);
      }
    }
  }

  Future<void> _processMinimaPayment(String qrData) async {
    try {
      final uri = Uri.parse('https://${qrData.replaceFirst('minima:', '')}');
      final toAddress = uri.host;
      final amount = double.tryParse(uri.queryParameters['amount'] ?? '') ?? 0;
      final memo = uri.queryParameters['memo'] ?? 'DADA Transfer';

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Send DADA', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To: ${toAddress.length > 20 ? '${toAddress.substring(0, 10)}...${toAddress.substring(toAddress.length - 6)}' : toAddress}',
                   style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Text('Amount: $amount DADA', style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Memo: $memo', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              child: const Text('Send'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        final wallet = WalletService();
        final success = await wallet.sendDada(toAddress: toAddress, amount: amount, memo: memo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success ? 'Sent $amount DADA!' : 'Transfer failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
