import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  /// Login dengan username & password
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiClient.dio.post(
      '/login',
      data: {
        'username': username.trim(),
        'password': password,
      },
    );

    final responseData = response.data['data'];
    final String token = responseData['token'];
    final Map<String, dynamic> user = responseData['user'];

    await _saveUserSession(token: token, user: user);
    return user;
  }

  /// Mengambil data user terbaru dari endpoint GET /api/me
  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.dio.get('/me');
    final Map<String, dynamic> user = response.data['data'];

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    await _saveUserSession(token: token, user: user);

    return user;
  }

  /// Logout dari server & hapus sesi lokal
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/logout');
    } catch (_) {
      // Tetap lanjutkan hapus data lokal meskipun koneksi gagal
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  /// Menyimpan data penting user ke SharedPreferences
  Future<void> _saveUserSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', user['id']);
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('role', user['role'] ?? 'santri');
    await prefs.setBool('is_asisten_guru', user['is_asisten_guru'] == true);
    await prefs.setString('status_keaktifan', user['status_keaktifan'] ?? 'aktif');
    await prefs.setString('user_json', jsonEncode(user));
  }

  /// Mengambil data user yang tersimpan di lokal (Offline/Startup Check)
  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_json');

    if (token == null || token.isEmpty || userJson == null) {
      return null;
    }
    return jsonDecode(userJson) as Map<String, dynamic>;
  }
}