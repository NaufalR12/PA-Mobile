import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/category_model.dart';

class CategoryService {
  final String baseUrl =
      'https://projek-akhir-505940949397.us-central1.run.app/api';
  final storage = const FlutterSecureStorage();

  Future<String> _getUserId() async {
    final userId = await storage.read(key: 'user_id');
    if (userId == null) {
      throw Exception('User ID tidak ditemukan');
    }
    return userId;
  }

  Future<List<Category>> getCategories() async {
    try {
      final userId = await _getUserId();
      print('Fetching categories for user: $userId');

      final url = '$baseUrl/category?userId=$userId';
      print('Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> categoriesJson = data['data'];
          return categoriesJson.map((json) => Category.fromJson(json)).toList();
        }
        throw Exception(data['message'] ?? 'Gagal mengambil data kategori');
      } else {
        throw Exception(
            'Gagal mengambil data kategori: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  Future<bool> createCategory(String name) async {
    try {
      final userId = await _getUserId();
      print('Creating category for user: $userId');

      final body = {'name': name};
      print('Request body: $body');

      final url = '$baseUrl/category?userId=$userId';
      print('Request URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('Create Category Response: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Gagal membuat kategori: ${response.body}');
      }
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final userId = await _getUserId();
      print('Updating category for user: $userId');
      print('Category to update: ${category.toJson()}');

      final body = {'name': category.name};
      print('Request body: $body');

      final url = '$baseUrl/category/${category.id}?userId=$userId';
      print('Request URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('Update Category Response: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Gagal mengupdate kategori: ${response.body}');
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final userId = await _getUserId();
      print('Deleting category for user: $userId');

      final url = '$baseUrl/category/$id?userId=$userId';
      print('Request URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Delete Category Response: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Gagal menghapus kategori: ${response.body}');
      }
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
