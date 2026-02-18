import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/extensions/translation_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List rides = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRides();
  }

  Future<void> fetchRides() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) return;

      final data = await AuthService.getRides(token);

      setState(() {
        rides = data;
        isLoading = false;
      });

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        title: const Text("ISHARE"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Welcome 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Upcoming Rides",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(child: _buildRideContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildRideContent() {

    /// Loading State
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    /// Empty State
    if (rides.isEmpty) {
      return const Center(
        child: Text(
          "No rides available yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    /// Ride List
    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) {

        final ride = rides[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.directions_car),

            title: Text(
              "${ride["from_location"]} → ${ride["to_location"]}",
            ),

            subtitle: Text(
              "Driver: ${ride["driver_name"]}",
            ),
          ),
        );
      },
    );
  }
}