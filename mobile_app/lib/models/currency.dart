class Currency {
  final String code;
  final String name;
  final String symbol;
  final double rate; // Rate terhadap IDR

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rate,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      rate: json['rate'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'rate': rate,
    };
  }
}

// Daftar mata uang yang tersedia
final List<Currency> availableCurrencies = [
  Currency(
    code: 'IDR',
    name: 'Indonesian Rupiah',
    symbol: 'Rp',
    rate: 1.0,
  ),
  Currency(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    rate: 0.000064, // Contoh rate, akan diupdate dari API
  ),
  Currency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    rate: 0.000059, // Contoh rate, akan diupdate dari API
  ),
  Currency(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
    rate: 0.000050, // Contoh rate, akan diupdate dari API
  ),
  Currency(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    rate: 0.0096, // Contoh rate, akan diupdate dari API
  ),
];
