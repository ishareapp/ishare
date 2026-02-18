import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/storage_service.dart';
import '../../core/extensions/translation_extension.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      
      final response = await http.get(
        Uri.parse("${StorageService.baseUrl}/accounts/admin/dashboard/stats/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          stats = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load dashboard");
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? const Center(child: Text("Failed to load dashboard"))
              : RefreshIndicator(
                  onRefresh: fetchDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title
                        const Text(
                          "📊 Platform Overview",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _buildStatCard(
                              title: "Total Revenue",
                              value: "${_formatNumber(stats!['revenue']['total'])} RWF",
                              subtitle: "${_formatNumber(stats!['revenue']['last_30_days'])} (30d)",
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              title: "Total Users",
                              value: "${stats!['users']['total']}",
                              subtitle: "+${stats!['users']['new_last_30_days']} (${stats!['users']['growth_rate']}%)",
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              title: "Total Rides",
                              value: "${stats!['rides']['total']}",
                              subtitle: "${stats!['rides']['active']} active",
                              icon: Icons.directions_car,
                              color: Colors.orange,
                            ),
                            _buildStatCard(
                              title: "Bookings",
                              value: "${stats!['bookings']['total']}",
                              subtitle: "${stats!['bookings']['confirmed']} confirmed",
                              icon: Icons.receipt_long,
                              color: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Revenue Breakdown
                        const Text(
                          "💰 Revenue Breakdown",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow("Today", "${_formatNumber(stats!['revenue']['today'])} RWF"),
                                const Divider(),
                                _buildDetailRow("Last 7 Days", "${_formatNumber(stats!['revenue']['last_7_days'])} RWF"),
                                const Divider(),
                                _buildDetailRow("Last 30 Days", "${_formatNumber(stats!['revenue']['last_30_days'])} RWF"),
                                const Divider(),
                                _buildDetailRow("Total", "${_formatNumber(stats!['revenue']['total'])} RWF", isBold: true),
                                const Divider(),
                                _buildDetailRow("Avg Booking", "${_formatNumber(stats!['revenue']['average_booking_value'])} RWF"),
                                const Divider(),
                                _buildDetailRow("Subscription Revenue", "${_formatNumber(stats!['revenue']['subscription_revenue'])} RWF"),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Driver Stats
                        const Text(
                          "🚕 Driver Statistics",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow("Total Drivers", "${stats!['drivers']['total']}"),
                                const Divider(),
                                _buildDetailRow("Verified Drivers", "${stats!['drivers']['verified']}", 
                                  valueColor: Colors.green),
                                const Divider(),
                                _buildDetailRow("Pending Verification", "${stats!['drivers']['pending_verification']}", 
                                  valueColor: Colors.orange),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Subscription Stats
                        const Text(
                          "💳 Subscription Statistics",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow("Active Subscriptions", "${stats!['subscriptions']['active']}"),
                                const Divider(),
                                _buildDetailRow("Trial Subscriptions", "${stats!['subscriptions']['trial']}"),
                                const Divider(),
                                _buildDetailRow("Paid Subscriptions", "${stats!['subscriptions']['paid']}"),
                                const Divider(),
                                _buildDetailRow("Expired", "${stats!['subscriptions']['expired']}", 
                                  valueColor: Colors.red),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Platform Health
                        const Text(
                          "⭐ Platform Health",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow("Total Ratings", "${stats!['ratings']['total']}"),
                                const Divider(),
                                _buildDetailRow("Average Rating", "⭐ ${stats!['ratings']['average']}/5"),
                                const Divider(),
                                _buildDetailRow("Completion Rate", 
                                  "${_calculateCompletionRate()}%", 
                                  valueColor: Colors.green),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return "0";
    final value = double.tryParse(number.toString()) ?? 0;
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _calculateCompletionRate() {
    final total = stats!['rides']['total'];
    final completed = stats!['rides']['completed'];
    if (total == 0) return "0";
    return ((completed / total) * 100).toStringAsFixed(1);
  }
}