import 'package:flutter/material.dart';

import 'customer_register_screen.dart';
import 'driver_register_screen.dart';
import 'chauffeur_register_screen.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Create GoRide Account"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 25),

            Image.asset(
              "assets/images/goride_logo.png",
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_taxi,
                  size: 90,
                  color: Colors.green,
                );
              },
            ),

            const SizedBox(height: 15),

            const Text(
              "Join GoRide",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Choose the account type you want to create",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 30),

            choiceCard(
              context,
              icon: Icons.person,
              title: "Register as Customer",
              subtitle: "Book rides, EV rides, bikes and chauffeur services",
              color: Colors.green,
              page: const CustomerRegisterScreen(),
            ),

            choiceCard(
              context,
              icon: Icons.directions_car,
              title: "Register as Driver",
              subtitle: "Drive with your own vehicle and earn with GoRide",
              color: Colors.blue,
              page: const DriverRegisterScreen(),
            ),

            choiceCard(
              context,
              icon: Icons.badge,
              title: "Register as Chauffeur Driver",
              subtitle: "Professional driver for customer-owned cars",
              color: Colors.orange,
              page: const ChauffeurRegisterScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget choiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => openPage(context, page),
      ),
    );
  }
}
