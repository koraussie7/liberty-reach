import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Supplier dashboard API service.
/// Connects to /supplier/stats, /supplier/orders, /supplier/order, etc.
class SupplierService extends ChangeNotifier {
  final http.Client _client = http.Client();
  final String _baseUrl = AppConstants.apiBaseUrl;

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _serviceTypes = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ──

  Map<String, dynamic>? get stats => _stats;
  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get serviceTypes => _serviceTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Stats ──

  Future<Map<String, dynamic>?> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/supplier/stats'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _stats = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        _error = 'Stats API error: ${res.statusCode}';
      }
    } catch (e) {
      _error = 'Stats fetch failed: $e';
      debugPrint('SupplierService.fetchStats error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _stats;
  }

  // ── Orders ──

  Future<List<Map<String, dynamic>>> fetchOrders({
    String status = '',
    String serviceType = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (status.isNotEmpty) params['status'] = status;
      if (serviceType.isNotEmpty) params['service_type'] = serviceType;
      final uri =
          Uri.parse('$_baseUrl/supplier/orders').replace(queryParameters: params);
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _orders = list.cast<Map<String, dynamic>>();
      } else {
        _error = 'Orders API error: ${res.statusCode}';
      }
    } catch (e) {
      _error = 'Orders fetch failed: $e';
      debugPrint('SupplierService.fetchOrders error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _orders;
  }

  // ── Create Order ──

  Future<Map<String, dynamic>?> createOrder({
    required String serviceType,
    String customerName = '',
    String customerPhone = '',
    Map<String, dynamic> items = const {},
    double totalAmount = 0,
    String note = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'service_type': serviceType,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': items,
        'total_amount': totalAmount,
        'note': note,
      };
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/supplier/order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body) as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        _error = 'Create order API error: ${res.statusCode}';
      }
    } catch (e) {
      _error = 'Create order failed: $e';
      debugPrint('SupplierService.createOrder error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ── Update Order Status ──

  Future<Map<String, dynamic>?> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    _error = null;

    try {
      final body = {'order_id': orderId, 'status': status};
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/supplier/order/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        _error = 'Status update API error: ${res.statusCode}';
      }
    } catch (e) {
      _error = 'Status update failed: $e';
      debugPrint('SupplierService.updateOrderStatus error: $e');
    }

    notifyListeners();
    return null;
  }

  // ── Service Types ──

  Future<List<Map<String, dynamic>>> fetchServiceTypes() async {
    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/supplier/service-types'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _serviceTypes = (data['services'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('SupplierService.fetchServiceTypes error: $e');
    }
    return _serviceTypes;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
