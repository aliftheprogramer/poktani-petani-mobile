import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _prefs.setString('token', token);
  }

  String? getToken() {
    return _prefs.getString('token');
  }

  Future<void> removeToken() async {
    await _prefs.remove('token');
  }

  // User data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString('user_data', jsonEncode(userData));
  }

  User? getUserData() {
    final data = _prefs.getString('user_data');
    if (data != null) {
      try {
        final jsonData = jsonDecode(data);
        return User.fromJson(jsonData);
      } catch (e) {
        Logger().i('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> removeUserData() async {
    await _prefs.remove('user_data');
  }

  // General storage methods
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return getToken() != null;
  }

  // Logout
  Future<void> logout() async {
    await removeToken();
    await removeUserData();
  }
}
