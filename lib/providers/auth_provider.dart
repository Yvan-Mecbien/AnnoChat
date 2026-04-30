import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String username;
  final String chatLink;

  const UserModel({
    required this.id,
    required this.username,
    required this.chatLink,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] as String,
        username: json['username'] as String,
        chatLink: json['chatLink'] as String? ?? '',
      );
}

// ─── State ───────────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final data = await ApiService.instance.getMe();
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await SocketService.instance.connect();
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> register(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print(username);
      final data = await ApiService.instance.register(username, password);
      await ApiService.instance.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      await SocketService.instance.connect();
      state = AuthState(
          user: UserModel.fromJson(data['user'] as Map<String, dynamic>));
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.instance.login(username, password);
      await ApiService.instance.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      await SocketService.instance.connect();
      state = AuthState(
          user: UserModel.fromJson(data['user'] as Map<String, dynamic>));
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> logout() async {
    SocketService.instance.disconnect();
    await ApiService.instance.logout();
    state = const AuthState();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
