class Plan {
  final int id;
  final int userId;
  final int categoryId;
  final double amount;
  final double remainingAmount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.remainingAmount,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    print('Plan.fromJson: Menerima data: $json');
    try {
      return Plan(
        id: int.parse(json['id'].toString()),
        userId: int.parse(json['userId'].toString()),
        categoryId: int.parse(json['categoryId'].toString()),
        amount: double.parse(json['amount'].toString()),
        remainingAmount: double.parse(json['remainingAmount'].toString()),
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
    } catch (e) {
      print('Plan.fromJson: Error parsing data: $e');
      print('Plan.fromJson: Data yang gagal diparse: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'remainingAmount': remainingAmount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
