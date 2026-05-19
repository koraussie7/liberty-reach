import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentChannel {
  final String peerId;
  final double balance;
  final double capacity;
  final bool isOpen;

  PaymentChannel({
    required this.peerId,
    this.balance = 0.0,
    this.capacity = 0.0,
    this.isOpen = false,
  });

  factory PaymentChannel.fromJson(Map<String, dynamic> json) {
    return PaymentChannel(
      peerId: json['peer_id'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] as bool? ?? false,
    );
  }
}

class HyperspacePaymentService extends ChangeNotifier {
  final String _baseUrl;
  final http.Client _client;

  HyperspacePaymentService({
    String baseUrl = 'https://muhantube.com/ai/hyperspace/payment',
  })  : _baseUrl = baseUrl,
        _client = http.Client();

  int _hypeBalance = 0;
  String _hypeAddress = '0x...';
  List<PaymentChannel> _channels = [];
  bool _loading = false;
  String _error = '';

  int get hypeBalance => _hypeBalance;
  String get hypeAddress => _hypeAddress;
  List<PaymentChannel> get channels => List.unmodifiable(_channels);
  bool get loading => _loading;
  String get error => _error;

  Future<void> fetchBalance(String address) async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/balance?address=$address'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _hypeBalance = (data['balance'] as num?)?.toInt() ?? 0;
        _hypeAddress = data['address'] as String? ?? address;
        _error = '';
      } else {
        _error = 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('HyperspacePaymentService fetchBalance error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPayment(String to, int amount, {String? memo}) async {
    _loading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'to': to,
        'amount': amount,
      };
      if (memo != null && memo.isNotEmpty) {
        body['memo'] = memo;
      }
      final resp = await _client
          .post(
            Uri.parse('$_baseUrl/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          // Refresh balance
          await fetchBalance(_hypeAddress);
          _loading = false;
          notifyListeners();
          return true;
        }
      }
      _error = 'HTTP ${resp.statusCode}';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchChannels() async {
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/channels'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List? ?? [];
        _channels = data
            .map((e) => PaymentChannel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchChannels error: $e');
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
