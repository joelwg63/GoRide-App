import 'package:flutter/material.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Trip History"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          tripCard(
            "Westlands",
            "JKIA Airport",
            "KES 1,250",
            "Completed",
            Colors.green,
          ),

          tripCard("Karen", "CBD", "KES 850", "Completed", Colors.green),

          tripCard("Nakuru", "Nairobi", "KES 5,500", "Cancelled", Colors.red),
        ],
      ),
    );
  }

  Widget tripCard(
    String pickup,
    String destination,
    String amount,
    String status,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.route, color: color),
        title: Text("$pickup → $destination"),
        subtitle: Text(status),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
