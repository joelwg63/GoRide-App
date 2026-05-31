import 'package:flutter/material.dart';

class DriverFoundScreen extends StatelessWidget {
  const DriverFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Found"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          "Driver Found!\nYour ride is on the way.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
