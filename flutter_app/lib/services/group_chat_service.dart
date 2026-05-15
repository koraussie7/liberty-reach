import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GroupMember {
  final String peerId;
  final String displayName;
  final bool isAdmin;

  GroupMember({
    required this.peerId,
    required this.displayName,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() => {
    'peer_id': peerId,
    'display_name': displayName,
    'is_admin': isAdmin,
  };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    peerId: json['peer_id'] as String,
    displayName: json['display_name'] as String,
    isAdmin: json['is_admin'] as bool? ?? false,
  );
}

class ChatGroup {
  final String id;
  String name;
  final List<GroupMember> members;
  final DateTime createdAt;
  String? inviteCode;
  String? avatarUrl;

  ChatGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    this.inviteCode,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'invite_code': inviteCode,
    'avatar_url': avatarUrl,
  };

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    members: (json['members'] as List).map((e) => GroupMember.fromJson(e)).toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
    inviteCode: json['invite_code'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}

class GroupChatService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  List<ChatGroup> _groups = [];
  final Map<String, StreamController<String>> _roomControllers = {};

  List<ChatGroup> get groups => List.unmodifiable(_groups);

  Stream<String> messageStream(String roomId) {
    _roomControllers.putIfAbsent(roomId, () => StreamController<String>.broadcast());
    return _roomControllers[roomId]!.stream;
  }

  Future<void> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_groups');
    if (raw == null) return;
    try {
      _groups = (jsonDecode(raw) as List).map((e) => ChatGroup.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[GroupChat] load error: $e');
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_groups', jsonEncode(_groups.map((g) => g.toJson()).toList()));
  }

  Future<ChatGroup> createGroup(String name, List<GroupMember> members) async {
    final group = ChatGroup(
      id: _uuid.v4(),
      name: name,
      members: members,
      createdAt: DateTime.now(),
      inviteCode: _uuid.v4().substring(0, 8),
    );
    _groups.add(group);
    await _persist();
    notifyListeners();
    return group;
  }

  Future<void> addMember(String groupId, GroupMember member) async {
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    if (_groups[idx].members.any((m) => m.peerId == member.peerId)) return;
    _groups[idx].members.add(member);
    await _persist();
    notifyListeners();
  }

  Future<void> removeMember(String groupId, String peerId) async {
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    _groups[idx].members.removeWhere((m) => m.peerId == peerId);
    if (_groups[idx].members.isEmpty) {
      _groups.removeAt(idx);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> renameGroup(String groupId, String newName) async {
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    _groups[idx].name = newName;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    await _persist();
    notifyListeners();
  }

  ChatGroup? groupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  ChatGroup? groupByInviteCode(String code) {
    try {
      return _groups.firstWhere((g) => g.inviteCode == code);
    } catch (_) {
      return null;
    }
  }

  void routeRoomMessage(String roomId, String messageJson) {
    _roomControllers.putIfAbsent(roomId, () => StreamController<String>.broadcast());
    _roomControllers[roomId]!.add(messageJson);
  }

  @override
  void dispose() {
    for (final c in _roomControllers.values) {
      c.close();
    }
    super.dispose();
  }
}
