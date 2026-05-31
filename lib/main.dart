import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/customer_home.dart';
import 'screens/driver_home.dart';
import 'screens/admin_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GoRideApp());
}

class GoRideApp extends StatelessWidget {
  const GoRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoRide',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFFFF7FF),
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= SPLASH SCREEN =================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/goride_logo.png',
              height: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              "GoRide",
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Your Ride, Your Way",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= MAIN NAVIGATION =================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    CustomerHome(),
    DriverHome(),
    AdminHome(),
    AccountScreen(),
  ];

  final List<String> titles = const [
    "GoRide Customer",
    "GoRide Driver",
    "GoRide Admin",
    "Account",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Customer"),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: "Driver"),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: "Admin",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

// ================= ACCOUNT SCREEN =================

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Center(
          child: Column(
            children: [
              Image.asset('assets/images/goride_logo.png', height: 110),
              const SizedBox(height: 8),
              const Text(
                "GoRide Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                "Your Ride, Your Way",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        accountTile(Icons.person, "Profile", "Manage your name and phone"),
        accountTile(Icons.payment, "Payments", "Cash, M-Pesa, Card, Binance"),
        accountTile(Icons.card_giftcard, "Promotions", "Discounts and rewards"),
        accountTile(Icons.security, "Safety", "SOS and trusted contacts"),
        accountTile(Icons.location_on, "Saved Places", "Home, work, favorites"),
        accountTile(Icons.history, "My Rides", "Past and active trips"),
        accountTile(Icons.wallet, "Wallet", "Balance and transactions"),
        accountTile(Icons.support_agent, "Support", "Help and complaints"),
        accountTile(Icons.settings, "Settings", "Language and app settings"),
      ],
    );
  }

  Widget accountTile(IconData icon, String title, String subtitle) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
