import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Supported payment method descriptor
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final int balance;
  final bool available;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    this.balance = 0,
    this.available = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      balance: json['balance'] as int? ?? 0,
      available: json['available'] as bool? ?? true,
    );
  }
}

class ChargeResult {
  final bool success;
  final String? checkoutUrl;
  final String? sessionId;
  final String? chargeId;
  final String error;

  ChargeResult({
    required this.success,
    this.checkoutUrl,
    this.sessionId,
    this.chargeId,
    this.error = '',
  });
}

class PaymentResult {
  final bool success;
  final String? checkoutUrl;
  final String? transactionId;
  final String message;
  final String paymentMethod;

  PaymentResult({
    required this.success,
    this.checkoutUrl,
    this.transactionId,
    this.message = '',
    this.paymentMethod = '',
  });
}

/// Unified payment service — DADA Point charge + product payment
class PaymentService {
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  String _baseUrl = 'https://privseai.com';
  final http.Client _client = http.Client();

  String get baseUrl => _baseUrl;
  set baseUrl(String url) => _baseUrl = url;

  // ═══════════════════════════════════════════════════════════
  //  Part 1: DADA Point Charging (Stripe → Point)
  // ═══════════════════════════════════════════════════════════

  /// Stripe 결제 세션 생성 → DADA Point 충전
  Future<ChargeResult> chargeDadaPoint({
    required int amount,
    String? userId,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/point/charge'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'payment_method': 'stripe',
              if (userId != null) 'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChargeResult(
          success: true,
          checkoutUrl: data['checkout_url'] as String?,
          sessionId: data['session_id'] as String?,
          chargeId: data['charge_id'] as String?,
        );
      }
      return ChargeResult(
        success: false,
        error: 'HTTP ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      debugPrint('[Payment] chargeDadaPoint error: $e');
      return ChargeResult(success: false, error: e.toString());
    }
  }

  /// 충전 요청 상태 조회
  Future<Map<String, dynamic>?> getChargeStatus(String chargeId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/point/charge/$chargeId'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['charge'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[Payment] getChargeStatus error: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  Part 2: Product Payment (DADA Point or Stripe)
  // ═══════════════════════════════════════════════════════════

  /// Process a product payment (DADA Point debit or Stripe checkout)
  Future<PaymentResult> processPayment({
    required int amount,
    required String productId,
    required String method,
    required String userId,
    String? description,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/payment/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'product_id': productId,
              'payment_method': method,
              'user_id': userId,
              if (description != null) 'description': description,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if ((method == 'stripe' || method == 'crypto') && data['checkout_url'] != null) {
          final uri = Uri.parse(data['checkout_url']);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            return PaymentResult(
              success: false,
              message: method == 'crypto'
                  ? 'USDC 결제 페이지를 열 수 없습니다.'
                  : 'Stripe 결제 페이지를 열 수 없습니다.',
              paymentMethod: method,
            );
          }
        }

        return PaymentResult(
          success: data['status'] == 'success',
          checkoutUrl: data['checkout_url'] as String?,
          transactionId: data['transaction_id'] as String?,
          message: data['message'] as String? ?? '',
          paymentMethod: method,
        );
      }

      return PaymentResult(
        success: false,
        message: 'HTTP ${response.statusCode}: ${response.body}',
        paymentMethod: method,
      );
    } catch (e) {
      debugPrint('[Payment] processPayment error: $e');
      return PaymentResult(
        success: false,
        message: e.toString(),
        paymentMethod: method,
      );
    }
  }

  /// Get available payment methods + DADA Point balance
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/payment/methods?user_id=$userId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final methods = (data['methods'] as List?)
            ?.map((m) => PaymentMethod.fromJson(m as Map<String, dynamic>))
            .toList();
        return methods ?? [];
      }
    } catch (e) {
      debugPrint('[Payment] getPaymentMethods error: $e');
    }
    return [];
  }

  /// Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(
              '$_baseUrl/payment/history?user_id=$userId&limit=$limit'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      }
    } catch (e) {
      debugPrint('[Payment] getPaymentHistory error: $e');
    }
    return [];
  }

  void dispose() {
    _client.close();
  }
}
