class FeedbackModel {
  final int? id;
  final String saran;
  final String kesan;
  final DateTime createdAt;

  FeedbackModel({
    this.id,
    required this.saran,
    required this.kesan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saran': saran,
      'kesan': kesan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'],
      saran: map['saran'],
      kesan: map['kesan'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
