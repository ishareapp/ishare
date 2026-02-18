import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../navigation/main_navigation.dart';
import '../verification/email_verification_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../documents/driver_document_upload_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLogin = true;
  bool isHidden = true;
  bool isLoading = false;

  String selectedRole = "Passenger";

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = isLogin
          ? await AuthService.login(
              emailController.text.trim(),
              passwordController.text.trim(),
            )
          : await AuthService.register(
              usernameController.text.trim(),
              emailController.text.trim(),
              phoneController.text.trim(),
              passwordController.text.trim(),
              selectedRole.toLowerCase(),
            );

      if (response.containsKey("access")) {
        await StorageService.saveToken(response["access"]);
        if (response.containsKey("refresh")) {
          await StorageService.saveRefreshToken(response["refresh"]);
        }

        final role = isLogin
            ? (await AuthService.getCurrentUser())['role']
            : selectedRole.toLowerCase();

        await StorageService.saveRole(role);

        if (!mounted) return;

        if (!isLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const EmailVerificationScreen(),
            ),
          );
          return;
        }

        final userInfo = await AuthService.getCurrentUser();
        final emailVerified = userInfo['email_verified'] ?? false;

        if (!emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const EmailVerificationScreen(),
            ),
          );
        } else if (role == 'driver') {
          final token = await StorageService.getToken();

          try {
            final docsResponse = await http.get(
              Uri.parse(
                  "${StorageService.baseUrl}/accounts/driver/documents/"),
              headers: {"Authorization": "Bearer $token"},
            );

            if (docsResponse.statusCode == 200) {
              final docsData = jsonDecode(docsResponse.body);
              final hasUploaded =
                  docsData['documents_uploaded']['national_id'] ?? false;

              if (!hasUploaded) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverDocumentUploadScreen(),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigation(),
                  ),
                );
              }
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainNavigation(),
                ),
              );
            }
          } catch (e) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MainNavigation(),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainNavigation(),
            ),
          );
        }
      } else {
        throw Exception("Authentication failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Illustration Header ──
              Container(
                height: size.height * 0.35,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF87CEEB), // Sky blue
                      Color(0xFFB0E0E6), // Powder blue
                      Color(0xFFE0F6FF), // Very light blue
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Logo at top
                    Positioned(
                      top: 16,
                      left: 20,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "iS",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "iShare",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // "Log In" or "Register" text
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          isLogin ? "Log In" : "Register",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ),

                    // Illustration (emoji placeholder)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          "🚗",
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form Card ──
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLogin ? "Log In" : "Create Account",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Form fields
                        if (!isLogin) ...[
                          _buildTextField(
                            hint: "Username",
                            icon: Icons.person_outline,
                            controller: usernameController,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildTextField(
                          hint: "Email",
                          icon: Icons.email_outlined,
                          controller: emailController,
                        ),

                        const SizedBox(height: 16),

                        if (!isLogin) ...[
                          _buildTextField(
                            hint: "Phone",
                            icon: Icons.phone_outlined,
                            controller: phoneController,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildTextField(
                          hint: "Password",
                          icon: Icons.lock_outline,
                          controller: passwordController,
                          isPassword: true,
                          showForgot: isLogin,
                        ),

                        const SizedBox(height: 24),

                        // Role selector for register
                        if (!isLogin) ...[
                          _buildRoleSelector(),
                          const SizedBox(height: 24),
                        ],

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isLogin ? "Log In" : "Register",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Switch to Login/Register
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                text: isLogin
                                    ? "Don't have an account?  "
                                    : "Already have an account?  ",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: isLogin ? "Sign Up" : "Log In",
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool showForgot = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword ? isHidden : false,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "$hint is required";
            }
            if (hint == "Email" && !value.contains("@")) {
              return "Enter valid email";
            }
            if (hint == "Password" && value.length < 6) {
              return "Password must be at least 6 characters";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isHidden = !isHidden;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (showForgot) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset coming soon!")),
                );
              },
              child: const Text(
                "Forgot password?",
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(child: _roleCard("Passenger", Icons.person_outline)),
        const SizedBox(width: 12),
        Expanded(child: _roleCard("Driver", Icons.directions_car)),
      ],
    );
  }

  Widget _roleCard(String role, IconData icon) {
    bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}