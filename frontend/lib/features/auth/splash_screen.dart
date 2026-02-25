import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_screen.dart';
import '../auth/onboarding_screen.dart';
import '../../core/services/storage_service.dart';
import '../../navigation/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _featuresController;
  late AnimationController _bgController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotate;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _featuresFade;
  late Animation<double> _bgAnimation;
  late Animation<double> _pulseAnimation;

  int _currentFeature = 0;
  Timer? _featureTimer;
  bool _showFeatures = false;

  final List<Map<String, dynamic>> _features = [
  {
    'icon': Icons.route_rounded,
    'title': 'Smart Ride Sharing',
    'subtitle': 'Connect drivers & passengers across Rwanda',
    'color': const Color(0xFF34D399),
    'bg': const Color(0xFF064E3B),
  },
  {
    'icon': Icons.calendar_month_rounded,
    'title': 'Schedule Rides',
    'subtitle': 'Daily, weekend or monthly recurring trips',
    'color': const Color(0xFFFBBF24),
    'bg': const Color(0xFF78350F),
  },
  {
    'icon': Icons.my_location_rounded,
    'title': 'Live Tracking',
    'subtitle': 'Real-time GPS tracking for safety',
    'color': const Color(0xFFF87171),
    'bg': const Color(0xFF7F1D1D),
  },
  {
    'icon': Icons.sos_rounded,
    'title': 'SOS Emergency',
    'subtitle': 'One-tap emergency alerts & contacts',
    'color': const Color(0xFFFF6B6B),
    'bg': const Color(0xFF4C0519),
  },
  {
    'icon': Icons.account_balance_wallet_rounded,
    'title': 'Digital Wallet',
    'subtitle': 'MTN MoMo & Airtel Money payments',
    'color': const Color(0xFF818CF8),
    'bg': const Color(0xFF1E1B4B),
  },
  {
    'icon': Icons.language_rounded,
    'title': '3 Languages',
    'subtitle': 'English • Français • Ikinyarwanda',
    'color': const Color(0xFF38BDF8),
    'bg': const Color(0xFF0C4A6E),
  },
];
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _featuresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _featuresFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeIn),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _contentController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _showFeatures = true);
      _featuresController.forward();
    }

    _featureTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _featuresController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentFeature = (_currentFeature + 1) % _features.length;
            });
            _featuresController.forward();
          }
        });
      }
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    _featureTimer?.cancel();

    final token = await StorageService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const MainNavigation(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else if (!seenOnboarding) {
      await prefs.setBool('onboarding_seen', true);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const AuthScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _featuresController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    _featureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Light blue background matching onboarding ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF60A5FA),
                  Color(0xFF3B82F6),
                  Color(0xFF2563EB),
                ],
              ),
            ),
          ),

          // ── Decorative circles like onboarding ──
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF93C5FD).withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.1,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF93C5FD).withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: size.width * 0.2,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.2),
              ),
            ),
          ),

          // ── Animated sparkles ──
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.35,
                    left: size.width * 0.1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                          0.4 + math.sin(_bgAnimation.value * math.pi * 4) * 0.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.42,
                    right: size.width * 0.12,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                          0.3 + math.cos(_bgAnimation.value * math.pi * 3) * 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildLogo(),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const Spacer(flex: 1),
                      if (_showFeatures) _buildFeatureCard(),
                      const SizedBox(height: 12),
                      _buildStats(),
                      const SizedBox(height: 12),
                      _buildBottom(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _logoFade,
          child: Transform.rotate(
            angle: _logoRotate.value,
            child: ScaleTransition(
              scale: _logoScale,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/home.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
        position: _contentSlide,
        child: Column(
          children: [
            const Text(
              "ISHARE",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 8,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Text(
                "Ride Smart • Ride Together",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
  final feature = _features[_currentFeature];
  final color = feature['color'] as Color;
  final bg = feature['bg'] as Color;

  return FadeTransition(
    opacity: _featuresFade,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              bg.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildStats() {
    return FadeTransition(
      opacity: _contentFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat("🚗", "Drivers", "Easy"),
              Container(width: 1, height: 36, color: Colors.white38),
              _buildStat("👥", "Passengers", "Safe"),
              Container(width: 1, height: 36, color: Colors.white38),
              _buildStat("🇷🇼", "Rwanda", "First"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBottom() {
    return FadeTransition(
      opacity: _contentFade,
      child: Column(
        children: [
          // In _buildBottom(), replace the dots Row with:
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(_features.length, (index) {
    final isActive = index == _currentFeature;
    final dotColor = _features[index]['color'] as Color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: isActive ? dotColor : Colors.white.withOpacity(0.4),
      ),
    );
  }),
),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: _navigate,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Made in Rwanda 🇷🇼",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}