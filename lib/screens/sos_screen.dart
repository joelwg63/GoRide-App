import 'package:flutter/material.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text("GoRide SOS"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.sos, size: 120, color: Colors.red),

            const SizedBox(height: 20),

            const Text(
              "Emergency Assistance",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Press the SOS button only in emergencies. "
              "GoRide Safety Team and Admin will be notified.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {},
                child: const Text(
                  "SEND SOS ALERT",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.local_police),
                title: const Text("Police Emergency"),
                subtitle: const Text("999 / 112"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text("GoRide Safety Team"),
                subtitle: const Text("24/7 Support"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
