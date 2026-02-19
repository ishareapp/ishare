import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../auth/auth_screen.dart';
import '../admin/admin_dashboard_screen.dart';  // ADD THIS IMPORT
import '../../core/extensions/translation_extension.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
  try {
    final info = await AuthService.getCurrentUser();
    print("USER INFO: $info"); // ← add here
    setState(() {
      userInfo = info;
      isLoading = false;
    });
  } catch (e) {
    print("ERROR: $e"); // ← and here
    setState(() => isLoading = false);
  }
}
  Future<void> _logout(BuildContext context) async {
    await StorageService.clearAll();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = userInfo?['role'] ?? 'user';
    final username = userInfo?['username'] ?? 'User';
    final email = userInfo?['email'] ?? '';
    final isAdmin = userInfo?['is_superuser'] == true || userInfo?['is_staff'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// Profile Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: role == 'driver' 
                  ? const Color(0xFF1E3A8A) 
                  : const Color(0xFF10B981),
              child: Icon(
                role == 'driver' ? Icons.drive_eta : Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            /// Username
            Text(
              username,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            /// Email
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            /// Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: role == 'driver' 
                    ? Colors.blue.shade50 
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: role == 'driver' 
                      ? Colors.blue 
                      : Colors.green,
                ),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: role == 'driver' 
                      ? Colors.blue.shade900 
                      : Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// Rating (Placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    SizedBox(width: 8),
                    Text(
                      "4.8",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Rating",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ADMIN DASHBOARD BUTTON - Only shows for admins
            if (isAdmin) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.dashboard),
                  label: const Text("Admin Dashboard"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1E3A8A),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Spacer(),
            

            /// Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.red,
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}