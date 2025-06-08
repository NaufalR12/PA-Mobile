import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/plan_model.dart';

class PlanService {
  final String baseUrl =
      'https://projek-akhir-505940949397.us-central1.run.app/api';
  final storage = const FlutterSecureStorage();

  Future<String> _getUserId() async {
    try {
      final userId = await storage.read(key: 'user_id');
      print('Mencoba mendapatkan userId dari storage: $userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('User ID tidak ditemukan');
      }
      return userId;
    } catch (e) {
      print('Error dalam _getUserId: $e');
      throw Exception('User ID tidak ditemukan: $e');
    }
  }

  Future<List<Plan>> getPlans() async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/plan?userId=$userId'),
      );

      print('Get Plans Response Status: ${response.statusCode}');
      print('Get Plans Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> plansData = data['data'];
          return plansData.map((json) => Plan.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Gagal mengambil data rencana: ${response.body}');
      }
    } catch (e) {
      print('Error dalam getPlans: $e');
      throw Exception('Error: $e');
    }
  }

  Future<double> getCategoryTotalExpense(int categoryId) async {
    try {
      final userId = await _getUserId();
      print('Mendapatkan total pengeluaran untuk kategori: $categoryId');
      print('userId: $userId');

      final url = '$baseUrl/transaction?userId=$userId';
      print('Request URL: $url');

      final response = await http.get(Uri.parse(url));
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          // Hitung total pengeluaran untuk kategori ini
          final transactions = data['data'] as List;
          final totalExpense = transactions
              .where((t) =>
                  t['type'] == 'expense' && t['categoryId'] == categoryId)
              .fold<double>(
                  0,
                  (sum, t) =>
                      sum + (double.tryParse(t['amount'].toString()) ?? 0));

          print('Total pengeluaran untuk kategori $categoryId: $totalExpense');
          return totalExpense;
        }
        return 0;
      } else {
        throw Exception(
            'Gagal mendapatkan total pengeluaran: ${response.body}');
      }
    } catch (e) {
      print('Error dalam getCategoryTotalExpense: $e');
      return 0;
    }
  }

  Future<Plan> createPlan({
    required int categoryId,
    required double amount,
    String? description,
  }) async {
    try {
      final userId = await _getUserId();
      print('Membuat rencana dengan userId: $userId');
      print('categoryId: $categoryId');
      print('amount: $amount');
      print('description: $description');

      // Hitung total pengeluaran untuk kategori ini
      final totalExpense = await getCategoryTotalExpense(categoryId);
      print('Total pengeluaran kategori: $totalExpense');

      // Sisa saldo = jumlah rencana - total pengeluaran
      final remainingAmount = amount - totalExpense;
      print('Sisa jumlah: $remainingAmount');

      final requestBody = {
        'categoryId': categoryId,
        'amount': amount,
        'remainingAmount': remainingAmount,
        'description': description,
      };
      print('Request body: $requestBody');

      final url = '$baseUrl/plan?userId=$userId';
      print('Request URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Create Plan Response Status: ${response.statusCode}');
      print('Create Plan Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return Plan.fromJson(data['data']);
        }
        throw Exception('Data rencana tidak ditemukan dalam response');
      } else {
        throw Exception('Gagal membuat rencana: ${response.body}');
      }
    } catch (e) {
      print('Error dalam createPlan: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Plan> updatePlan(Plan plan) async {
    try {
      final userId = await _getUserId();
      print('PlanService: Memulai updatePlan');
      print('PlanService: userId: $userId');
      print('PlanService: plan: ${plan.toJson()}');

      // Hitung total pengeluaran untuk kategori ini
      final totalExpense = await getCategoryTotalExpense(plan.categoryId);
      print('Total pengeluaran kategori: $totalExpense');

      // Sisa saldo = jumlah rencana - total pengeluaran
      final remainingAmount = plan.amount - totalExpense;
      print('Sisa jumlah: $remainingAmount');

      final requestBody = {
        'categoryId': plan.categoryId,
        'amount': plan.amount,
        'remainingAmount': remainingAmount,
        'description': plan.description,
      };
      print('PlanService: Request body: $requestBody');

      final url = '$baseUrl/plan/${plan.id}?userId=$userId';
      print('PlanService: Request URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('PlanService: Update Plan Response Status: ${response.statusCode}');
      print('PlanService: Update Plan Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return Plan.fromJson(data['data']);
        }
        throw Exception('Data rencana tidak ditemukan dalam response');
      } else {
        throw Exception('Gagal memperbarui rencana: ${response.body}');
      }
    } catch (e) {
      print('PlanService: Error dalam updatePlan: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> deletePlan(int id) async {
    try {
      final userId = await _getUserId();
      final url = '$baseUrl/plan/$id?userId=$userId';
      print('Request URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Delete Plan Response Status: ${response.statusCode}');
      print('Delete Plan Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus rencana: ${response.body}');
      }
    } catch (e) {
      print('Error dalam deletePlan: $e');
      throw Exception('Error: $e');
    }
  }
}
