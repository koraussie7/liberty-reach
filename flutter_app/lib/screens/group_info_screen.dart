import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_chat_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final group = context.read<GroupChatService>().groupById(widget.groupId);
    _nameController = TextEditingController(text: group?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupService = context.watch<GroupChatService>();
    final group = groupService.groupById(widget.groupId);

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Info')),
        body: const Center(child: Text('Group not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFFEE500),
                  child: Text(
                    group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  )
                else
                  Text(group.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${group.members.length} members', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 8),
                Text('Invite: ${group.inviteCode ?? "N/A"}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isEditing)
                      TextButton(onPressed: () => _saveName(groupService), child: const Text('Save'))
                    else
                      TextButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteGroup(groupService),
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Members', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          ),
          ...group.members.map((m) => ListTile(
            leading: CircleAvatar(
              backgroundColor: m.isAdmin ? const Color(0xFFFEE500) : Colors.grey[300],
              child: Icon(Icons.person, color: m.isAdmin ? Colors.black87 : Colors.grey[600]),
            ),
            title: Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(m.peerId, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            trailing: m.isAdmin
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE500).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Admin', style: TextStyle(fontSize: 11)),
                  )
                : null,
          )),
        ],
      ),
    );
  }

  void _saveName(GroupChatService service) async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await service.renameGroup(widget.groupId, newName);
    }
    setState(() => _isEditing = false);
  }

  void _deleteGroup(GroupChatService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await service.deleteGroup(widget.groupId);
      if (mounted) Navigator.pop(context);
    }
  }
}
