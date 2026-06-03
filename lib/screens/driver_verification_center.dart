import 'package:flutter/material.dart';

class DriverVerificationCenter extends StatelessWidget {
  const DriverVerificationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Driver Verification Center"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Pending Driver Applications",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          verificationCard(
            "John Mwangi",
            "Driver",
            "Pending Review",
            Colors.orange,
          ),
          verificationCard("David Ouma", "Chauffeur", "Approved", Colors.green),
          verificationCard("Peter Kariuki", "Driver", "Rejected", Colors.red),
        ],
      ),
    );
  }

  Widget verificationCard(
    String name,
    String type,
    String status,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text("$type • $status"),
        trailing: ElevatedButton(onPressed: () {}, child: const Text("Review")),
      ),
    );
  }
}
