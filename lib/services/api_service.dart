import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ⚠️  Remplacez par votre URL backend
const _baseUrl = 'http://127.0.0.1:5000/api'; // Change me

//const _baseUrl = 'https://api-annonchat-backend-annochat-ccpinr-64afca-185-181-8-139.traefik.me/api'; // Change me

class ApiService {
  ApiService._() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshTokens();
            if (refreshed) {
              final token = await _storage.read(key: 'accessToken');
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._();

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  final _storage = const FlutterSecureStorage();

  // ─── Tokens ────────────────────────────────────────────────────────────────

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'accessToken', value: access);
    await _storage.write(key: 'refreshToken', value: refresh);
  }

  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) return false;
      final res = await _dio
          .post('/auth/refresh', data: {'refreshToken': refreshToken});
      await saveTokens(
        res.data['accessToken'] as String,
        res.data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async => _storage.deleteAll();

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(
      String username, String password) async {
    final res = await _dio.post('/auth/register',
        data: {'username': username, 'password': password});

    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'username': username, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  // ─── Conversations ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getConversations() async {
    final res = await _dio.get('/conversations');
    return res.data['conversations'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> findOrCreateConversation(
      String linkOwnerId) async {
    final res = await _dio.post('/conversations/find-or-create',
        data: {'linkOwnerId': linkOwnerId});
    return res.data as Map<String, dynamic>;
  }

  Future<void> markRead(String conversationId) async {
    await _dio.post('/conversations/$conversationId/read');
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMessages(String conversationId,
      {String? cursor}) async {
    final res = await _dio.get(
      '/messages/$conversationId',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data as Map<String, dynamic>;
  }
}
