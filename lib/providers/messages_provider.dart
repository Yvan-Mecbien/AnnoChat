import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class MessageModel {
  final String id;
  final String conversationId;
  final String? senderId;
  final String content;
  final bool isMine;
  final String? senderDisplay;
  final String status;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.content,
    required this.isMine,
    this.senderDisplay,
    required this.status,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['_id'] as String,
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String?,
        content: json['content'] as String? ?? '',
        isMine: json['isMine'] == true,
        senderDisplay: json['senderDisplay'] as String?,
        status: json['status'] as String? ?? 'sent',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  MessageModel copyWith({String? status}) => MessageModel(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        isMine: isMine,
        senderDisplay: senderDisplay,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

// ─── State ───────────────────────────────────────────────────────────────────

class MessagesState {
  final List<MessageModel> messages;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const MessagesState({
    this.messages = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) =>
      MessagesState(
        messages: messages ?? this.messages,
        nextCursor: nextCursor ?? this.nextCursor,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error ?? this.error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class MessagesNotifier extends StateNotifier<MessagesState> {
  final String conversationId;

  MessagesNotifier(this.conversationId)
      : super(const MessagesState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await ApiService.instance.getMessages(conversationId);
      final msgs = (data['messages'] as List)
          .cast<Map<String, dynamic>>()
          .map(MessageModel.fromJson)
          .toList();
      state = MessagesState(
        messages: msgs,
        nextCursor: data['nextCursor'] as String?,
        hasMore: data['nextCursor'] != null,
      );
    } catch (e) {
      state = MessagesState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final data = await ApiService.instance.getMessages(
        conversationId,
        cursor: state.nextCursor,
      );
      final older = (data['messages'] as List)
          .cast<Map<String, dynamic>>()
          .map(MessageModel.fromJson)
          .toList();
      state = state.copyWith(
        messages: [...older, ...state.messages],
        nextCursor: data['nextCursor'] as String?,
        hasMore: data['nextCursor'] != null,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void addMessage(MessageModel msg) {
    if (state.messages.any((m) => m.id == msg.id)) return;
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void updateStatus(String messageId, String newStatus) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        return m.id == messageId ? m.copyWith(status: newStatus) : m;
      }).toList(),
    );
  }
}

// ─── Provider (family – un par conversation) ─────────────────────────────────

final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    MessagesState, String>(
  (ref, conversationId) => MessagesNotifier(conversationId),
);
