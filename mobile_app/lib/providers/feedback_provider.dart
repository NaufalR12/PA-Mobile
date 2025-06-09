import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/feedback_model.dart';

class FeedbackProvider with ChangeNotifier {
  Database? _database;
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = false;

  List<FeedbackModel> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;

  Future<void> initDatabase() async {
    if (_database != null) return;

    _database = await openDatabase(
      join(await getDatabasesPath(), 'feedback_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE feedbacks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            saran TEXT,
            kesan TEXT,
            created_at TEXT
          )''',
        );
      },
      version: 1,
    );
  }

  Future<void> loadFeedbacks() async {
    _isLoading = true;
    notifyListeners();

    await initDatabase();
    final List<Map<String, dynamic>> maps =
        await _database!.query('feedbacks', orderBy: 'created_at DESC');
    _feedbacks = maps.map((map) => FeedbackModel.fromMap(map)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFeedback(String saran, String kesan) async {
    await initDatabase();

    final feedback = FeedbackModel(
      saran: saran,
      kesan: kesan,
      createdAt: DateTime.now(),
    );

    await _database!.insert(
      'feedbacks',
      feedback.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await loadFeedbacks();
  }

  Future<void> deleteFeedback(int id) async {
    await initDatabase();
    await _database!.delete(
      'feedbacks',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadFeedbacks();
  }
}
