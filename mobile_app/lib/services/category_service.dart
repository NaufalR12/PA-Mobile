import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/category_model.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final url = '${ApiConstants.baseUrl}${ApiConstants.categories}';
      print('Fetching categories from: $url');
      print('Using token: $token');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Category Response Status: ${response.statusCode}');
      print('Category Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> categoriesJson = data['data'];
          return categoriesJson.map((json) => Category.fromJson(json)).toList();
        }
        throw Exception(data['message'] ?? 'Gagal mengambil data kategori');
      }
      throw Exception('Gagal mengambil data kategori: ${response.statusCode}');
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }
}
