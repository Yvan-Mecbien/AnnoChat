import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class ConversationModel {
  final String id;
  final String displayName;
  final bool isOnline;
  final int unreadCount;
  final String? lastContent;
  final DateTime? updatedAt;

  const ConversationModel({
    required this.id,
    required this.displayName,
    required this.isOnline,
    required this.unreadCount,
    this.lastContent,
    this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'] as Map<String, dynamic>?;
    return ConversationModel(
      id: json['_id'] as String,
      displayName: json['displayName'] as String? ?? 'Anonyme',
      isOnline: json['isOnline'] == true,
      unreadCount: (json['unreadCount'] as int?) ?? 0,
      lastContent: lastMsg?['content'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  ConversationModel copyWith({
    int? unreadCount,
    String? lastContent,
    DateTime? updatedAt,
  }) =>
      ConversationModel(
        id: id,
        displayName: displayName,
        isOnline: isOnline,
        unreadCount: unreadCount ?? this.unreadCount,
        lastContent: lastContent ?? this.lastContent,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─── State ───────────────────────────────────────────────────────────────────

class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  ConversationsNotifier() : super(const ConversationsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = const ConversationsState(isLoading: true);
    try {
      final raw = await ApiService.instance.getConversations();
      final convs = raw
          .cast<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .toList();
      state = ConversationsState(conversations: convs);
    } catch (e) {
      state = ConversationsState(error: e.toString());
    }
  }

  void incrementUnread(String conversationId) {
    state = ConversationsState(
      conversations: state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(unreadCount: c.unreadCount + 1);
        }
        return c;
      }).toList(),
    );
  }

  void clearUnread(String conversationId) {
    state = ConversationsState(
      conversations: state.conversations
          .map((c) => c.id == conversationId ? c.copyWith(unreadCount: 0) : c)
          .toList(),
    );
  }

  void updateLastMessage(String conversationId, String content) {
    state = ConversationsState(
      conversations: state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(lastContent: content, updatedAt: DateTime.now());
        }
        return c;
      }).toList(),
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>(
  (ref) => ConversationsNotifier(),
);
