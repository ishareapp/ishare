import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat/chat_screen.dart';
import '../tracking/live_tracking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  List bookings = [];
  bool isLoading = true;
  String? userRole;
  late TabController _tabController;

  List<String> tabs = ['All', 'Pending', 'Confirmed', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadUserRole();
    fetchBookings();
  }

  Future<void> _loadUserRole() async {
    userRole = await StorageService.getRole();
    setState(() {});
  }

  List get filteredBookings {
    final selectedTab = tabs[_tabController.index];
    if (selectedTab == 'All') return bookings;
    return bookings
        .where((b) =>
            b['status']?.toString().toLowerCase() == selectedTab.toLowerCase())
        .toList();
  }

  Future<void> fetchBookings() async {
    setState(() => isLoading = true);

    try {
      final token = await StorageService.getToken();
      final role = await StorageService.getRole();

      String endpoint;
      if (role == 'driver') {
        endpoint = "${StorageService.baseUrl}/rides/my-rides-with-bookings/";
      } else {
        endpoint = "${StorageService.baseUrl}/rides/my-bookings/";
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (role == 'driver') {
            bookings = [];
            for (var ride in data) {
              if (ride['bookings'] != null) {
                for (var booking in ride['bookings']) {
                  booking['ride'] = {
                    'start_location': ride['start_location'],
                    'destination': ride['destination'],
                    'departure_time': ride['departure_time'],
                  };
                  bookings.add(booking);
                }
              }
            }
          } else {
            bookings = data;
          }
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load bookings");
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rateUser(int bookingId, bool isDriver) async {
    final rating = await showDialog<int>(
      context: context,
      builder: (context) => _RatingDialog(
        title: isDriver ? "Rate Passenger" : "Rate Driver",
      ),
    );

    if (rating == null) return;

    try {
      final token = await StorageService.getToken();

      final response = await http.post(
        Uri.parse("${StorageService.baseUrl}/rides/rate/$bookingId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"score": rating}),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Rating submitted successfully!"),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
          fetchBookings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _downloadReceipt(int bookingId) async {
    try {
      final token = await StorageService.getToken();
      final url = "${StorageService.baseUrl}/rides/receipt/$bookingId/";

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Receipt downloaded!"),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception("Failed to download receipt");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _openChat(int bookingId, String otherUserName) async {
    try {
      final token = await StorageService.getToken();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        Uri.parse("${StorageService.baseUrl}/chat/create/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"booking_id": bookingId}),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatRoom = data['chat_room'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatRoomId: chatRoom['id'],
              otherUserName: otherUserName,
            ),
          ),
        );
      } else {
        throw Exception("Failed to create chat: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = userRole == 'driver';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isDriver ? "My Rides & Bookings" : "My Bookings",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A8A),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (_) => setState(() {}),
          tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchBookings,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredBookings.isEmpty
                ? _buildEmptyState(isDriver)
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(booking, isDriver);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDriver) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isDriver ? "No bookings yet" : "No bookings yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDriver
                ? "Bookings will appear here when passengers book your rides"
                : "Your booked rides will appear here",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map booking, bool isDriver) {
    final ride = booking['ride'];
    final status = booking['status']?.toString().toLowerCase() ?? '';

    final isCompleted = status == 'completed';
    final isConfirmed = status == 'confirmed';
    final canChat = true;
    final canTrack = isConfirmed;

    final otherUserName = isDriver
        ? (booking['passenger_name'] ?? 'Passenger')
        : (booking['driver_name'] ?? 'Driver');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  "ID: ${booking['id']}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Color(0xFF1E3A8A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${ride["start_location"]} → ${ride["destination"]}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                ride["departure_time"] ?? "Not specified",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.person_rounded,
                      otherUserName,
                      Colors.grey.shade700,
                    ),
                    _buildInfoChip(
                      Icons.event_seat_rounded,
                      "${booking['seats_booked']} seats",
                      Colors.grey.shade700,
                    ),
                    _buildInfoChip(
                      Icons.attach_money_rounded,
                      "${booking['total_price']} RWF",
                      const Color(0xFF10B981),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                if (canTrack) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveTrackingScreen(
                              bookingId: booking['id'],
                              driverName: booking['driver_name'] ?? 'Driver',
                              driverPhone: booking['driver_phone'] ?? '',
                              passengerName:
                                  booking['passenger_name'] ?? 'Passenger',
                              passengerPhone: booking['passenger_phone'] ?? '',
                              isDriver: userRole == 'driver',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text("Track Ride"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (canChat) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _openChat(booking['id'], otherUserName);
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: Text(isDriver
                          ? "Chat with Passenger"
                          : "Chat with Driver"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                if (isCompleted) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rateUser(booking['id'], isDriver),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text("Rate"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadReceipt(booking['id']),
                          icon: const Icon(Icons.receipt_rounded, size: 18),
                          label: const Text("Receipt"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Rating dialog
class _RatingDialog extends StatefulWidget {
  final String title;

  const _RatingDialog({this.title = "Rate Driver"});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("How was your experience?"),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFF59E0B),
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    selectedRating = index + 1;
                  });
                },
              );
            }),
          ),
          if (selectedRating > 0) ...[
            const SizedBox(height: 8),
            Text(
              _getRatingText(selectedRating),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: selectedRating > 0
              ? () => Navigator.pop(context, selectedRating)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Submit"),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Poor";
      case 2:
        return "Fair";
      case 3:
        return "Good";
      case 4:
        return "Very Good";
      case 5:
        return "Excellent";
      default:
        return "";
    }
  }
}