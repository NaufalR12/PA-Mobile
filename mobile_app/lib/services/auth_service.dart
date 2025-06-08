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
        // Simpan user ID untuk digunakan di request berikutnya
        await storage.write(key: 'user_id', value: userData['id'].toString());
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
    await storage.deleteAll();
  }

  Future<String?> getUserId() async {
    return await storage.read(key: 'user_id');
  }

  Future<bool> isLoggedIn() async {
    final userId = await storage.read(key: 'user_id');
    return userId != null;
  }
}
