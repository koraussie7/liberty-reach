class ChatMessage {
  final String id;
  final String sender;
  final String content;
  final bool isMe;
  final bool isAI;
  final bool isLoading;
  final bool isRead;
  final DateTime timestamp;
  final List<String> imagePaths;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.isMe,
    this.isAI = false,
    this.isLoading = false,
    this.isRead = false,
    DateTime? timestamp,
    this.imagePaths = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasImages => imagePaths.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? content,
    bool? isMe,
    bool? isAI,
    bool? isLoading,
    bool? isRead,
    DateTime? timestamp,
    List<String>? imagePaths,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      isMe: isMe ?? this.isMe,
      isAI: isAI ?? this.isAI,
      isLoading: isLoading ?? this.isLoading,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'content': content,
    'isMe': isMe,
    'isAI': isAI,
    'isRead': isRead,
    'timestamp': timestamp.toIso8601String(),
    'imagePaths': imagePaths,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    sender: json['sender'] as String,
    content: json['content'] as String,
    isMe: json['isMe'] as bool,
    isAI: json['isAI'] as bool,
    isRead: json['isRead'] as bool? ?? false,
    timestamp: DateTime.parse(json['timestamp'] as String),
    imagePaths: (json['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}
