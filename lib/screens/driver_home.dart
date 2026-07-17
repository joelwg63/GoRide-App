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
  final String driverPhone = "0712345678";

  // Change this driver type for testing:
  // Car, EV, Bike, EV Bike, XL, Van, Chauffeur
  final String driverType = "Car";

  bool isOnline = false;
  bool loading = false;

  double walletBalance = 0;
  double commissionDue = 0;
  double todayEarnings = 0;
  double tipsReceived = 0;
  bool suspended = false;

  final double commissionPercent = 18;
  final double suspensionLimit = 500;
  final double waitingChargePerMinute = 30;
  final int freeWaitingMinutes = 5;

  final TextEditingController customerCommentController =
      TextEditingController();

  @override
  void dispose() {
    customerCommentController.dispose();
    super.dispose();
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  bool isChauffeurRide(Map<String, dynamic> ride) {
    return ride["requestedDriverType"] == "Chauffeur" ||
        ride["serviceGroup"] == "Chauffeur";
  }

  bool canDriverReceive(Map<String, dynamic> ride) {
    final requested = (ride["requestedDriverType"] ?? "").toString();
    final serviceGroup = (ride["serviceGroup"] ?? "").toString();

    if (driverType == requested) return true;

    if (driverType == "Car" && requested == "EV") return true;
    if (driverType == "Car" && requested == "Car") return true;

    if (driverType == "Bike" && requested == "Bike") return true;
    if (driverType == "Bike" && requested == "EV Bike") return true;

    if (serviceGroup == "Food/Parcel") {
      if (driverType == requested) return true;
      if (requested == "Bike" && driverType == "Car") return true;
      if (requested == "Car" && driverType == "XL") return true;
    }

    return false;
  }

  Future<void> updateDriverStatus(bool online) async {
    if (commissionDue > suspensionLimit) {
      setState(() => suspended = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are suspended. Pay GoRide balance first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("drivers").doc(driverId).set({
      "driverId": driverId,
      "name": driverName,
      "phone": driverPhone,
      "driverType": driverType,
      "online": online,
      "status": online ? "online" : "offline",
      "walletBalance": walletBalance,
      "commissionDue": commissionDue,
      "todayEarnings": todayEarnings,
      "tipsReceived": tipsReceived,
      "suspended": suspended,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      isOnline = online;
      loading = false;
    });
  }

  Future<void> acceptRide(String requestId, Map<String, dynamic> ride) async {
    final double estimatedFare = toDouble(
      ride["estimatedFareVisibleToCustomer"] ??
          ride["estimatedFareHiddenFromCustomer"] ??
          ride["estimatedFareBeforeDriverAccept"] ??
          ride["customerPayableFare"] ??
          ride["fare"] ??
          ride["originalFare"],
    );

    final double confirmedFare = estimatedFare;
    final double commissionAmount = confirmedFare * commissionPercent / 100;
    final double driverNetEarnings = confirmedFare - commissionAmount;

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
      "status": "accepted",
      "assignedDriverId": driverId,
      "assignedDriverName": driverName,
      "driverId": driverId,
      "driverName": driverName,
      "driverPhone": driverPhone,
      "driverType": driverType,
      "driverCanViewCustomerDetails": true,
      "customerCanViewDriverDetails": true,
      "acceptedAt": FieldValue.serverTimestamp(),
      "driverEtaMinutes": ride["serviceEtaMinutes"] ?? 5,
      "driverDistanceToPickupKm": 3.5,
      "confirmedFare": confirmedFare,
      "customerPayableFare": confirmedFare,
      "totalFare": confirmedFare,
      "fareConfirmed": true,
      "appCommissionPercent": commissionPercent,
      "appCommissionAmount": commissionAmount,
      "driverNetEarnings": driverNetEarnings,
      "driverMovementStatus": "Driver accepted and is heading to pickup",
      "customerNotice":
          "Driver accepted. Confirmed fare is KES ${confirmedFare.toStringAsFixed(0)}. Please prepare before driver arrives.",
    });
  }

  Future<void> rejectRide(String requestId) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
      "status": "rejected",
      "rejectedBy": driverId,
      "targetDriverId": "",
      "rejectedAt": FieldValue.serverTimestamp(),
      "customerNotice":
          "Driver rejected request. GoRide is searching another nearby driver.",
      "driverMovementStatus": "Searching another nearby driver",
    });
  }

  Future<void> markArrived(String requestId, Map<String, dynamic> ride) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
      "status": "arrived",
      "arrivedAt": FieldValue.serverTimestamp(),
      "waitingStartedAt": FieldValue.serverTimestamp(),
      "driverEtaMinutes": 0,
      "driverDistanceToPickupKm": 0,
      "driverMovementStatus": "Driver arrived at pickup",
      "customerNotice":
          "Driver has arrived. You have 5 free waiting minutes.",
    });
  }

  Future<void> startTrip(String requestId) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
      "status": "in_progress",
      "tripStartedAt": FieldValue.serverTimestamp(),
      "driverMovementStatus": "Trip is in progress",
      "customerNotice": "Your trip has started.",
    });
  }

  Future<void> completeTrip(String requestId, Map<String, dynamic> ride) async {
    final String paymentMethod = ride["paymentMethod"] ?? "Cash";

    final double confirmedFare = toDouble(
      ride["confirmedFare"] ??
          ride["customerPayableFare"] ??
          ride["estimatedFareVisibleToCustomer"],
    );

    final Timestamp? waitingStartedAt = ride["waitingStartedAt"];
    int waitingMinutes = 0;

    if (waitingStartedAt != null) {
      waitingMinutes =
          DateTime.now().difference(waitingStartedAt.toDate()).inMinutes;
    }

    final int chargeableWaitingMinutes =
        waitingMinutes > freeWaitingMinutes ? waitingMinutes - freeWaitingMinutes : 0;

    final double waitingFee = chargeableWaitingMinutes * waitingChargePerMinute;
    final double finalFare = confirmedFare + waitingFee;

    final double commissionAmount = finalFare * commissionPercent / 100;
    final double driverNetEarnings = finalFare - commissionAmount;

    double newWalletBalance = walletBalance;
    double newCommissionDue = commissionDue;

    if (paymentMethod == "Cash" || paymentMethod == "M-Pesa") {
      newCommissionDue += commissionAmount;
      newWalletBalance -= commissionAmount;
    } else {
      newWalletBalance += driverNetEarnings;
    }

    final bool shouldSuspend = newCommissionDue > suspensionLimit;

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
      "status": "completed",
      "completedAt": FieldValue.serverTimestamp(),
      "waitingMinutes": waitingMinutes,
      "chargeableWaitingMinutes": chargeableWaitingMinutes,
      "waitingFee": waitingFee,
      "originalTotalFare": finalFare,
      "customerPayableFare": finalFare,
      "confirmedFare": finalFare,
      "totalFare": finalFare,
      "appCommissionPercent": commissionPercent,
      "appCommissionAmount": commissionAmount,
      "driverNetEarnings": driverNetEarnings,
      "driverWalletBalanceAfterTrip": newWalletBalance,
      "driverCommissionDueAfterTrip": newCommissionDue,
      "driverMovementStatus": "Trip completed",
      "customerNotice":
          "Trip completed. Final amount: KES ${finalFare.toStringAsFixed(0)}",
    });

    await FirebaseFirestore.instance.collection("drivers").doc(driverId).set({
      "walletBalance": newWalletBalance,
      "commissionDue": newCommissionDue,
      "todayEarnings": todayEarnings + driverNetEarnings,
      "suspended": shouldSuspend,
      "online": shouldSuspend ? false : isOnline,
      "status": shouldSuspend ? "suspended" : "online",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      walletBalance = newWalletBalance;
      commissionDue = newCommissionDue;
      todayEarnings += driverNetEarnings;
      suspended = shouldSuspend;
      if (shouldSuspend) isOnline = false;
    });
  }

  void callCustomer(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Call customer: $phone")),
    );
  }

  void openSOS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SOS alert sent to GoRide Admin."),
        backgroundColor: Colors.red,
      ),
    );
  }

  void withdrawMoney() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Withdrawal request sent."),
      ),
    );
  }

  void payGoRideBalance() {
    setState(() {
      commissionDue = 0;
      walletBalance = 0;
      suspended = false;
    });

    FirebaseFirestore.instance.collection("drivers").doc(driverId).set({
      "commissionDue": 0,
      "walletBalance": 0,
      "suspended": false,
      "status": "offline",
      "online": false,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      body: Column(
        children: [
          driverStatusHeader(),
          walletCard(),
          Expanded(child: rideRequestArea()),
        ],
      ),
    );
  }

  Widget driverStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: suspended
          ? Colors.black
          : isOnline
              ? Colors.green
              : Colors.red,
      child: Column(
        children: [
          Text(
            suspended
                ? "SUSPENDED"
                : isOnline
                    ? "YOU ARE ONLINE"
                    : "YOU ARE OFFLINE",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Driver Type: $driverType",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline ? Colors.red : Colors.green,
                  ),
                  onPressed: loading ? null : () => updateDriverStatus(!isOnline),
                  child: Text(
                    isOnline ? "GO OFFLINE" : "GO ONLINE",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: openSOS,
                child: const Text("SOS", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget walletCard() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "Driver Wallet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            walletLine("Wallet Balance", walletBalance),
            walletLine("Commission Due", -commissionDue),
            walletLine("Today Earnings", todayEarnings),
            walletLine("Tips Received", tipsReceived),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: withdrawMoney,
                    child: const Text("Withdraw"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: payGoRideBalance,
                    child: const Text(
                      "Pay Balance",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget rideRequestArea() {
    if (!isOnline) {
      return Center(
        child: Text(
          suspended
              ? "Suspended: Pay GoRide balance first."
              : "You are offline.\nGo online to receive matching request.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("ride_requests")
          .orderBy("createdAt", descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final ride = doc.data() as Map<String, dynamic>;

          final String status = ride["status"] ?? "";
          final String targetDriverId = ride["targetDriverId"] ?? "";
          final String assignedDriverId = ride["assignedDriverId"] ?? "";
          final String rideDriverId = ride["driverId"] ?? "";

          final bool targetedToMe =
              status == "pending" &&
              targetDriverId == driverId &&
              canDriverReceive(ride);

          final bool mine =
              assignedDriverId == driverId || rideDriverId == driverId;

          final bool activeMine = mine &&
              (status == "accepted" ||
                  status == "arrived" ||
                  status == "in_progress" ||
                  status == "completed" ||
                  status == "cancelled_by_customer");

          return targetedToMe || activeMine;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "No $driverType request assigned yet.\nNearest matching customer request will appear here.",
              textAlign: TextAlign.center,
            ),
          );
        }

        final doc = docs.first;
        final ride = doc.data() as Map<String, dynamic>;

        return buildRideCard(doc.id, ride);
      },
    );
  }

  Widget buildRideCard(String requestId, Map<String, dynamic> ride) {
    final String status = ride["status"] ?? "pending";
    final String pickup = ride["pickup"] ?? "";
    final String destination = ride["destination"] ?? "";
    final String category = ride["selectedVehicleCategory"] ?? "Ride";
    final String serviceGroup = ride["serviceGroup"] ?? "";
    final String requestedDriverType = ride["requestedDriverType"] ?? "";
    final String payment = ride["paymentMethod"] ?? "Cash";
    final String customerName = ride["customerName"] ?? "Customer";
    final String customerPhone = ride["customerPhone"] ?? "0700000000";

    final bool acceptedOrLater =
        status != "pending" && status != "rejected" && status != "cancelled_by_customer";

    final bool cancelledByCustomer = status == "cancelled_by_customer";

    final double estimatedFare = toDouble(
      ride["estimatedFareVisibleToCustomer"] ??
          ride["estimatedFareHiddenFromCustomer"],
    );

    final double confirmedFare = toDouble(
      ride["confirmedFare"] ?? ride["customerPayableFare"] ?? ride["totalFare"],
    );

    final int serviceEta = toDouble(ride["serviceEtaMinutes"]).toInt();
    final int capacity = toDouble(ride["serviceCapacity"]).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Card(
        color: cancelledByCustomer
            ? Colors.grey
            : acceptedOrLater
                ? Colors.green
                : Colors.orange,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                cancelledByCustomer
                    ? "CUSTOMER CANCELLED"
                    : "${status.toUpperCase()} REQUEST",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (acceptedOrLater) ...[
                rideLine("Customer", customerName),
                rideLine("Phone", customerPhone),
                fullButton(
                  "CALL CUSTOMER",
                  Colors.black,
                  () => callCustomer(customerPhone),
                ),
                const SizedBox(height: 8),
              ] else
                rideLine("Customer", "Hidden until accepted"),

              rideLine("Pickup", pickup),
              rideLine("Destination", destination),
              rideLine("Group", serviceGroup),
              rideLine("Service", category),
              rideLine("Requested Type", requestedDriverType),
              rideLine("Payment", payment),
              rideLine("ETA", "$serviceEta min"),
              rideLine("Capacity", capacity == 0 ? "Own car" : "$capacity passengers"),

              const Divider(color: Colors.white),

              if (!acceptedOrLater)
                rideLine("Estimated Fare", "KES ${estimatedFare.toStringAsFixed(0)}"),

              if (acceptedOrLater)
                rideLine("Confirmed Fare", "KES ${confirmedFare.toStringAsFixed(0)}"),

              if (ride["isParcel"] == true) ...[
                const Divider(color: Colors.white),
                rideLine("Parcel", ride["parcelAction"] ?? ""),
                rideLine("Transport", ride["parcelTransport"] ?? ""),
                rideLine("Sender", ride["senderName"] ?? ""),
                rideLine("Sender Phone", ride["senderPhone"] ?? ""),
                rideLine("Receiver", ride["receiverName"] ?? ""),
                rideLine("Receiver Phone", ride["receiverPhone"] ?? ""),
                rideLine("Package", ride["parcelDescription"] ?? ""),
                rideLine("Pickup Notes", ride["pickupNotes"] ?? ""),
                rideLine("Drop-off Notes", ride["dropOffNotes"] ?? ""),
              ],

              if (cancelledByCustomer)
                rideLine("Reason", ride["cancelReason"] ?? ""),

              const SizedBox(height: 10),

              if (status == "pending")
                buttonRow(
                  "ACCEPT",
                  Colors.green,
                  () => acceptRide(requestId, ride),
                  "REJECT",
                  Colors.red,
                  () => rejectRide(requestId),
                ),

              if (status == "accepted")
                fullButton(
                  "ARRIVED AT PICKUP",
                  Colors.green,
                  () => markArrived(requestId, ride),
                ),

              if (status == "arrived")
                fullButton(
                  "START TRIP",
                  Colors.blue,
                  () => startTrip(requestId),
                ),

              if (status == "in_progress")
                fullButton(
                  "END TRIP",
                  Colors.green,
                  () => completeTrip(requestId, ride),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget walletLine(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          "KES ${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: value < 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget rideLine(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: Text(
              "$value",
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget fullButton(String text, Color color, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: action,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget buttonRow(
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