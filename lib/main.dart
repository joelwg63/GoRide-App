import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/customer_home.dart';
import 'screens/driver_home.dart';
import 'screens/admin_home.dart';
import 'screens/super_admin_home.dart';
import 'screens/wallet_screen.dart';
import 'screens/trip_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase startup skipped for now: $e');
  }

  runApp(const GoRideApp());
}

class GoRideApp extends StatelessWidget {
  const GoRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFFFF7FF),
        useMaterial3: true,
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_taxi,
                  color: Colors.green,
                  size: 120,
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'GoRide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Your Ride, Your Way',
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

// ================= MAIN NAVIGATION DEMO =================

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
    SuperAdminHome(),
    AccountScreen(),
  ];

  final List<String> titles = const [
    'GoRide Customer',
    'GoRide Driver',
    'GoRide Admin',
    'GoRide Super Admin',
    'Account',
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Customer'),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: 'Driver'),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Super'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

// ================= ACCOUNT SCREEN =================

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/goride_logo.png',
                height: 110,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.local_taxi,
                    color: Colors.green,
                    size: 80,
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'GoRide Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                'Your Ride, Your Way',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        accountTile(Icons.person, 'Profile', 'Manage your name and phone'),
        accountTile(Icons.payment, 'Payments', 'Cash, M-Pesa, Card, Binance'),
        accountTile(Icons.card_giftcard, 'Promotions', 'Discounts and rewards'),
        accountTile(Icons.security, 'Safety', 'SOS and trusted contacts'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sos, color: Colors.red),
            title: const Text(
              'SOS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Emergency assistance'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => openPage(context, const SosScreen()),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history, color: Colors.green),
            title: const Text(
              'Trip History',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Past and active trips'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => openPage(context, const TripHistoryScreen()),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
            ),
            title: const Text(
              'Wallet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Balance and transactions'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => openPage(context, const WalletScreen()),
          ),
        ),
        accountTile(Icons.support_agent, 'Support', 'Help and complaints'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings, color: Colors.green),
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Language and app settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => openPage(context, const SettingsScreen()),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text(
            'Logout / Back to Login',
            style: TextStyle(color: Colors.white),
          ),
        ),
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