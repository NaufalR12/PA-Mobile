class ApiConstants {
  static const String baseUrl =
      'https://projek-akhir-505940949397.us-central1.run.app/api';

  // Auth endpoints
  static const String login = '/user/login';
  static const String register = '/user/register';
  static const String logout = '/user/logout';
  static const String refreshToken = '/user/refresh-token';
  static const String profile = '/user/me';
  static const String updateProfile = '/user/profile';
  static const String deleteAccount = '/user/delete';

  // Transaction endpoints
  static const String transactions = '/transaction';
  static const String transactionById = '/transaction/';

  // Category endpoints
  static const String categories = '/category';
  static const String categoryById = '/category/';

  // Plan endpoints
  static const String plans = '/plan';
  static const String planById = '/plan/';
}
