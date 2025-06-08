class User {
  final int id;
  final String name;
  final String email;
  final String gender;
  final String? fotoProfil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    this.fotoProfil,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw Exception('JSON data is null');
    }

    try {
      return User(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        gender: json['gender'] ?? '',
        fotoProfil: json['foto_profil'] ?? json['fotoProfil'],
        createdAt: json['created_at'] != null || json['createdAt'] != null
            ? DateTime.parse(json['created_at'] ?? json['createdAt'])
            : null,
        updatedAt: json['updated_at'] != null || json['updatedAt'] != null
            ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
            : null,
      );
    } catch (e) {
      print('Error parsing User JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender,
      'foto_profil': fotoProfil,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
