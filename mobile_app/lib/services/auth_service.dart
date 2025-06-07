import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null) {
          throw Exception('Response data is null');
        }

        if (data['data'] == null) {
          throw Exception('User data is null in response');
        }

        final userData = data['data'];
        await storage.write(
            key: 'access_token', value: userData['accessToken']);
        await storage.write(
            key: 'refresh_token', value: userData['refreshToken']);
        return User.fromJson(userData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Login gagal: ${response.body}');
      }
    } catch (e) {
      print('Login Error: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('Refresh token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      print('Refresh Token Response Status: ${response.statusCode}');
      print('Refresh Token Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final newAccessToken = data['accessToken'];
          if (newAccessToken == null) {
            throw Exception('Access token tidak ditemukan dalam response');
          }
          await storage.write(key: 'access_token', value: newAccessToken);
        } else {
          throw Exception(data['message'] ?? 'Gagal refresh token');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal refresh token');
      }
    } catch (e) {
      print('Refresh Token Error: $e');
      throw Exception('Gagal refresh token: $e');
    }
  }

  Future<User> register(
      String name, String email, String gender, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'gender': gender,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return User.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Registrasi gagal');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> logout() async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      await storage.deleteAll();
    } catch (e) {
      throw Exception('Terjadi kesalahan saat logout: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) return null;

      // Decode token untuk mengecek expiration
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Jika token akan expired dalam 5 menit atau sudah expired
      if (exp - now < 300) {
        await refreshToken();
        return await storage.read(key: 'access_token');
      }

      return token;
    } catch (e) {
      print('Get Token Error: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'access_token');
    return token != null;
  }
}
