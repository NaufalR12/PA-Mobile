class Transaction {
  final int id;
  final double amount;
  final String type; // 'income' atau 'expense'
  final int categoryId;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    try {
      return Transaction(
        id: json['id'] ?? 0,
        amount: parseAmount(json['amount']),
        type: json['type'] ?? '',
        categoryId: json['categoryId'] ?? json['category_id'] ?? 0,
        description: json['description'] ?? '',
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('Error parsing Transaction JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
