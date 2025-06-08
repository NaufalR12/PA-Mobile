import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencyProvider with ChangeNotifier {
  Currency _selectedCurrency = availableCurrencies.first;
  bool _isLoading = false;

  Currency get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;

  CurrencyProvider() {
    _loadSelectedCurrency();
  }

  Future<void> _loadSelectedCurrency() async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedCurrency = await CurrencyService.getSelectedCurrency();

      // Update rates jika diperlukan
      if (await CurrencyService.shouldUpdateRates()) {
        await CurrencyService.updateRates();
      }
    } catch (e) {
      print('Error loading currency: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setCurrency(String currencyCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      await CurrencyService.setSelectedCurrency(currencyCode);
      _selectedCurrency = availableCurrencies.firstWhere(
        (c) => c.code == currencyCode,
      );
    } catch (e) {
      print('Error setting currency: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> formatAmount(double amount) async {
    return await CurrencyService.formatAmount(amount);
  }

  Future<double> convertFromIDR(double amount) async {
    return await CurrencyService.convertFromIDR(amount);
  }

  Future<double> convertToIDR(double amount) async {
    return await CurrencyService.convertToIDR(amount);
  }
}
