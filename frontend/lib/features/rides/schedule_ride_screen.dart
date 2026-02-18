import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/extensions/translation_extension.dart';

class ScheduleRideScreen extends StatefulWidget {
  final int rideId;
  final Map<String, dynamic> rideDetails;
  
  const ScheduleRideScreen({
    super.key,
    required this.rideId,
    required this.rideDetails,
  });

  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
  String selectedScheduleType = 'once'; // once, daily, weekend, monthly
  DateTime selectedDate = DateTime.now();
  DateTime? endDate;
  int seatsToBook = 1;
  bool isBooking = false;
  
  // Days selection for custom scheduling
  Set<int> selectedDays = {}; // 1=Monday, 7=Sunday
  
  final Map<String, String> scheduleTypes = {
    'once': 'One-time Ride',
    'daily': 'Daily (Mon-Fri)',
    'weekend': 'Weekend (Sat-Sun)',
    'monthly': 'Monthly',
  };

  Future<void> _selectDate(BuildContext context, {bool isEndDate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (endDate ?? DateTime.now().add(const Duration(days: 30))) : selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isEndDate) {
          endDate = picked;
        } else {
          selectedDate = picked;
        }
      });
    }
  }

  Future<void> _bookScheduledRide() async {
    if (selectedScheduleType != 'once' && endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an end date for recurring rides")),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      final token = await StorageService.getToken();
      
      final response = await http.post(
        Uri.parse("${StorageService.baseUrl}/rides/schedule-booking/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "ride": widget.rideId,
          "seats_booked": seatsToBook,
          "schedule_type": selectedScheduleType,
          "start_date": selectedDate.toIso8601String(),
          "end_date": endDate?.toIso8601String(),
          "selected_days": selectedDays.toList(),
          "payment_confirmed": true,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Success!"),
              content: Text(
                selectedScheduleType == 'once'
                    ? "Your ride has been scheduled successfully!"
                    : "Your recurring rides have been scheduled successfully!",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception("Failed to schedule ride");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (double.tryParse(widget.rideDetails['price_per_seat'].toString()) ?? 0) * seatsToBook;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Schedule Ride"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${widget.rideDetails['start_location']} → ${widget.rideDetails['destination']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.rideDetails['price_per_seat']} RWF per seat",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Schedule Type
            const Text(
              "Schedule Type",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...scheduleTypes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: selectedScheduleType,
                  onChanged: (value) {
                    setState(() {
                      selectedScheduleType = value!;
                      if (value == 'once') {
                        endDate = null;
                      }
                    });
                  },
                  title: Text(entry.value),
                  subtitle: Text(_getScheduleDescription(entry.key)),
                  activeColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selectedScheduleType == entry.key
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Start Date
            const Text(
              "Start Date",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            
            // End Date (for recurring rides)
            if (selectedScheduleType != 'once') ...[
              const SizedBox(height: 16),
              const Text(
                "End Date",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              InkWell(
                onTap: () => _selectDate(context, isEndDate: true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 12),
                      Text(
                        endDate != null
                            ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                            : "Select end date",
                        style: TextStyle(
                          fontSize: 16,
                          color: endDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Seats Selection
            const Text(
              "Number of Seats",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                IconButton(
                  onPressed: seatsToBook > 1
                      ? () => setState(() => seatsToBook--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF1E3A8A),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    "$seatsToBook",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: seatsToBook < (widget.rideDetails['available_seats'] ?? 1)
                      ? () => setState(() => seatsToBook++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1E3A8A),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Total Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Price:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${totalPrice.toStringAsFixed(0)} RWF",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBooking ? null : _bookScheduledRide,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Confirm Booking",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScheduleDescription(String type) {
    switch (type) {
      case 'once':
        return 'Book for a single trip';
      case 'daily':
        return 'Monday to Friday, every week';
      case 'weekend':
        return 'Saturday and Sunday, every week';
      case 'monthly':
        return 'Same date every month';
      default:
        return '';
    }
  }
}