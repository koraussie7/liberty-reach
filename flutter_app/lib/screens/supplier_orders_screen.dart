import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supplier_service.dart';

/// 공급업체(CS) 주문 관리 화면
/// /supplier/orders API에서 주문 목록 조회
/// 각 주문 클릭 → 상세 정보 + 상태 변경
class SupplierOrdersScreen extends StatefulWidget {
  const SupplierOrdersScreen({super.key});

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  String _statusFilter = '';
  String _serviceFilter = '';
  List<Map<String, dynamic>> _serviceTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final svc = context.read<SupplierService>();
      final results = await Future.wait([
        svc.fetchOrders(status: _statusFilter, serviceType: _serviceFilter),
        svc.fetchServiceTypes(),
      ]);
      _orders = results[0];
      _serviceTypes = results[1];
    } catch (e) {
      _error = '데이터 로딩 실패: $e';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    final svc = context.read<SupplierService>();
    final result = await svc.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
    );

    if (!mounted) return;

    if (result != null && result['status'] == 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 상태 변경 완료 → $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 상태 변경 실패: ${result?['message'] ?? svc.error ?? 'unknown'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('📋 주문 관리'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 필터 Row ──
          _buildFilters(),
          const SizedBox(height: 8),
          // ── 본문 ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final statuses = ['', 'pending', 'confirmed', 'preparing', 'completed', 'cancelled'];
    final statusLabels = {
      '': '전체',
      'pending': '대기중',
      'confirmed': '확정',
      'preparing': '준비중',
      'completed': '완료',
      'cancelled': '취소',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 필터
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: statuses.map((s) {
                final isActive = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(statusLabels[s]!),
                    selected: isActive,
                    onSelected: (_) {
                      setState(() => _statusFilter = s);
                      _loadData();
                    },
                    selectedColor: const Color(0xFF6B46C1),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // 서비스 타입 필터
          if (_serviceTypes.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('전체'),
                      selected: _serviceFilter == '',
                      onSelected: (_) {
                        setState(() => _serviceFilter = '');
                        _loadData();
                      },
                      selectedColor: const Color(0xFF6B46C1),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _serviceFilter == '' ? Colors.white : Colors.grey,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide.none,
                    ),
                  ),
                  ..._serviceTypes.map((st) {
                    final key = st['key'] as String? ?? st['type'] as String? ?? '';
                    final name = st['name'] as String? ?? key;
                    final isActive = _serviceFilter == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(name),
                        selected: isActive,
                        onSelected: (_) {
                          setState(() => _serviceFilter = key);
                          _loadData();
                        },
                        selectedColor: const Color(0xFF6B46C1),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        side: BorderSide.none,
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9F7AEA)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '주문이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _OrderCard(
            order: order,
            onTap: () => _showOrderDetail(context, order),
          );
        },
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? order['order_id']?.toString() ?? '';
    final status = order['status'] as String? ?? 'pending';

    final availableStatuses = <String>[];
    switch (status) {
      case 'pending':
        availableStatuses.addAll(['confirmed', 'cancelled']);
        break;
      case 'confirmed':
        availableStatuses.addAll(['preparing', 'cancelled']);
        break;
      case 'preparing':
        availableStatuses.addAll(['completed', 'cancelled']);
        break;
      case 'completed':
        break;
      case 'cancelled':
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF9F7AEA)),
                  const SizedBox(width: 12),
                  Text(
                    '주문 #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 20),
              // Details
              _detailRow('서비스 타입', order['service_type'] ?? '-'),
              _detailRow('고객명', order['customer_name'] ?? '-'),
              _detailRow('연락처', order['customer_phone'] ?? '-'),
              _detailRow('금액', '${order['total_amount'] ?? 0}원'),
              _detailRow('메모', order['note'] ?? '-'),
              if (order['created_at'] != null)
                _detailRow('생성일', order['created_at']),
              // Items
              if (order['items'] is Map && (order['items'] as Map).isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '주문 항목',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9F7AEA),
                  ),
                ),
                const SizedBox(height: 6),
                ...(order['items'] as Map).entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                )),
              ],
              const SizedBox(height: 20),
              // Status actions
              if (availableStatuses.isNotEmpty) ...[
                const Text(
                  '상태 변경',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9F7AEA),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: availableStatuses.map((s) {
                    final color = _statusColor(s);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateStatus(orderId, s);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.withValues(alpha: 0.2),
                            foregroundColor: color,
                            side: BorderSide(color: color.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _statusLabel(s),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'preparing':
        return Colors.orange;
      case 'confirmed':
        return Colors.blueAccent;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return '대기중';
      case 'confirmed':
        return '확정';
      case 'preparing':
        return '준비중';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return s;
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final orderId = order['id']?.toString() ?? order['order_id']?.toString() ?? 'N/A';
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final customerName = order['customer_name'] as String? ?? '고객';
    final amount = order['total_amount'] as num? ?? 0;

    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Order icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$shortId · $customerName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order['service_type'] ?? '-'} · ${_formatAmount(amount)}원',
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'preparing':
        return Colors.orange;
      case 'confirmed':
        return Colors.blueAccent;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return '대기중';
      case 'confirmed':
        return '확정';
      case 'preparing':
        return '준비중';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return s;
    }
  }

  String _formatAmount(dynamic n) {
    if (n is int) {
      return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    if (n is double) {
      return n.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return n.toString();
  }
}
