import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/conversation_provider.dart';
import '../../l10n/app_localizations.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n!.conversations),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(conversationsProvider.notifier).load(),
          ),
        ],
      ),
      body: _buildBody(context, ref, l10n, theme, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    ConversationsState state,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: theme.colorScheme.error.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.6))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    ref.read(conversationsProvider.notifier).load(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 80,
                  color: theme.colorScheme.onBackground.withOpacity(0.12)),
              const SizedBox(height: 20),
              Text(l10n.noConversations,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.4))),
              const SizedBox(height: 8),
              Text(l10n.noConversationsHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.3))),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationsProvider.notifier).load(),
      child: ListView.separated(
        itemCount: state.conversations.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 76,
          color: theme.colorScheme.onBackground.withOpacity(0.06),
        ),
        itemBuilder: (context, i) {
          final conv = state.conversations[i];
          return _ConversationTile(
            conv: conv,
            onTap: () {
              ref.read(conversationsProvider.notifier).clearUnread(conv.id);
              context.go(
                '/chat/${conv.id}?name=${Uri.encodeComponent(conv.displayName)}',
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = conv.unreadCount;
    final initial = conv.displayName[0].toUpperCase();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Text(
              initial,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          if (conv.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conv.displayName,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          if (conv.updatedAt != null)
            Text(
              timeago.format(conv.updatedAt!, locale: 'fr'),
              style: TextStyle(
                fontSize: 11,
                color: unread > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onBackground.withOpacity(0.38),
                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conv.lastContent ?? 'Aucun message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: unread > 0
                    ? theme.colorScheme.onBackground.withOpacity(0.8)
                    : theme.colorScheme.onBackground.withOpacity(0.42),
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            _UnreadBadge(count: unread),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
