import 'package:flutter/material.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("GoRide Super Admin"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "GO RIDE OWNER CONTROL CENTER",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Full platform control • Finance • Security • Users",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: dashboardCard(
                    "Customers",
                    "All",
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dashboardCard(
                    "Drivers",
                    "All",
                    Icons.drive_eta,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: dashboardCard(
                    "Admins",
                    "Full Control",
                    Icons.admin_panel_settings,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dashboardCard(
                    "Finance",
                    "Owner Only",
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            sectionTitle("User Management"),
            actionTile(
              context,
              "Manage All Customers",
              "View, suspend, reactivate, fraud control",
              Icons.people,
              Colors.green,
            ),
            actionTile(
              context,
              "Manage All Drivers",
              "Approve, suspend, force offline, view earnings",
              Icons.drive_eta,
              Colors.blue,
            ),
            actionTile(
              context,
              "Manage Chauffeur Drivers",
              "Approve/reject chauffeur professionals",
              Icons.badge,
              Colors.teal,
            ),

            const SizedBox(height: 15),

            sectionTitle("Admin Staff Management"),
            actionTile(
              context,
              "Create Admin",
              "Assign unique GoRide Job Card Number",
              Icons.person_add,
              Colors.green,
            ),
            actionTile(
              context,
              "Suspend Admin",
              "Block admin access immediately",
              Icons.block,
              Colors.red,
            ),
            actionTile(
              context,
              "Admin Activity Logs",
              "See every admin action and data view",
              Icons.history,
              Colors.black,
            ),

            const SizedBox(height: 15),

            sectionTitle("Financial Control - Super Admin Only"),
            actionTile(
              context,
              "All Income",
              "Customer payments, card, M-Pesa, Binance, cash reports",
              Icons.trending_up,
              Colors.green,
            ),
            actionTile(
              context,
              "Outgoing Payments",
              "Driver payouts, refunds, expenses",
              Icons.trending_down,
              Colors.red,
            ),
            actionTile(
              context,
              "Driver Withdrawals",
              "Approve/reject driver withdrawal requests",
              Icons.payments,
              Colors.blue,
            ),
            actionTile(
              context,
              "Commission Settings",
              "Change GoRide commission percentage",
              Icons.percent,
              Colors.purple,
            ),
            actionTile(
              context,
              "Promotion Budget Control",
              "Approve discounts and driver rewards",
              Icons.discount,
              Colors.orange,
            ),

            const SizedBox(height: 15),

            sectionTitle("Security & Data Protection"),
            actionTile(
              context,
              "Data Access Requests",
              "Court order + Super Admin approval required",
              Icons.privacy_tip,
              Colors.deepOrange,
            ),
            actionTile(
              context,
              "Audit Logs",
              "Every sensitive action is recorded",
              Icons.fact_check,
              Colors.black,
            ),
            actionTile(
              context,
              "Face Confirmation",
              "Required for sensitive owner actions",
              Icons.face,
              Colors.teal,
            ),
            actionTile(
              context,
              "Fingerprint Confirmation",
              "Extra biometric owner security",
              Icons.fingerprint,
              Colors.indigo,
            ),
            actionTile(
              context,
              "Screen Protection Policy",
              "No print/export/screenshot for admins",
              Icons.no_photography,
              Colors.red,
            ),

            const SizedBox(height: 15),

            sectionTitle("Operations Command"),
            actionTile(
              context,
              "Driver Verification Center",
              "Review and approve driver documents",
              Icons.verified_user,
              Colors.green,
            ),
            actionTile(
              context,
              "SOS Command Center",
              "Monitor customer and driver emergency alerts",
              Icons.sos,
              Colors.red,
            ),
            actionTile(
              context,
              "Pricing Rules",
              "Manage fares, waiting, toll, parking, dead mileage",
              Icons.price_change,
              Colors.blue,
            ),
            actionTile(
              context,
              "Country Settings",
              "Manage country codes and international launch",
              Icons.public,
              Colors.green,
            ),
            actionTile(
              context,
              "System Settings",
              "Global GoRide app controls",
              Icons.settings,
              Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget actionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showMessage(context, "$title will be connected next.");
        },
      ),
    );
  }
}
