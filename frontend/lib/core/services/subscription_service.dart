import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../core/extensions/translation_extension.dart';

class SubscriptionService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Get current user's subscription
  static Future<Map<String, dynamic>?> getSubscription() async {
    final token = await StorageService.getToken();

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/accounts/subscription/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null; // No subscription found
      } else {
        throw Exception("Failed to get subscription: ${response.body}");
      }
    } catch (e) {
      return null;
    }
  }

  // Create/Activate subscription (FREE TRIAL)
  static Future<Map<String, dynamic>> createSubscription({
    required String planType,
    bool isTrial = true,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/accounts/subscription/create/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "plan_type": planType,
        "is_trial": isTrial,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create subscription: ${response.body}");
    }
  }

  // Process payment for subscription (PAID)
  static Future<Map<String, dynamic>> processPayment({
    required String phoneNumber,
    required String paymentMethod,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/accounts/subscription/payment/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "phone_number": phoneNumber,
        "payment_method": paymentMethod,
        "amount": 5000,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Payment failed: ${response.body}");
    }
  }

  // Check if subscription is active
  static Future<bool> hasActiveSubscription() async {
    final subscription = await getSubscription();
    
    if (subscription == null) return false;
    
    final isActive = subscription['is_active'] ?? false;
    final expiryDate = DateTime.parse(subscription['expiry_date']);
    
    return isActive && expiryDate.isAfter(DateTime.now());
  }

  // Check if subscription is expired
  static Future<bool> isSubscriptionExpired() async {
    final subscription = await getSubscription();
    
    if (subscription == null) return false;
    
    final expiryDate = DateTime.parse(subscription['expiry_date']);
    return expiryDate.isBefore(DateTime.now());
  }

  // Get days remaining in subscription
  static Future<int> getDaysRemaining() async {
    final subscription = await getSubscription();
    
    if (subscription == null) return 0;
    
    final expiryDate = DateTime.parse(subscription['expiry_date']);
    final now = DateTime.now();
    
    if (expiryDate.isBefore(now)) return 0;
    
    return expiryDate.difference(now).inDays;
  }
}