import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../core/extensions/translation_extension.dart';

class AuthService {

  static const String baseUrl = "https://striking-charm-production-fbce.up.railway.app/api";

  static Future<Map<String, dynamic>> login(
      String email,
      String password,
  ) async {

    final response = await http.post(
      Uri.parse("$baseUrl/accounts/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(
      String username,
      String email,
      String phone,
      String password,
      String role,
  ) async {

    final response = await http.post(
      Uri.parse("$baseUrl/accounts/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role,
      }),
    );

    return jsonDecode(response.body);
  }

  // NEW METHOD: Get current user info
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await StorageService.getToken();
    
    final response = await http.get(
      Uri.parse("$baseUrl/accounts/me/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get user info: ${response.body}");
    }
  }

  static Future<List<dynamic>> getRides(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rides/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  static Future<void> submitRating(
    int driverId,
    int rating,
    String token,
  ) async {
    await http.post(
      Uri.parse("$baseUrl/ratings/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "driver_id": driverId,
        "rating": rating,
      }),
    );
  }
}