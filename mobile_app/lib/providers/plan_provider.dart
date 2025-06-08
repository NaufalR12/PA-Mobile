import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

class PlanProvider with ChangeNotifier {
  final PlanService _planService = PlanService();
  List<Plan> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<Plan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlans() async {
    try {
      print('PlanProvider: Memulai loadPlans');
      _isLoading = true;
      _error = null;
      notifyListeners();

      _plans = await _planService.getPlans();
      print(
          'PlanProvider: Berhasil loadPlans, jumlah rencana: ${_plans.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('PlanProvider: Error dalam loadPlans: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPlan({
    required int categoryId,
    required double amount,
    String? description,
  }) async {
    try {
      print('PlanProvider: Memulai createPlan');
      print('PlanProvider: categoryId: $categoryId');
      print('PlanProvider: amount: $amount');
      print('PlanProvider: description: $description');

      _isLoading = true;
      _error = null;
      notifyListeners();

      final plan = await _planService.createPlan(
        categoryId: categoryId,
        amount: amount,
        description: description,
      );
      print('PlanProvider: Berhasil createPlan: ${plan.toJson()}');

      _plans.add(plan);

      await loadPlans();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('PlanProvider: Error dalam createPlan: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlan(Plan plan) async {
    try {
      print('PlanProvider: Memulai updatePlan');
      print('PlanProvider: plan: ${plan.toJson()}');

      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedPlan = await _planService.updatePlan(plan);
      print('PlanProvider: Berhasil updatePlan: ${updatedPlan.toJson()}');

      final index = _plans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _plans[index] = updatedPlan;
      }

      await loadPlans();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('PlanProvider: Error dalam updatePlan: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlan(int id) async {
    try {
      print('PlanProvider: Memulai deletePlan');
      print('PlanProvider: id: $id');

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _planService.deletePlan(id);
      print('PlanProvider: Berhasil deletePlan');

      _plans.removeWhere((plan) => plan.id == id);

      await loadPlans();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('PlanProvider: Error dalam deletePlan: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
