import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'package:http_parser/http_parser.dart';

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

  Future<User> updateProfile(String name, String gender) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User ID tidak ditemukan');
      }

      print('AuthService: Mengupdate profil untuk user ID: $userId');
      print(
          'AuthService: Data yang akan diupdate - name: $name, gender: $gender');

      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.updateProfile}?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'gender': gender,
        }),
      );

      print('AuthService: Response status code: ${response.statusCode}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('AuthService: Update profil berhasil');
          return User.fromJson(data['data']);
        } else {
          print('AuthService: Update profil gagal - ${data['message']}');
          throw Exception(data['message'] ?? 'Gagal mengupdate profil');
        }
      } else {
        final error = jsonDecode(response.body);
        print('AuthService: Update profil gagal - ${error['message']}');
        throw Exception(error['message'] ?? 'Gagal mengupdate profil');
      }
    } catch (e) {
      print('AuthService: Error saat update profil - $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<User> updateEmail(String email) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User ID tidak ditemukan');
      }

      print('AuthService: Mengupdate email untuk user ID: $userId');
      print('AuthService: Email baru: $email');

      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.updateProfile}?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      print('AuthService: Response status code: ${response.statusCode}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('AuthService: Update email berhasil');
          return User.fromJson(data['data']);
        } else {
          print('AuthService: Update email gagal - ${data['message']}');
          throw Exception(data['message'] ?? 'Gagal mengupdate email');
        }
      } else {
        final error = jsonDecode(response.body);
        print('AuthService: Update email gagal - ${error['message']}');
        throw Exception(error['message'] ?? 'Gagal mengupdate email');
      }
    } catch (e) {
      print('AuthService: Error saat update email - $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<User> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User ID tidak ditemukan');
      }

      print('AuthService: Mengupdate password untuk user ID: $userId');

      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.updateProfile}?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      print('AuthService: Response status code: ${response.statusCode}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('AuthService: Update password berhasil');
          return User.fromJson(data['data']);
        } else {
          print('AuthService: Update password gagal - ${data['message']}');
          throw Exception(data['message'] ?? 'Gagal mengupdate password');
        }
      } else {
        final error = jsonDecode(response.body);
        print('AuthService: Update password gagal - ${error['message']}');
        throw Exception(error['message'] ?? 'Gagal mengupdate password');
      }
    } catch (e) {
      print('AuthService: Error saat update password - $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<User> updateProfilePhoto(String imagePath) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User ID tidak ditemukan');
      }

      print('AuthService: Mengupdate foto profil untuk user ID: $userId');

      // Buat multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.updateProfilePhoto}?userId=$userId'),
      );

      // Tambahkan file foto
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_profil',
          imagePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('AuthService: Response status code: ${response.statusCode}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('AuthService: Update foto profil berhasil');
          return User.fromJson(data['data']);
        } else {
          print('AuthService: Update foto profil gagal - ${data['message']}');
          throw Exception(data['message'] ?? 'Gagal mengupdate foto profil');
        }
      } else {
        final error = jsonDecode(response.body);
        print('AuthService: Update foto profil gagal - ${error['message']}');
        throw Exception(error['message'] ?? 'Gagal mengupdate foto profil');
      }
    } catch (e) {
      print('AuthService: Error saat update foto profil - $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
