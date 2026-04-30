import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n!.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        children: [
          // ── User card ──────────────────────────────────────────────────────
          if (user != null) _UserCard(username: user.username),

          // ── Apparence ─────────────────────────────────────────────────────
          _SectionHeader(title: l10n.appearance),
          _SwitchTile(
            icon: Icons.dark_mode_outlined,
            title: l10n.darkMode,
            value: themeMode == ThemeMode.dark,
            onChanged: (val) => ref
                .read(themeModeProvider.notifier)
                .setMode(val ? ThemeMode.dark : ThemeMode.light),
          ),

          // ── Langue ────────────────────────────────────────────────────────
          _SectionHeader(title: l10n.language),
          _NavTile(
            icon: Icons.language_outlined,
            title: l10n.language,
            subtitle: 'Français / English',
            onTap: () => _showLanguageDialog(context),
          ),

          // ── Compte ────────────────────────────────────────────────────────
          _SectionHeader(title: l10n.account),
          _NavTile(
            icon: Icons.link_outlined,
            title: l10n.myChatLink,
            subtitle: user?.chatLink ?? '',
            onTap: () => context.go('/home'),
          ),

          // ── Session ───────────────────────────────────────────────────────
          _SectionHeader(title: l10n.session),
          _NavTile(
            icon: Icons.logout_rounded,
            title: l10n.logout,
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
            onTap: () => _confirmLogout(context, ref, l10n),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              l10n.version,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.28)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Langue / Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Français'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final String username;
  const _UserCard({required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.onBackground.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Text(
              username[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(l10n!.activeAccount,
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onBackground.withOpacity(0.45))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading:
          Icon(icon, color: theme.colorScheme.onBackground.withOpacity(0.65)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: iconColor ?? theme.colorScheme.onBackground.withOpacity(0.65)),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              color: textColor ?? theme.colorScheme.onBackground)),
      subtitle: subtitle != null && subtitle!.isNotEmpty
          ? Text(
              subtitle!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.42)),
            )
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          size: 20, color: theme.colorScheme.onBackground.withOpacity(0.3)),
      onTap: onTap,
    );
  }
}
