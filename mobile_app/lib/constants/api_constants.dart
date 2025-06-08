class ApiConstants {
  static const String baseUrl =
      'https://projek-akhir-505940949397.us-central1.run.app/api';

  // Auth endpoints
  static const String login = '/user/login';
  static const String register = '/user/register';
  static const String updateProfile = '/user/profile';
  static const String updateProfilePhoto = '/user/profile/photo';
  static const String getProfile = '/user/me';
  static const String getProfilePhoto = '/user/profile/photo';
  static const String logout = '/user/logout';
  static const String deleteAccount = '/user/delete';

  // Transaction endpoints
  static const String transactions = '/transactions';
  static const String transactionById = '/transaction/';

  // Category endpoints
  static const String categories = '/categories';
  static const String categoryById = '/category/';

  // Plan endpoints
  static const String plans = '/plans';
  static const String planById = '/plan/';
}
