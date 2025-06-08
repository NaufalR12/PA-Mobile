import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String gender, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(name, email, gender, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    return await _authService.isLoggedIn();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile(String name, String gender) async {
    print('AuthProvider: Memulai update profil');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Memanggil authService.updateProfile');
      _user = await _authService.updateProfile(name, gender);
      print(
          'AuthProvider: Update profil berhasil, user baru: ${_user?.toJson()}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider: Error saat update profil - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmail(String email) async {
    print('AuthProvider: Memulai update email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Memanggil authService.updateEmail');
      _user = await _authService.updateEmail(email);
      print(
          'AuthProvider: Update email berhasil, user baru: ${_user?.toJson()}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider: Error saat update email - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(
      String currentPassword, String newPassword) async {
    print('AuthProvider: Memulai update password');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Memanggil authService.updatePassword');
      _user = await _authService.updatePassword(currentPassword, newPassword);
      print('AuthProvider: Update password berhasil');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider: Error saat update password - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String imagePath) async {
    print('AuthProvider: Memulai update foto profil');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Memanggil authService.updateProfilePhoto');
      final updatedUser = await _authService.updateProfilePhoto(imagePath);
      print('AuthProvider: Update foto profil berhasil');

      // Update user state dengan data terbaru
      if (_user != null) {
        _user = User(
          id: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          gender: updatedUser.gender,
          fotoProfil: updatedUser.fotoProfil,
          createdAt: updatedUser.createdAt,
          updatedAt: updatedUser.updatedAt,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider: Error saat update foto profil - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
