import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../services/chat_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final Uuid _uuid = const Uuid();
  final ChatService _chatService;

  ChatBloc(this._chatService) : super(const ChatState()) {
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<LoadMessagesEvent>(_onLoadMessages);
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final message = Message(
      id: _uuid.v4(),
      content: event.content,
      senderId: event.senderId,
      senderName: event.senderName,
    );
    _chatService.send(event.content, event.groupId);
    emit(state.copyWith(
      messages: [...state.messages, message],
    ));
  }

  void _onReceiveMessage(ReceiveMessageEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: [...state.messages, event.message],
    ));
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _chatService.loadHistory();
      final loaded = _chatService.messageHistory.map((m) => Message(
        id: m.id,
        content: m.content,
        senderId: m.sender,
        senderName: m.isMe ? 'Me' : m.sender,
        timestamp: m.timestamp,
        isAI: m.isAI,
      )).toList();
      emit(state.copyWith(isLoading: false, messages: loaded));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
