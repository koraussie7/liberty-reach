import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PodMember {
  final String peerId;
  final String? name;
  final String? gpu;
  final int vram;
  final bool isOnline;

  PodMember({
    required this.peerId,
    this.name,
    this.gpu,
    this.vram = 0,
    this.isOnline = false,
  });

  factory PodMember.fromJson(Map<String, dynamic> json) {
    return PodMember(
      peerId: json['peer_id'] as String? ?? '',
      name: json['name'] as String?,
      gpu: json['gpu'] as String?,
      vram: (json['vram'] as num?)?.toInt() ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }
}

class HyperspacePodService extends ChangeNotifier {
  final String _baseUrl;
  final http.Client _client;

  HyperspacePodService({
    String baseUrl = 'https://muhantube.com/ai/hyperspace/pod',
  })  : _baseUrl = baseUrl,
        _client = http.Client();

  List<PodMember> _members = [];
  String? _currentPodId;
  String? _inviteLink;
  bool _loading = false;
  String _error = '';

  List<PodMember> get members => List.unmodifiable(_members);
  String? get currentPodId => _currentPodId;
  String? get inviteLink => _inviteLink;
  bool get loading => _loading;
  String get error => _error;

  Future<void> fetchMembers() async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/members'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _currentPodId = data['pod_id'] as String?;
        final rawMembers = data['members'] as List? ?? [];
        _members = rawMembers
            .map((e) => PodMember.fromJson(e as Map<String, dynamic>))
            .toList();
        _error = '';
      } else {
        _error = 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('HyperspacePodService fetchMembers error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createPod(String name) async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await _client
          .post(
            Uri.parse('$_baseUrl/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _currentPodId = data['pod_id'] as String?;
        _error = '';
        _loading = false;
        notifyListeners();
        await fetchMembers();
        return true;
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

  Future<String?> getInviteLink() async {
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/invite'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _inviteLink = data['invite_link'] as String?;
        notifyListeners();
        return _inviteLink;
      }
    } catch (e) {
      debugPrint('getInviteLink error: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
