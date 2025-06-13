import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final String baseUrl =
      'https://projek-akhir-505940949397.us-central1.run.app/api';
  final storage = const FlutterSecureStorage();

  Future<String?> _getUserId() async {
    return await storage.read(key: 'user_id');
  }

  Future<List<Transaction>> getTransactions() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User ID tidak ditemukan');

    final response = await http.get(
      Uri.parse('$baseUrl/transaction?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('Get transactions response status: ${response.statusCode}');
    print('Get transactions response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final List<dynamic> data = responseData['data'];
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal mengambil data transaksi');
      }
    } else {
      throw Exception(
          'Gagal mengambil data transaksi: ${response.statusCode} - ${response.body}');
    }
  }

  Future<bool> createTransaction(Transaction transaction) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User ID tidak ditemukan');

    final requestBody = {
      'amount': transaction.amount,
      'type': transaction.type,
      'categoryId': transaction.categoryId,
      'description': transaction.description,
      'date': transaction.date.toIso8601String(),
      'created_at': transaction.createdAt.toIso8601String(),
    };

    print('Creating transaction at: $baseUrl/transaction?userId=$userId');
    print('Request body: $requestBody');

    final response = await http.post(
      Uri.parse('$baseUrl/transaction?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['status'] == 'success';
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Gagal membuat transaksi');
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User ID tidak ditemukan');

    final requestBody = {
      'amount': transaction.amount,
      'type': transaction.type,
      'categoryId': transaction.categoryId,
      'description': transaction.description,
      'date': transaction.date.toIso8601String(),
      'created_at': transaction.createdAt.toIso8601String(),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/transaction/${transaction.id}?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['status'] == 'success';
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Gagal mengupdate transaksi');
    }
  }

  Future<bool> deleteTransaction(int id) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User ID tidak ditemukan');

    final response = await http.delete(
      Uri.parse('$baseUrl/transaction/$id?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['status'] == 'success';
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Gagal menghapus transaksi');
    }
  }
}
