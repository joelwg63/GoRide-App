import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0;
  }

  int countByStatus(List<QueryDocumentSnapshot> docs, String status) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data["status"] == status;
    }).length;
  }

  double sumField(List<QueryDocumentSnapshot> docs, String field) {
    double total = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += toDouble(data[field]);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("GoRide Admin"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ride_requests")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, rideSnapshot) {
          if (!rideSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = rideSnapshot.data!.docs;

          final pending = countByStatus(rides, "pending");
          final accepted = countByStatus(rides, "accepted");
          final arrived = countByStatus(rides, "arrived");
          final inProgress = countByStatus(rides, "in_progress");
          final completed = countByStatus(rides, "completed");
          final rejected = countByStatus(rides, "rejected");

          final baseFareTotal = sumField(rides, "baseFare");
          final waitingTotal = sumField(rides, "waitingExtraFare");
          final parkingTotal = sumField(rides, "parkingFee");
          final tollTotal = sumField(rides, "tollFee");
          final totalRevenue = sumField(rides, "totalFare");

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  "🛠 ADMIN APP",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const Text(
                  "GoRide",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const Text(
                  "Manage trips • Drivers • Charges",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: summaryCard(
                        "Requests",
                        rides.length.toString(),
                        Icons.receipt_long,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: summaryCard(
                        "Completed",
                        completed.toString(),
                        Icons.check_circle,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: summaryCard(
                        "Pending",
                        pending.toString(),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: summaryCard(
                        "Accepted",
                        accepted.toString(),
                        Icons.person_pin_circle,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: summaryCard(
                        "Arrived",
                        arrived.toString(),
                        Icons.location_on,
                        Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: summaryCard(
                        "Rejected",
                        rejected.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                chargeBox(
                  baseFareTotal: baseFareTotal,
                  waitingTotal: waitingTotal,
                  parkingTotal: parkingTotal,
                  tollTotal: tollTotal,
                  totalRevenue: totalRevenue,
                ),

                const SizedBox(height: 15),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Live Trip Monitoring",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final data = rides[index].data() as Map<String, dynamic>;

                    return tripCard(data);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget chargeBox({
    required double baseFareTotal,
    required double waitingTotal,
    required double parkingTotal,
    required double tollTotal,
    required double totalRevenue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Revenue & Charges",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          chargeLine("Base Fare", baseFareTotal),
          chargeLine("Waiting Charges", waitingTotal),
          chargeLine("Parking Charges", parkingTotal),
          chargeLine("Toll Charges", tollTotal),

          const Divider(),

          chargeLine("Total Revenue", totalRevenue, big: true),
        ],
      ),
    );
  }

  Widget chargeLine(String label, double value, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "KES ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: big ? 20 : 14,
              fontWeight: big ? FontWeight.bold : FontWeight.normal,
              color: big ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget tripCard(Map<String, dynamic> data) {
    final customer = data["customerName"] ?? "Customer";
    final driver =
        data["driverName"] ?? data["assignedDriverName"] ?? "Not accepted";
    final pickup = data["pickup"] ?? "Unknown";
    final destination = data["destination"] ?? "Unknown";
    final category = data["selectedVehicleCategory"] ?? "Ride";
    final status = data["status"] ?? "pending";

    final distance = toDouble(data["distanceKm"]);
    final baseFare = toDouble(data["baseFare"] ?? data["fare"]);
    final waitingExtra = toDouble(data["waitingExtraFare"]);
    final parking = toDouble(data["parkingFee"]);
    final toll = toDouble(data["tollFee"]);
    final total = toDouble(data["totalFare"] ?? data["fare"]);

    final waitingMinutes = data["waitingMinutes"] ?? 0;
    final chargeableWaitingMinutes = data["chargeableWaitingMinutes"] ?? 0;
    final eta = data["driverEtaMinutes"] ?? 0;
    final driverDistance = toDouble(data["driverDistanceToPickupKm"]);
    final movement = data["driverMovementStatus"] ?? "";
    final notice = data["customerNotice"] ?? "";

    Color statusColor = Colors.orange;
    if (status == "accepted") statusColor = Colors.blue;
    if (status == "arrived") statusColor = Colors.purple;
    if (status == "in_progress") statusColor = Colors.green;
    if (status == "completed") statusColor = Colors.black;
    if (status == "rejected") statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$category • ${status.toUpperCase()}",
              style: TextStyle(
                fontSize: 15,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            compactLine("Customer", customer),
            compactLine("Driver", driver),
            compactLine("Pickup", pickup),
            compactLine("Destination", destination),
            compactLine("Distance", "${distance.toStringAsFixed(1)} KM"),

            if (movement.toString().isNotEmpty)
              compactLine("Movement", movement),

            if (eta > 0 || driverDistance > 0)
              compactLine(
                "Driver ETA",
                "$eta min • ${driverDistance.toStringAsFixed(1)} KM away",
              ),

            const Divider(),

            compactLine("Base Fare", "KES ${baseFare.toStringAsFixed(0)}"),
            compactLine("Waiting Time", "$waitingMinutes min"),
            compactLine("Chargeable Waiting", "$chargeableWaitingMinutes min"),
            compactLine(
              "Waiting Fee",
              "KES ${waitingExtra.toStringAsFixed(0)}",
            ),
            compactLine("Parking Fee", "KES ${parking.toStringAsFixed(0)}"),
            compactLine("Toll Fee", "KES ${toll.toStringAsFixed(0)}"),

            const SizedBox(height: 5),

            Text(
              "Total: KES ${total.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            if (notice.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                notice,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget compactLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "$label: $value",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
