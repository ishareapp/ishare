import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/language_service.dart';
import 'language_selection_screen.dart';
import '../tracking/emergency_contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool smsNotifications = false;
  bool locationEnabled = true;
  bool darkMode = false;
  String currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final langCode = await LanguageService.getLanguage();
    setState(() {
      // Map language code to display name
      if (langCode == 'en') {
        currentLanguage = 'English';
      } else if (langCode == 'fr') {
        currentLanguage = 'Français';
      } else if (langCode == 'rw') {
        currentLanguage = 'Ikinyarwanda';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _buildSectionHeader("Notifications"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                    },
                    title: const Text("Push Notifications"),
                    subtitle: const Text("Receive booking & ride updates"),
                    secondary: const Icon(Icons.notifications_outlined),
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    value: emailNotifications,
                    onChanged: notificationsEnabled
                        ? (value) {
                            setState(() {
                              emailNotifications = value;
                            });
                          }
                        : null,
                    title: const Text("Email Notifications"),
                    subtitle: const Text("Receive updates via email"),
                    secondary: const Icon(Icons.email_outlined),
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    value: smsNotifications,
                    onChanged: notificationsEnabled
                        ? (value) {
                            setState(() {
                              smsNotifications = value;
                            });
                          }
                        : null,
                    title: const Text("SMS Notifications"),
                    subtitle: const Text("Receive updates via SMS"),
                    secondary: const Icon(Icons.sms_outlined),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Safety & Emergency
            _buildSectionHeader("Safety & Emergency"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sos, color: Colors.red),
                    title: const Text("Emergency Contacts"),
                    subtitle: const Text("Manage SOS emergency contacts"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    value: locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        locationEnabled = value;
                      });
                    },
                    title: const Text("Location Services"),
                    subtitle: const Text("Allow app to access location"),
                    secondary: const Icon(Icons.location_on_outlined),
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text("Privacy Settings"),
                    subtitle: const Text("Control your data and privacy"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Privacy settings coming soon!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Appearance
            _buildSectionHeader("Appearance"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text("Language"),
                    subtitle: Text(currentLanguage),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionScreen(),
                        ),
                      );
                      
                      if (result == true && mounted) {
                        // Language was changed, update display
                        setState(() {
                          // Reload language
                          _loadLanguage();
                        });
                      }
                    },
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    value: darkMode,
                    onChanged: (value) {
                      setState(() {
                        darkMode = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Dark mode coming soon!")),
                      );
                    },
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Use dark theme"),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Security
            _buildSectionHeader("Security"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Change Password"),
                    subtitle: const Text("Update your password"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Change password coming soon!")),
                      );
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_outlined),
                    title: const Text("Biometric Login"),
                    subtitle: const Text("Use fingerprint or face ID"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Biometric login coming soon!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data & Storage
            _buildSectionHeader("Data & Storage"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text("Download Data"),
                    subtitle: const Text("Export your account data"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Download data coming soon!")),
                      );
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text("Permanently delete your account"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                    onTap: () {
                      _showDeleteAccountDialog();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account deletion coming soon!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}