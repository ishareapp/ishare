import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'withdraw_money_screen.dart';
import 'add_money_screen.dart';
import '../../core/extensions/translation_extension.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool isLoading = true;
  String? userRole;
  double balance = 0.0;
  List transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      final role = await StorageService.getRole();
      
      setState(() {
        userRole = role;
      });
      
      // TODO: Replace with actual wallet endpoint when backend is ready
      // For now, we'll calculate from bookings
      await _calculateBalanceFromBookings(token, role);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading wallet: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _calculateBalanceFromBookings(String? token, String? role) async {
    try {
      String endpoint;
      if (role == 'driver') {
        // For drivers: Get all rides with bookings
        endpoint = "${StorageService.baseUrl}/rides/my-rides-with-bookings/";
      } else {
        // For passengers: Get all bookings
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
        
        double totalBalance = 0.0;
        List<Map<String, dynamic>> transactionList = [];
        
        if (role == 'driver') {
          // Calculate driver earnings from rides
          for (var ride in data) {
            if (ride['bookings'] != null) {
              for (var booking in ride['bookings']) {
                if (booking['status'] == 'completed' && booking['payment_status'] == 'paid') {
                  final amount = double.tryParse(booking['total_price'].toString()) ?? 0.0;
                  totalBalance += amount;
                  
                  transactionList.add({
                    'type': 'earning',
                    'amount': amount,
                    'description': '${ride['start_location']} → ${ride['destination']}',
                    'passenger': booking['passenger']['username'],
                    'date': booking['created_at'],
                    'status': 'completed',
                  });
                }
              }
            }
          }
        } else {
          // Calculate passenger spending from bookings
          for (var booking in data) {
            if (booking['payment_status'] == 'paid') {
              final amount = double.tryParse(booking['total_price'].toString()) ?? 0.0;
              
              transactionList.add({
                'type': 'payment',
                'amount': amount,
                'description': '${booking['ride']['start_location']} → ${booking['ride']['destination']}',
                'driver': booking['ride']['driver_name'],
                'date': booking['created_at'],
                'status': booking['status'],
              });
            }
          }
          
          // For passengers, show negative balance (money spent)
          totalBalance = -totalBalance;
        }
        
        setState(() {
          balance = totalBalance;
          transactions = transactionList;
        });
      }
    } catch (e) {
      print("❌ Error calculating balance: $e");
    }
  }

  Future<void> _navigateToWithdraw() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawMoneyScreen(availableBalance: balance.abs()),
      ),
    );
    
    if (result == true) {
      _loadWalletData(); // Refresh balance
    }
  }

  Future<void> _navigateToAddMoney() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMoneyScreen(),
      ),
    );
    
    if (result == true) {
      _loadWalletData(); // Refresh balance
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = userRole == 'driver';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Wallet"),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Balance Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E3A8A),
                            const Color(0xFF3B82F6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDriver ? "Total Earnings" : "Total Spent",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${balance.abs().toStringAsFixed(0)} RWF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                isDriver ? Icons.trending_up : Icons.trending_down,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDriver 
                                    ? "From ${transactions.length} completed rides"
                                    : "From ${transactions.length} bookings",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          if (isDriver) ...[
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.account_balance,
                                label: "Withdraw",
                                color: Colors.green,
                                onTap: _navigateToWithdraw,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: _buildActionCard(
                              icon: isDriver ? Icons.history : Icons.add,
                              label: isDriver ? "History" : "Add Money",
                              color: const Color(0xFF1E3A8A),
                              onTap: isDriver 
                                  ? () {
                                      // Scroll to transactions
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("View full history below"),
                                        ),
                                      );
                                    }
                                  : _navigateToAddMoney,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Recent Transactions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Show all transactions
                            },
                            child: const Text("View All"),
                          ),
                        ],
                      ),
                    ),
                    
                    if (transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No transactions yet",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: transactions.length > 10 ? 10 : transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isEarning = transaction['type'] == 'earning';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isEarning 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                child: Icon(
                                  isEarning ? Icons.add : Icons.remove,
                                  color: isEarning ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                transaction['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                isDriver 
                                    ? "Passenger: ${transaction['passenger']}"
                                    : "Status: ${transaction['status']}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Text(
                                "${isEarning ? '+' : '-'}${transaction['amount'].toStringAsFixed(0)} RWF",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEarning ? Colors.green : Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}