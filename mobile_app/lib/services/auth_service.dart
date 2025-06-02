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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access_token', value: data['access_token']);
        await storage.write(key: 'refresh_token', value: data['refresh_token']);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Login gagal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
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
    return await storage.read(key: 'access_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'access_token');
    return token != null;
  }
}
