import 'package:flutter/material.dart';
import 'customer_home.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("GoRide Login"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Image.asset(
              'assets/images/goride_logo.png',
              height: 140,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 15),

            const Text(
              "GoRide",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const Text(
              "Your Ride, Your Way",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 30),

            const TextField(
              decoration: InputDecoration(
                labelText: "Email or Phone",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerHome(),
                    ),
                  );
                },
                child: const Text("Login", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
