import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("GoRide Wallet"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          walletCard(
            "Available Balance",
            "KES 0",
            Icons.account_balance_wallet,
            Colors.green,
          ),
          walletCard("Commission Due", "KES 0", Icons.money_off, Colors.red),
          walletCard(
            "Tips Received",
            "KES 0",
            Icons.card_giftcard,
            Colors.orange,
          ),
          walletCard(
            "Pending Settlement",
            "KES 0",
            Icons.pending_actions,
            Colors.blue,
          ),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: () {}, child: const Text("Withdraw Money")),

          ElevatedButton(
            onPressed: () {},
            child: const Text("Pay GoRide Balance"),
          ),
        ],
      ),
    );
  }

  Widget walletCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
