import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String productId;
  final String description;
  final String? userId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.productId,
    required this.description,
    this.userId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentMethod> _methods = [];
  String _selectedMethod = "stripe";
  int _dadaBalance = 0;
  bool _isLoading = true;
  bool _isPaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _isLoading = true);
    final methods = await _paymentService.getPaymentMethods(
      widget.userId ?? "anonymous",
    );
    if (mounted) {
      setState(() {
        _methods = methods;
        final dadaMethod = methods.where((m) => m.id == "dada_point").firstOrNull;
        _dadaBalance = dadaMethod?.balance ?? 0;
        _selectedMethod = dadaMethod?.available == true ? "dada_point" : "stripe";
        _isLoading = false;
      });
    }
  }

  Future<void> _pay() async {
    setState(() {
      _isPaying = true;
      _error = null;
    });

    final result = await _paymentService.processPayment(
      amount: widget.amount,
      productId: widget.productId,
      method: _selectedMethod,
      userId: widget.userId ?? "anonymous",
      description: widget.description,
    );

    setState(() => _isPaying = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message.isNotEmpty
              ? result.message
              : "✅ 결제가 완료되었습니다!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPayWithDada = _dadaBalance >= widget.amount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("결제하기"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F0F1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "결제 금액",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.amount >= 1000
                              ? "₩${(widget.amount / 100).toStringAsFixed(0)}"
                              : "${widget.amount} Point",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Payment method selection
                  const Text(
                    "결제 수단 선택",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // DADA Point card
                  _buildMethodCard(
                    id: "dada_point",
                    icon: Icons.token,
                    title: "DADA Point",
                    subtitle: "보유: ${_dadaBalance.toInt().toStringAsFixed(0)} P",
                    trailing: canPayWithDada
                        ? const Text(
                            "사용 가능",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            "${widget.amount - _dadaBalance}P 부족",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    enabled: canPayWithDada,
                  ),

                  const SizedBox(height: 8),

                  // Stripe card
                  _buildMethodCard(
                    id: "stripe",
                    icon: Icons.credit_card,
                    title: "신용카드 (Stripe)",
                    subtitle: "안전한 카드 결제 · Visa, Mastercard, etc.",
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.white38),
                    enabled: true,
                  ),

                  const SizedBox(height: 8),

                  // Crypto card
                  _buildMethodCard(
                    id: "crypto",
                    icon: Icons.currency_bitcoin,
                    title: "USDC (Stablecoin)",
                    subtitle: "Phantom/MetaMask 등으로 USDC 결제",
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.white38),
                    enabled: true,
                  ),

                  const SizedBox(height: 32),

                  // Error
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isPaying ? null : _pay,
                      icon: _isPaying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _selectedMethod == "dada_point"
                                  ? Icons.token
                                  : _selectedMethod == "crypto"
                                      ? Icons.currency_bitcoin
                                      : Icons.credit_card,
                            ),
                      label: Text(
                        _isPaying
                            ? "처리 중..."
                            : _selectedMethod == "dada_point"
                                ? "${widget.amount} DADA Point 결제"
                                : _selectedMethod == "crypto"
                                    ? "USDC 결제"
                                    : "₩${(widget.amount / 100).toStringAsFixed(0)} 카드 결제",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMethodCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool enabled,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedMethod = id) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B46C1).withValues(alpha: 0.2)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9F7AEA)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6B46C1).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? const Color(0xFF9F7AEA)
                      : Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF9F7AEA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              )
            else
              trailing,
          ],
        ),
      ),
    );
  }
}
