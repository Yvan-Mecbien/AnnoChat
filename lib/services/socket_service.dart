import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// ⚠️  Remplacez par votre URL backend
const _socketUrl = 'https://your-api-url.com';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  final _storage = const FlutterSecureStorage();

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) return;
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // ─── Emit ──────────────────────────────────────────────────────────────────

  void joinRoom(String conversationId) =>
      _socket?.emit('room:join', {'conversationId': conversationId});

  void sendMessage(String conversationId, String content,
      {Function(dynamic)? ack}) {
    _socket?.emitWithAck(
      'message:send',
      {'conversationId': conversationId, 'content': content},
      ack: ack,
    );
  }

  void startTyping(String conversationId) =>
      _socket?.emit('typing:start', {'conversationId': conversationId});

  void stopTyping(String conversationId) =>
      _socket?.emit('typing:stop', {'conversationId': conversationId});

  void markRead(String conversationId) =>
      _socket?.emit('message:read', {'conversationId': conversationId});

  // ─── Listen ────────────────────────────────────────────────────────────────

  void on(String event, Function(dynamic) handler) =>
      _socket?.on(event, handler);

  void off(String event) => _socket?.off(event);

  void onNewMessage(Function(dynamic) handler) =>
      _socket?.on('message:new', handler);

  void onTypingStart(Function(dynamic) handler) =>
      _socket?.on('typing:start', handler);

  void onTypingStop(Function(dynamic) handler) =>
      _socket?.on('typing:stop', handler);

  void onUserOnline(Function(dynamic) handler) =>
      _socket?.on('user:online', handler);

  void onUserOffline(Function(dynamic) handler) =>
      _socket?.on('user:offline', handler);
}
