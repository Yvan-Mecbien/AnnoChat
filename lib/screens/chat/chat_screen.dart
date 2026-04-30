import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/conversation_provider.dart';
import '../../providers/messages_provider.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String displayName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.displayName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _otherTyping = false;
  bool _isTyping = false;
  Timer? _typingTimer;
  Timer? _typingVisibleTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _setupSocket();
    SocketService.instance.markRead(widget.conversationId);
    ref.read(conversationsProvider.notifier).clearUnread(widget.conversationId);

    // Scroll to bottom after first frame
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(animated: false));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    _typingVisibleTimer?.cancel();
    SocketService.instance.off('message:new');
    SocketService.instance.off('typing:start');
    SocketService.instance.off('typing:stop');
    super.dispose();
  }

  void _setupSocket() {
    SocketService.instance.joinRoom(widget.conversationId);

    SocketService.instance.onNewMessage((data) {
      if (!mounted) return;
      final map = Map<String, dynamic>.from(data as Map);
      if (map['conversationId'] == widget.conversationId) {
        final msg = MessageModel.fromJson(map);
        ref
            .read(messagesProvider(widget.conversationId).notifier)
            .addMessage(msg);

        // Update conversation list
        ref
            .read(conversationsProvider.notifier)
            .updateLastMessage(widget.conversationId, msg.content);

        SocketService.instance.markRead(widget.conversationId);
        _scrollToBottom();
      }
    });

    SocketService.instance.onTypingStart((_) {
      if (!mounted) return;
      setState(() => _otherTyping = true);
      _typingVisibleTimer?.cancel();
      _typingVisibleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _otherTyping = false);
      });
    });

    SocketService.instance.onTypingStop((_) {
      if (!mounted) return;
      _typingVisibleTimer?.cancel();
      setState(() => _otherTyping = false);
    });
  }

  void _onScroll() {
    final state = ref.read(messagesProvider(widget.conversationId));
    if (_scrollCtrl.position.pixels <= 100 && state.hasMore) {
      ref.read(messagesProvider(widget.conversationId).notifier).loadMore();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  void _onTextChanged(String value) {
    if (!_isTyping && value.isNotEmpty) {
      _isTyping = true;
      SocketService.instance.startTyping(widget.conversationId);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        SocketService.instance.stopTyping(widget.conversationId);
      }
    });
    if (value.isEmpty && _isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      SocketService.instance.stopTyping(widget.conversationId);
    }
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      SocketService.instance.stopTyping(widget.conversationId);
    }

    SocketService.instance.sendMessage(widget.conversationId, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final msgState = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/conversations'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _otherTyping
                  ? Text(
                      l10n!.typing,
                      key: const ValueKey('typing'),
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w400),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(context, l10n!, theme, msgState)),
          _buildInputBar(context, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    MessagesState state,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64,
                color: theme.colorScheme.onBackground.withOpacity(0.15)),
            const SizedBox(height: 12),
            Text(l10n.noMessages,
                style: TextStyle(
                    color: theme.colorScheme.onBackground.withOpacity(0.35))),
            const SizedBox(height: 4),
            Text(l10n.noMessagesHint,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onBackground.withOpacity(0.25))),
          ],
        ),
      );
    }

    final chatTheme = theme.extension<ChatThemeExtension>()!;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading more indicator at top
        if (state.isLoadingMore && index == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final msgIndex = state.isLoadingMore ? index - 1 : index;
        final msg = state.messages[msgIndex];
        final prev = msgIndex > 0 ? state.messages[msgIndex - 1] : null;
        final showDateSeparator =
            prev == null || !_sameDay(prev.createdAt, msg.createdAt);

        return Column(
          children: [
            if (showDateSeparator) _DateSeparator(date: msg.createdAt),
            _MessageBubble(msg: msg, chatTheme: chatTheme),
          ],
        );
      },
    );
  }

  Widget _buildInputBar(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.onBackground.withOpacity(0.08))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              onChanged: _onTextChanged,
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.messagePlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onTap: _sendMessage),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final ChatThemeExtension chatTheme;

  const _MessageBubble({required this.msg, required this.chatTheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = msg.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender label (only for messages from others)
            if (!isMine && msg.senderDisplay != null)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 3),
                child: Text(
                  msg.senderDisplay!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            // Bubble
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? chatTheme.bubbleMine : chatTheme.bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isMine ? Colors.white : theme.colorScheme.onBackground,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

            // Time + status
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeago.format(msg.createdAt, locale: 'fr'),
                    style:
                        TextStyle(fontSize: 11, color: chatTheme.secondaryText),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _StatusIcon(status: msg.status),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case 'read':
        return Icon(Icons.done_all_rounded,
            size: 14, color: theme.colorScheme.primary);
      case 'delivered':
        return Icon(Icons.done_all_rounded,
            size: 14, color: theme.colorScheme.onBackground.withOpacity(0.4));
      default:
        return Icon(Icons.done_rounded,
            size: 14, color: theme.colorScheme.onBackground.withOpacity(0.3));
    }
  }
}

// ─── Date Separator ───────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return "Aujourd'hui";
    if (d == today.subtract(const Duration(days: 1))) return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: theme.colorScheme.onBackground.withOpacity(0.1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.4)),
            ),
          ),
          Expanded(
              child: Divider(
                  color: theme.colorScheme.onBackground.withOpacity(0.1))),
        ],
      ),
    );
  }
}

// ─── Send Button ──────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
