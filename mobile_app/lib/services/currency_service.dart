import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class CurrencyService {
  static const String _apiKey = '7ff5b3c71fbec20f8d5343fa'; // Ganti dengan API key Anda
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/IDR';
  static const String _prefsKey = 'selected_currency';
  static const String _lastUpdateKey = 'last_currency_update';

  // Mendapatkan mata uang yang dipilih
  static Future<Currency> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString(_prefsKey) ?? 'IDR';
    return availableCurrencies.firstWhere((c) => c.code == currencyCode);
  }

  // Menyimpan mata uang yang dipilih
  static Future<void> setSelectedCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, currencyCode);
  }

  // Update rate mata uang dari API
  static Future<void> updateRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // Update rate untuk setiap mata uang
        for (var currency in availableCurrencies) {
          if (currency.code != 'IDR') {
            final rate = rates[currency.code] as double;
            currency = Currency(
              code: currency.code,
              name: currency.name,
              symbol: currency.symbol,
              rate: rate,
            );
          }
        }

        // Simpan waktu update terakhir
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error updating currency rates: $e');
    }
  }

  // Konversi jumlah dari IDR ke mata uang yang dipilih
  static Future<double> convertFromIDR(double amount) async {
    final selectedCurrency = await getSelectedCurrency();
    return amount * selectedCurrency.rate;
  }

  // Konversi jumlah dari mata uang yang dipilih ke IDR
  static Future<double> convertToIDR(double amount) async {
    final selectedCurrency = await getSelectedCurrency();
    return amount / selectedCurrency.rate;
  }

  // Format jumlah dengan simbol mata uang
  static Future<String> formatAmount(double amount) async {
    final selectedCurrency = await getSelectedCurrency();
    final convertedAmount = await convertFromIDR(amount);

    // Format angka dengan pemisah ribuan
    final formattedAmount = convertedAmount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return '${selectedCurrency.symbol} $formattedAmount';
  }

  // Cek apakah perlu update rate
  static Future<bool> shouldUpdateRates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_lastUpdateKey);

    if (lastUpdate == null) return true;

    final lastUpdateTime = DateTime.parse(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    // Update setiap 24 jam
    return difference.inHours >= 24;
  }
}
