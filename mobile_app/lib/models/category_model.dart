class Category {
  final int id;
  final String name;
  final int userId;
  final String? type;

  Category({
    required this.id,
    required this.name,
    required this.userId,
    this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      userId: json['userId'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'type': type,
    };
  }
}
