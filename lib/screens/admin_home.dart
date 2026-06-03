import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int countByStatus(List<QueryDocumentSnapshot> docs, String status) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data["status"] == status;
    }).length;
  }

  int countWhere(
    List<QueryDocumentSnapshot> docs,
    bool Function(Map<String, dynamic>) test,
  ) {
    return docs.where((doc) => test(doc.data() as Map<String, dynamic>)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("GoRide Admin"),
        backgroundColor: Colors.green,
        centerTitle: true,
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

          final chauffeurJobs = countWhere(
            rides,
            (data) =>
                data["isChauffeur"] == true ||
                data["serviceType"] == "chauffeur",
          );

          final evTrips = countWhere(rides, (data) => data["isEV"] == true);

          double customerPaidTotal = 0;
          double originalFareTotal = 0;
          double discountTotal = 0;
          double commissionTotal = 0;
          double driverNetTotal = 0;
          double parkingTotal = 0;
          double tollTotal = 0;
          double waitingTotal = 0;
          double deadMileageTotal = 0;
          double tipsTotal = 0;

          for (final doc in rides) {
            final data = doc.data() as Map<String, dynamic>;

            customerPaidTotal += toDouble(
              data["customerPayableFare"] ?? data["totalFare"],
            );
            originalFareTotal += toDouble(
              data["originalTotalFare"] ?? data["originalFare"] ?? data["fare"],
            );
            discountTotal += toDouble(data["gorideCoversDiscount"]);
            commissionTotal += toDouble(data["appCommissionAmount"]);
            driverNetTotal += toDouble(data["driverNetEarnings"]);
            parkingTotal += toDouble(data["parkingFee"]);
            tollTotal += toDouble(data["tollFee"]);
            waitingTotal += toDouble(
              data["waitingFee"] ?? data["waitingExtraFare"],
            );
            deadMileageTotal += toDouble(data["deadMileageFee"]);
            tipsTotal += toDouble(data["customerTipAmount"]);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                header(),
                const SizedBox(height: 12),

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
                        "Active",
                        (accepted + arrived + inProgress).toString(),
                        Icons.directions_car,
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
                        "Chauffeur",
                        chauffeurJobs.toString(),
                        Icons.badge,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: summaryCard(
                        "EV Trips",
                        evTrips.toString(),
                        Icons.electric_car,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: summaryCard(
                        "Rejected",
                        rejected.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: summaryCard(
                        "Arrived",
                        arrived.toString(),
                        Icons.location_on,
                        Colors.deepOrange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                revenueBox(
                  customerPaidTotal: customerPaidTotal,
                  originalFareTotal: originalFareTotal,
                  discountTotal: discountTotal,
                  commissionTotal: commissionTotal,
                  driverNetTotal: driverNetTotal,
                  parkingTotal: parkingTotal,
                  tollTotal: tollTotal,
                  waitingTotal: waitingTotal,
                  deadMileageTotal: deadMileageTotal,
                  tipsTotal: tipsTotal,
                ),

                const SizedBox(height: 15),
                adminActions(context),
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

  Widget header() {
    return Card(
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Image.asset(
              "assets/images/goride_logo.png",
              height: 75,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_taxi,
                  color: Colors.white,
                  size: 65,
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              "GoRide Admin",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Trips • Drivers • Charges • Safety",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
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

  Widget revenueBox({
    required double customerPaidTotal,
    required double originalFareTotal,
    required double discountTotal,
    required double commissionTotal,
    required double driverNetTotal,
    required double parkingTotal,
    required double tollTotal,
    required double waitingTotal,
    required double deadMileageTotal,
    required double tipsTotal,
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
          chargeLine("Original Fare Total", originalFareTotal),
          chargeLine("Customer Paid Total", customerPaidTotal),
          chargeLine("GoRide Discounts", discountTotal),
          chargeLine("Parking", parkingTotal),
          chargeLine("Toll", tollTotal),
          chargeLine("Waiting", waitingTotal),
          chargeLine("Dead Mileage", deadMileageTotal),
          chargeLine("Tips", tipsTotal),
          const Divider(),
          chargeLine("GoRide Commission", commissionTotal, big: true),
          chargeLine("Driver Net Earnings", driverNetTotal, big: true),
        ],
      ),
    );
  }

  Widget adminActions(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Admin Controls",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        adminButton(
          context,
          "Driver Documents Review",
          Icons.folder_shared,
          Colors.blue,
        ),
        adminButton(
          context,
          "Chauffeur Driver Review",
          Icons.badge,
          Colors.green,
        ),
        adminButton(
          context,
          "Create Customer Discount",
          Icons.discount,
          Colors.green,
        ),
        adminButton(
          context,
          "Reward Drivers",
          Icons.card_giftcard,
          Colors.orange,
        ),
        adminButton(context, "SOS Alerts", Icons.sos, Colors.red),
        adminButton(
          context,
          "Wallet & Commission Reports",
          Icons.account_balance_wallet,
          Colors.purple,
        ),
      ],
    );
  }

  Widget adminButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: const Text("Coming next"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$title coming next")));
        },
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
              fontSize: big ? 18 : 14,
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
    final customerPhone = data["customerPhone"] ?? "";
    final driver =
        data["driverName"] ?? data["assignedDriverName"] ?? "Not accepted";
    final driverPhone = data["driverPhone"] ?? "";

    final pickup = data["pickup"] ?? "Unknown";
    final destination = data["destination"] ?? "Unknown";
    final category = data["selectedVehicleCategory"] ?? "Ride";
    final status = data["status"] ?? "pending";
    final payment = data["paymentMethod"] ?? "Cash";

    final isChauffeur =
        data["isChauffeur"] == true || data["serviceType"] == "chauffeur";
    final isEV = data["isEV"] == true;

    final distance = toDouble(data["distanceKm"]);
    final baseFare = toDouble(
      data["baseTripFare"] ?? data["originalFare"] ?? data["fare"],
    );
    final waiting = toDouble(data["waitingFee"] ?? data["waitingExtraFare"]);
    final parking = toDouble(data["parkingFee"]);
    final toll = toDouble(data["tollFee"]);
    final deadMileage = toDouble(data["deadMileageFee"]);
    final customerPaid = toDouble(
      data["customerPayableFare"] ?? data["totalFare"],
    );
    final originalTotal = toDouble(
      data["originalTotalFare"] ?? data["originalFare"] ?? data["fare"],
    );
    final discount = toDouble(data["gorideCoversDiscount"]);
    final commission = toDouble(data["appCommissionAmount"]);
    final driverNet = toDouble(data["driverNetEarnings"]);
    final tip = toDouble(data["customerTipAmount"]);

    final waitingMinutes = data["waitingMinutes"] ?? 0;
    final chargeableWaitingMinutes = data["chargeableWaitingMinutes"] ?? 0;
    final eta = data["driverEtaMinutes"] ?? 0;
    final driverDistance = toDouble(data["driverDistanceToPickupKm"]);
    final movement = data["driverMovementStatus"] ?? "";
    final notice = data["customerNotice"] ?? "";

    final driverRatingToCustomer = data["driverRatingToCustomer"];
    final driverCommentToCustomer = data["driverCommentToCustomer"];
    final customerRatingToDriver = data["customerRatingToDriver"];
    final customerCommentToDriver = data["customerCommentToDriver"];

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
              "${isEV ? "⚡ " : ""}$category • ${status.toUpperCase()}",
              style: TextStyle(
                fontSize: 15,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isChauffeur)
              const Text(
                "👔 Chauffeur Service",
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            const SizedBox(height: 5),

            compactLine("Customer", customer),
            if (customerPhone.toString().isNotEmpty)
              compactLine("Customer Phone", customerPhone),
            compactLine("Driver", driver),
            if (driverPhone.toString().isNotEmpty)
              compactLine("Driver Phone", driverPhone),
            compactLine("Pickup", pickup),
            compactLine("Destination", destination),
            compactLine("Payment", payment),

            if (!isChauffeur)
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

            if (!isChauffeur) ...[
              compactLine("Waiting Time", "$waitingMinutes min"),
              compactLine(
                "Chargeable Waiting",
                "$chargeableWaitingMinutes min",
              ),
              compactLine("Waiting Fee", "KES ${waiting.toStringAsFixed(0)}"),
              compactLine("Parking", "KES ${parking.toStringAsFixed(0)}"),
              compactLine("Toll", "KES ${toll.toStringAsFixed(0)}"),
              compactLine(
                "Dead Mileage",
                "KES ${deadMileage.toStringAsFixed(0)}",
              ),
            ],

            compactLine(
              "Original Total",
              "KES ${originalTotal.toStringAsFixed(0)}",
            ),
            compactLine(
              "GoRide Discount",
              "KES ${discount.toStringAsFixed(0)}",
            ),
            compactLine(
              "Customer Paid",
              "KES ${customerPaid.toStringAsFixed(0)}",
            ),
            compactLine("Commission", "KES ${commission.toStringAsFixed(0)}"),
            compactLine("Driver Net", "KES ${driverNet.toStringAsFixed(0)}"),

            if (tip > 0)
              compactLine("Customer Tip", "KES ${tip.toStringAsFixed(0)}"),

            const SizedBox(height: 5),

            Text(
              "Admin Total View: KES ${customerPaid.toStringAsFixed(0)}",
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

            if (driverRatingToCustomer != null ||
                customerRatingToDriver != null) ...[
              const Divider(),
              if (driverRatingToCustomer != null)
                compactLine(
                  "Driver rated customer",
                  "$driverRatingToCustomer stars",
                ),
              if ((driverCommentToCustomer ?? "").toString().isNotEmpty)
                compactLine("Driver comment", "$driverCommentToCustomer"),
              if (customerRatingToDriver != null)
                compactLine(
                  "Customer rated driver",
                  "$customerRatingToDriver stars",
                ),
              if ((customerCommentToDriver ?? "").toString().isNotEmpty)
                compactLine("Customer comment", "$customerCommentToDriver"),
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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
