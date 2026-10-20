class AppConstants {
  AppConstants._();

  static const String appName = 'Temu Guru';
  static const String appTagline = 'Temukan Guru Terbaik, Belajar di Tempat Pilihanmu.';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String rememberMeKey = 'remember_me';

  // Validation limits
  static const int minPasswordLength = 6;
  static const int nikLength = 16;
  static const int maxTeacherAge = 35;
}
