import 'package:flutter/material.dart';
import '../../core/extensions/translation_extension.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Terms of Service"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ISHARE Terms of Service",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Last updated: February 15, 2026",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              "1. Acceptance of Terms",
              "By accessing and using ISHARE, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, you should not use ISHARE.",
            ),
            
            _buildSection(
              "2. Description of Service",
              "ISHARE provides a platform for connecting drivers and passengers for ride-sharing services. We act as an intermediary and are not responsible for the conduct of drivers or passengers.",
            ),
            
            _buildSection(
              "3. User Accounts",
              "You must create an account to use our services. You are responsible for maintaining the confidentiality of your account and password. You agree to:\n\n• Provide accurate and complete information\n• Update your information to keep it accurate\n• Not share your account with others\n• Notify us immediately of any unauthorized use",
            ),
            
            _buildSection(
              "4. Driver Requirements",
              "Drivers must:\n\n• Have a valid driver's license\n• Maintain valid vehicle registration\n• Have appropriate insurance coverage\n• Pass our verification process\n• Comply with all traffic laws and regulations",
            ),
            
            _buildSection(
              "5. Passenger Requirements",
              "Passengers must:\n\n• Be at least 18 years old\n• Provide accurate pickup and drop-off locations\n• Respect drivers and their vehicles\n• Pay the agreed fare for services rendered",
            ),
            
            _buildSection(
              "6. Payment Terms",
              "• All payments are processed through our secure payment system\n• Prices are determined by distance, time, and demand\n• Cancellation fees may apply\n• Refunds are issued at our discretion",
            ),
            
            _buildSection(
              "7. Prohibited Conduct",
              "Users must not:\n\n• Violate any laws or regulations\n• Harass, abuse, or harm others\n• Use the service for illegal activities\n• Interfere with the proper functioning of the platform\n• Attempt to gain unauthorized access to our systems",
            ),
            
            _buildSection(
              "8. Safety",
              "We prioritize safety but cannot guarantee it. Users are responsible for their own safety and should:\n\n• Verify driver/passenger identity\n• Report suspicious behavior\n• Follow safety guidelines\n• Use emergency services when necessary",
            ),
            
            _buildSection(
              "9. Rating System",
              "Users can rate each other after completed rides. Consistently low ratings may result in account suspension or termination.",
            ),
            
            _buildSection(
              "10. Liability",
              "ISHARE is not liable for:\n\n• Accidents or injuries during rides\n• Lost or damaged property\n• Disputes between drivers and passengers\n• Service interruptions or technical issues",
            ),
            
            _buildSection(
              "11. Termination",
              "We reserve the right to suspend or terminate accounts that violate these terms or engage in prohibited conduct.",
            ),
            
            _buildSection(
              "12. Changes to Terms",
              "We may update these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.",
            ),
            
            _buildSection(
              "13. Contact Us",
              "For questions about these terms, contact us at:\n\nEmail: support@ishare.rw\nPhone: +250 793487065",
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}