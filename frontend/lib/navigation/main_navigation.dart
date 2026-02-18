import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../features/home/driver_home_screen.dart';
import '../features/home/passenger_home_screen.dart';
import '../features/bookings/my_bookings_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../features/more/more_screen.dart';
import '../core/services/storage_service.dart';
import '../core/services/auth_service.dart';
import '../../core/extensions/translation_extension.dart';
import '../features/rides/driver_ride_management_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  List<Widget> pages = [];
  List<BottomNavigationBarItem> navItems = [];
  bool isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      // Fetch role from backend
      final userInfo = await AuthService.getCurrentUser();
      final role = userInfo['role'];
      
      // Save it for offline access
      await StorageService.saveRole(role);
      
      setState(() {
        userRole = role;
        
        if (role == "driver") {
          // Driver navigation
          pages = [
            const DriverHomeScreen(),
            const DriverRideManagementScreen(),  // ✅ CORRECT - Has accept/reject buttons
            const WalletScreen(),
            const MoreScreen(),
          ];
          
          navItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: "My Rides",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: "More",
            ),
          ];
        } else {
          // Passenger navigation
          pages = [
            PassengerHomeScreen(),
            const MyBookingsScreen(),
            const WalletScreen(),
            const MoreScreen(),
          ];
          
          navItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: "More",
            ),
          ];
        }
        
        isLoading = false;
      });
      
      print("✅ Loaded role from backend: $role");
      
    } catch (e) {
      print("⚠️ Error fetching role from backend: $e");
      
      // Fallback to stored role if backend fails
      final role = await StorageService.getRole();
      
      setState(() {
        userRole = role;
        
        if (role == "driver") {
          pages = [
            const DriverHomeScreen(),
            const MyBookingsScreen(),
            const WalletScreen(),
            const MoreScreen(),
          ];
          
          navItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: "My Rides",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: "More",
            ),
          ];
        } else {
          pages = [
            PassengerHomeScreen(),
            const MyBookingsScreen(),
            const WalletScreen(),
            const MoreScreen(),
          ];
          
          navItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: "More",
            ),
          ];
        }
        
        isLoading = false;
      });
      
      print("✅ Used stored role: $role");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: navItems,
      ),
    );
  }
}