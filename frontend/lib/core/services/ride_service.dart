import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../core/extensions/translation_extension.dart';

class RideService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Create a new ride (for drivers)
  static Future<Map<String, dynamic>> createRide({
    required String startLocation,
    required String destination,
    required String departureTime,
    required double pricePerSeat,
    required int availableSeats,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/create/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "start_location": startLocation,
        "destination": destination,
        "departure_time": departureTime,
        "price_per_seat": pricePerSeat,
        "available_seats": availableSeats,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create ride: ${response.body}");
    }
  }

  // Create scheduled rides
  static Future<Map<String, dynamic>> createScheduledRide({
    required String startLocation,
    required String destination,
    required String departureTime,
    required double pricePerSeat,
    required int availableSeats,
    required String scheduleType,
    required String endDate,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/create-scheduled/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "start_location": startLocation,
        "destination": destination,
        "departure_time": departureTime,
        "price_per_seat": pricePerSeat,
        "available_seats": availableSeats,
        "schedule_type": scheduleType,
        "end_date": endDate,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create scheduled rides: ${response.body}");
    }
  }

  // Search for available rides
  static Future<List<dynamic>> searchRides({
    String? startLocation,
    String? destination,
  }) async {
    final token = await StorageService.getToken();
    
    String url = "$baseUrl/rides/search/";
    List<String> params = [];
    
    if (startLocation != null && startLocation.isNotEmpty) {
      params.add("start_location=$startLocation");
    }
    if (destination != null && destination.isNotEmpty) {
      params.add("destination=$destination");
    }
    
    if (params.isNotEmpty) {
      url += "?${params.join('&')}";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to search rides: ${response.body}");
    }
  }

  // Book a ride (for passengers)
  static Future<Map<String, dynamic>> bookRide({
    required int rideId,
    required int seatsBooked,
    bool paymentConfirmed = true,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/book/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "ride": rideId,
        "seats_booked": seatsBooked,
        "payment_confirmed": paymentConfirmed,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to book ride: ${response.body}");
    }
  }

  // Complete a ride (for drivers)
  static Future<void> completeRide(int rideId) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/complete/$rideId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to complete ride: ${response.body}");
    }
  }

  // Rate a user after ride completion
  static Future<Map<String, dynamic>> rateUser({
    required int bookingId,
    required int score,
    String? comment,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/rate/$bookingId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "score": score,
        "comment": comment ?? "",
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to submit rating: ${response.body}");
    }
  }

  // Update booking status (for drivers)
  static Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/booking/$bookingId/update/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "status": status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update booking: ${response.body}");
    }
  }
}