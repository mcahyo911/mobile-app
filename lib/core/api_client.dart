import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Ganti IP ini sesuai perangkat pengujian Anda:
  // - Emulator Android Studio : 'http://10.0.2.2:8000/api'
  // - HP Fisik (Wi-Fi/LAN sama): 'http://127.0.0.1:8000/api'
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String storageBaseUrl = 'http://127.0.0.1:8000/api/file/';

  // static const String baseUrl = 'https://api.ppmalajwah.my.id/api';
  // static const String storageBaseUrl = 'https://api.ppmalajwah.my.id/api/file/';

  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Jika token kadaluwarsa / tidak valid (401 Unauthorized), bersihkan sesi lokal
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Helper untuk mengambil pesan error yang rapi dari response JSON Laravel
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          return data['message'].toString();
        }
        if (data['errors'] != null && data['errors'] is Map) {
          final firstError = (data['errors'] as Map).values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet atau IP server Anda.';
      }
    }
    return 'Terjadi kesalahan yang tidak diketahui.';
  }
}