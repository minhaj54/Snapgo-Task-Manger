import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';

  // Save login state
  static Future<void> saveLoginState({
    required String userName,
    required String userEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserName, userName);
      await prefs.setString(_keyUserEmail, userEmail);
    } catch (e) {
      print('Error saving login state: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('Error checking login state: $e');
      return false;
    }
  }

  // Get saved user name
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName);
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  // Get saved user email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  // Clear login state (logout)
  static Future<void> clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
    } catch (e) {
      print('Error clearing login state: $e');
    }
  }
}

