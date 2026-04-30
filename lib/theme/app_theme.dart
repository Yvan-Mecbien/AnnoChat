import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF6C63FF);
  static const _primaryDark = Color(0xFF9D97FF);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: _primary,
        background: const Color(0xFFF5F5F5),
        surface: Colors.white,
        onSurface: const Color(0xFF1A1A2E),
        bubbleMine: _primary,
        bubbleOther: const Color(0xFFE5E7EB),
        secondaryText: const Color(0xFF6B7280),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: _primaryDark,
        background: const Color(0xFF0F0F1A),
        surface: const Color(0xFF1A1A2E),
        onSurface: Colors.white,
        bubbleMine: _primaryDark,
        bubbleOther: const Color(0xFF2D2D44),
        secondaryText: const Color(0xFF9CA3AF),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color bubbleMine,
    required Color bubbleOther,
    required Color secondaryText,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: primary.withOpacity(0.7),
        onSecondary: Colors.white,
        error: const Color(0xFFE53E3E),
        onError: Colors.white,
        background: background,
        onBackground: onSurface,
        surface: surface,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: onSurface.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      extensions: [
        ChatThemeExtension(
          bubbleMine: bubbleMine,
          bubbleOther: bubbleOther,
          secondaryText: secondaryText,
        ),
      ],
    );
  }
}

class ChatThemeExtension extends ThemeExtension<ChatThemeExtension> {
  final Color bubbleMine;
  final Color bubbleOther;
  final Color secondaryText;

  const ChatThemeExtension({
    required this.bubbleMine,
    required this.bubbleOther,
    required this.secondaryText,
  });

  @override
  ChatThemeExtension copyWith({
    Color? bubbleMine,
    Color? bubbleOther,
    Color? secondaryText,
  }) =>
      ChatThemeExtension(
        bubbleMine: bubbleMine ?? this.bubbleMine,
        bubbleOther: bubbleOther ?? this.bubbleOther,
        secondaryText: secondaryText ?? this.secondaryText,
      );

  @override
  ChatThemeExtension lerp(ChatThemeExtension? other, double t) {
    if (other == null) return this;
    return ChatThemeExtension(
      bubbleMine: Color.lerp(bubbleMine, other.bubbleMine, t)!,
      bubbleOther: Color.lerp(bubbleOther, other.bubbleOther, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
    );
  }
}
