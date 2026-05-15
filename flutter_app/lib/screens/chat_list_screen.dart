import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<ChatRoom> _rooms = [
    ChatRoom(
      name: 'AI Assistant',
      lastMsg: 'Ask with @gemma',
      time: 'now',
      unread: 0,
      isAI: true,
      peerId: 'ai-assistant',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupChatService>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupChatService>().groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liberty Reach'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Create group',
            onPressed: () => Navigator.pushNamed(context, '/group/create'),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _openChat(context, ChatRoom(
              name: 'AI Assistant',
              lastMsg: '',
              time: '',
              unread: 0,
              isAI: true,
              peerId: 'ai-assistant',
            )),
          ),
        ],
      ),
      body: _rooms.isEmpty && groups.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                if (groups.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('GROUPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  ),
                  ...groups.map((group) => _ChatRoomTile(
                    room: ChatRoom(
                      name: group.name,
                      lastMsg: '${group.members.length} members',
                      time: '',
                      unread: 0,
                      isAI: false,
                      peerId: group.id,
                      isGroup: true,
                    ),
                    onTap: () => _openGroupChat(context, group.id, group.name),
                  )),
                  const Divider(indent: 80),
                ],
                ..._rooms.map((room) => _ChatRoomTile(
                  room: room,
                  onTap: () => _openChat(context, room),
                )),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No conversations', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/group/create'),
            child: const Text('Create a group'),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerId: room.peerId,
          peerName: room.name,
          isAI: room.isAI,
        ),
      ),
    );
  }

  void _openGroupChat(BuildContext context, String groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerId: groupId,
          peerName: groupName,
          isGroup: true,
          roomId: groupId,
        ),
      ),
    );
  }
}

class ChatRoom {
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  final bool isAI;
  final String peerId;
  final bool isGroup;

  ChatRoom({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.isAI,
    required this.peerId,
    this.isGroup = false,
  });
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _ChatRoomTile({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: room.isGroup
            ? const Color(0xFF7B1FA2)
            : room.isAI
                ? const Color(0xFFFEE500)
                : Colors.grey[300],
        child: Icon(
          room.isGroup ? Icons.group : room.isAI ? Icons.auto_awesome : Icons.person,
          color: Colors.black54,
          size: 24,
        ),
      ),
      title: Text(
        room.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          room.lastMsg,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(room.time, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          if (room.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE500),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.unread}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
