import 'package:flutter/material.dart';
import '../../core/extensions/translation_extension.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ISHARE Privacy Policy",
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
              "1. Introduction",
              "ISHARE (\"we\", \"our\", or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our ride-sharing platform.",
            ),
            
            _buildSection(
              "2. Information We Collect",
              "We collect information that you provide directly to us:\n\n• Personal Information: Name, email, phone number, profile picture\n• Location Data: GPS coordinates for pickup and drop-off\n• Payment Information: Payment methods and transaction history\n• Usage Data: App activity, ride history, preferences\n• Device Information: Device type, operating system, unique identifiers",
            ),
            
            _buildSection(
              "3. How We Use Your Information",
              "We use your information to:\n\n• Provide and improve our services\n• Connect drivers with passengers\n• Process payments and send receipts\n• Communicate with you about rides and updates\n• Verify identity and ensure safety\n• Analyze usage patterns and improve user experience\n• Comply with legal obligations",
            ),
            
            _buildSection(
              "4. Location Information",
              "We collect precise location data when you use our app to:\n\n• Show nearby drivers to passengers\n• Navigate drivers to pickup and drop-off locations\n• Calculate fares and estimated arrival times\n• Improve our services and routing\n\nYou can disable location services in your device settings, but this will limit functionality.",
            ),
            
            _buildSection(
              "5. Information Sharing",
              "We may share your information with:\n\n• Drivers/Passengers: Name, photo, phone number (for completed bookings)\n• Service Providers: Payment processors, analytics providers\n• Legal Authorities: When required by law or to protect rights and safety\n• Business Transfers: In connection with mergers or acquisitions\n\nWe do not sell your personal information to third parties.",
            ),
            
            _buildSection(
              "6. Data Security",
              "We implement security measures to protect your information:\n\n• Encryption of sensitive data in transit and at rest\n• Secure authentication and access controls\n• Regular security audits and updates\n• Employee training on data protection\n\nHowever, no method of transmission over the Internet is 100% secure.",
            ),
            
            _buildSection(
              "7. Data Retention",
              "We retain your information for as long as necessary to:\n\n• Provide our services\n• Comply with legal obligations\n• Resolve disputes and enforce agreements\n• Improve our services\n\nYou can request deletion of your account and data at any time.",
            ),
            
            _buildSection(
              "8. Your Rights",
              "You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your data\n• Object to processing of your data\n• Export your data\n• Opt-out of marketing communications",
            ),
            
            _buildSection(
              "9. Children's Privacy",
              "Our services are not intended for users under 18 years of age. We do not knowingly collect information from children.",
            ),
            
            _buildSection(
              "10. Cookies and Tracking",
              "We use cookies and similar technologies to:\n\n• Remember your preferences\n• Analyze usage patterns\n• Improve performance\n• Provide personalized experiences\n\nYou can control cookies through your browser settings.",
            ),
            
            _buildSection(
              "11. Changes to Privacy Policy",
              "We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or email.",
            ),
            
            _buildSection(
              "12. International Data Transfers",
              "Your information may be transferred to and processed in countries other than Rwanda. We ensure appropriate safeguards are in place.",
            ),
            
            _buildSection(
              "13. Contact Us",
              "If you have questions about this Privacy Policy or our data practices:\n\nEmail: privacy@ishare.rw\nPhone: +250 73 487 065\nAddress: Kigali, Rwanda",
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