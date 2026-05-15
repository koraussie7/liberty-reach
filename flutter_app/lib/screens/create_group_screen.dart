import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_chat_service.dart';
import '../services/p2p_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final List<GroupMemberEntry> _members = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addMember() {
    setState(() => _members.add(GroupMemberEntry(peerId: '', displayName: '')));
  }

  void _removeMember(int index) {
    setState(() => _members.removeAt(index));
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final members = _members
        .where((m) => m.peerId.isNotEmpty && m.displayName.isNotEmpty)
        .map((m) => GroupMember(peerId: m.peerId, displayName: m.displayName, isAdmin: false))
        .toList();

    final p2p = context.read<P2PService>();
    if (p2p.localPeerId != null) {
      members.insert(0, GroupMember(peerId: p2p.localPeerId!, displayName: 'Me', isAdmin: true));
    }

    final groupService = context.read<GroupChatService>();
    await groupService.createGroup(name, members);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(),
              hintText: 'Enter group name...',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          ...List.generate(_members.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Peer ID',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        hintText: 'peer_abc123',
                      ),
                      onChanged: (v) => _members[i].peerId = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Alice',
                      ),
                      onChanged: (v) => _members[i].displayName = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeMember(i),
                  ),
                ],
              ),
            );
          }),
          if (_members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Add members or create with just yourself',
                    style: TextStyle(color: Colors.grey[500])),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.group_add),
            label: const Text('Create Group'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupMemberEntry {
  String peerId;
  String displayName;

  GroupMemberEntry({required this.peerId, required this.displayName});
}
