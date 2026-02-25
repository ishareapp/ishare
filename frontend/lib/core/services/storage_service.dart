import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/extensions/translation_extension.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "https://striking-charm-production-2481.up.railway.app/api";

  static Future<void> saveToken(String token) async {
    await _storage.write(key: "jwt_token", value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: "jwt_token");
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: "jwt_token");
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: "refresh_token", value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: "refresh_token");
  }

  static Future<String?> refreshAccessToken() async {
    final refreshToken = await StorageService.getRefreshToken();

    final response = await http.post(
      Uri.parse("$baseUrl/accounts/token/refresh/"),  // FIXED: added /accounts/
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await StorageService.saveToken(data["access"]);
      return data["access"];
    }

    return null;
  }

  // Role management
  static Future<void> saveRole(String role) async {
    await _storage.write(key: "user_role", value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: "user_role");
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}