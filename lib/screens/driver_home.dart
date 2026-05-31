import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final String driverId = "demo_driver_001";
  final String driverName = "John Driver";

  bool isOnline = false;
  bool loading = false;

  final double waitingChargePerMinute = 30;
  final int freeWaitingMinutes = 5;

  Future<void> updateDriverStatus(bool online) async {
    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("drivers").doc(driverId).set({
      "driverId": driverId,
      "name": driverName,
      "online": online,
      "status": online ? "online" : "offline",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      isOnline = online;
      loading = false;
    });
  }

  Future<void> acceptRide(String requestId, double fare) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "status": "accepted",
          "driverId": driverId,
          "driverName": driverName,
          "acceptedAt": FieldValue.serverTimestamp(),
          "baseFare": fare,
          "waitingFreeMinutes": freeWaitingMinutes,
          "waitingChargePerMinute": waitingChargePerMinute,
          "waitingMinutes": 0,
          "waitingExtraFare": 0,
          "parkingFee": 0,
          "tollFee": 0,
          "totalFare": fare,
          "driverDistanceToPickupKm": 3.5,
          "driverEtaMinutes": 8,
          "driverCurrentArea": "Near pickup route",
          "driverMovementStatus": "Driver is heading to pickup",
          "customerNotice":
              "Driver accepted your ride. Please be ready at pickup.",
        });
  }

  Future<void> markArrived(String requestId) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "status": "arrived",
          "arrivedAt": FieldValue.serverTimestamp(),
          "waitingStartedAt": FieldValue.serverTimestamp(),
          "driverDistanceToPickupKm": 0,
          "driverEtaMinutes": 0,
          "driverMovementStatus": "Driver has arrived at pickup",
          "customerNotice":
              "Driver has arrived. You have 5 free waiting minutes. Extra charges apply after 5 minutes.",
        });
  }

  Future<void> startTrip(String requestId, Map<String, dynamic> ride) async {
    final Timestamp? waitingStartedAt = ride["waitingStartedAt"];
    int waitingMinutes = 0;

    if (waitingStartedAt != null) {
      waitingMinutes = DateTime.now()
          .difference(waitingStartedAt.toDate())
          .inMinutes;
    }

    final int chargeableMinutes = waitingMinutes > freeWaitingMinutes
        ? waitingMinutes - freeWaitingMinutes
        : 0;

    final double waitingExtraFare = chargeableMinutes * waitingChargePerMinute;
    final double baseFare = (ride["baseFare"] ?? ride["fare"] ?? 0).toDouble();
    final double parkingFee = (ride["parkingFee"] ?? 0).toDouble();
    final double tollFee = (ride["tollFee"] ?? 0).toDouble();
    final double totalFare = baseFare + waitingExtraFare + parkingFee + tollFee;

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "status": "in_progress",
          "tripStartedAt": FieldValue.serverTimestamp(),
          "waitingMinutes": waitingMinutes,
          "chargeableWaitingMinutes": chargeableMinutes,
          "waitingExtraFare": waitingExtraFare,
          "totalFare": totalFare,
          "driverMovementStatus": "Trip is in progress",
          "customerNotice":
              "Trip started. Final fare may include waiting, parking, or toll fees.",
        });
  }

  Future<void> completeTrip(String requestId, Map<String, dynamic> ride) async {
    final double totalFare = (ride["totalFare"] ?? ride["fare"] ?? 0)
        .toDouble();

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "status": "completed",
          "completedAt": FieldValue.serverTimestamp(),
          "finalFare": totalFare,
          "driverMovementStatus": "Trip completed",
          "customerNotice":
              "Trip completed. Final fare: KES ${totalFare.toStringAsFixed(0)}",
        });
  }

  Future<void> addParking(String requestId, Map<String, dynamic> ride) async {
    final double baseFare = (ride["baseFare"] ?? ride["fare"] ?? 0).toDouble();
    final double waitingExtraFare = (ride["waitingExtraFare"] ?? 0).toDouble();
    final double tollFee = (ride["tollFee"] ?? 0).toDouble();
    final double newParking = (ride["parkingFee"] ?? 0).toDouble() + 100;

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "parkingFee": newParking,
          "totalFare": baseFare + waitingExtraFare + tollFee + newParking,
          "customerNotice": "Parking fee added to your trip cost.",
        });
  }

  Future<void> addToll(String requestId, Map<String, dynamic> ride) async {
    final double baseFare = (ride["baseFare"] ?? ride["fare"] ?? 0).toDouble();
    final double waitingExtraFare = (ride["waitingExtraFare"] ?? 0).toDouble();
    final double parkingFee = (ride["parkingFee"] ?? 0).toDouble();
    final double newToll = (ride["tollFee"] ?? 0).toDouble() + 100;

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "tollFee": newToll,
          "totalFare": baseFare + waitingExtraFare + parkingFee + newToll,
          "customerNotice": "Toll fee added to your trip cost.",
        });
  }

  Future<void> rejectRide(String requestId) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "status": "rejected",
          "rejectedBy": driverId,
          "rejectedAt": FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("GoRide Driver"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: isOnline ? Colors.green : Colors.red,
            child: Column(
              children: [
                Text(
                  isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isOnline
                      ? "Ready to receive one assigned ride"
                      : "Tap GO ONLINE to receive rides",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnline ? Colors.red : Colors.green,
                ),
                onPressed: loading ? null : () => updateDriverStatus(!isOnline),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isOnline ? "GO OFFLINE" : "GO ONLINE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          Expanded(
            child: !isOnline
                ? const Center(
                    child: Text(
                      "You are offline.\nGo online to receive ride requests.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("ride_requests")
                        .where("assignedDriverId", isEqualTo: driverId)
                        .where(
                          "status",
                          whereIn: [
                            "pending",
                            "accepted",
                            "arrived",
                            "in_progress",
                          ],
                        )
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No assigned ride request yet",
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      final doc = snapshot.data!.docs.first;
                      final ride = doc.data() as Map<String, dynamic>;
                      return buildRideCard(doc.id, ride);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildRideCard(String requestId, Map<String, dynamic> ride) {
    final String status = ride["status"] ?? "pending";
    final String customer = ride["customerName"] ?? "Customer";
    final String pickup = ride["pickup"] ?? "Unknown";
    final String destination = ride["destination"] ?? "Unknown";
    final String category = ride["selectedVehicleCategory"] ?? "Ride";

    final double distance = (ride["distanceKm"] ?? 0).toDouble();
    final double baseFare = (ride["baseFare"] ?? ride["fare"] ?? 0).toDouble();
    final double waitingExtraFare = (ride["waitingExtraFare"] ?? 0).toDouble();
    final double parkingFee = (ride["parkingFee"] ?? 0).toDouble();
    final double tollFee = (ride["tollFee"] ?? 0).toDouble();
    final double totalFare =
        (ride["totalFare"] ??
                baseFare + waitingExtraFare + parkingFee + tollFee)
            .toDouble();

    final int waitingMinutes = ride["waitingMinutes"] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Card(
        color: Colors.orange,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status: ${status.toUpperCase()}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              info("Customer", customer),
              info("Pickup", pickup),
              info("Destination", destination),
              info("Category", category),
              info("Distance", "${distance.toStringAsFixed(1)} KM"),
              const Divider(color: Colors.white),

              charge("Base Fare", baseFare),
              charge("Waiting Extra", waitingExtraFare),
              charge("Parking", parkingFee),
              charge("Toll", tollFee),
              charge("Total Fare", totalFare, big: true),

              const SizedBox(height: 6),
              Text(
                "Waiting: $waitingMinutes min | Free: $freeWaitingMinutes min",
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 12),

              if (status == "pending")
                rowButtons(
                  "ACCEPT",
                  Colors.green,
                  () => acceptRide(requestId, baseFare),
                  "REJECT",
                  Colors.red,
                  () => rejectRide(requestId),
                ),

              if (status == "accepted")
                fullButton(
                  "I HAVE ARRIVED AT PICKUP",
                  Colors.green,
                  () => markArrived(requestId),
                ),

              if (status == "arrived")
                fullButton(
                  "START TRIP",
                  Colors.blue,
                  () => startTrip(requestId, ride),
                ),

              if (status == "in_progress") ...[
                rowButtons(
                  "ADD PARKING",
                  Colors.purple,
                  () => addParking(requestId, ride),
                  "ADD TOLL",
                  Colors.brown,
                  () => addToll(requestId, ride),
                ),
                const SizedBox(height: 8),
                fullButton(
                  "COMPLETE TRIP",
                  Colors.green,
                  () => completeTrip(requestId, ride),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget info(String label, String value) {
    return Text(
      "$label: $value",
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Widget charge(String label, double value, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text(
          "KES ${value.toStringAsFixed(0)}",
          style: TextStyle(
            color: Colors.white,
            fontSize: big ? 19 : 14,
            fontWeight: big ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget fullButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget rowButtons(
    String leftText,
    Color leftColor,
    VoidCallback leftAction,
    String rightText,
    Color rightColor,
    VoidCallback rightAction,
  ) {
    return Row(
      children: [
        Expanded(child: fullButton(leftText, leftColor, leftAction)),
        const SizedBox(width: 8),
        Expanded(child: fullButton(rightText, rightColor, rightAction)),
      ],
    );
  }
}
