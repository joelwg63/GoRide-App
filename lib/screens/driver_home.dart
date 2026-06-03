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

  final TextEditingController plateController = TextEditingController();
  final TextEditingController customerCommentController =
      TextEditingController();

  @override
  void dispose() {
    plateController.dispose();
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
    return ride["serviceType"] == "chauffeur" || ride["isChauffeur"] == true;
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
    final bool chauffeur = isChauffeurRide(ride);

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
          "driverCanViewCustomerDetails": true,
          "customerCanViewDriverDetails": true,
          "acceptedAt": FieldValue.serverTimestamp(),
          "driverEtaMinutes": chauffeur ? 10 : 8,
          "driverDistanceToPickupKm": chauffeur ? 4.0 : 3.5,
          "driverMovementStatus": chauffeur
              ? "Chauffeur driver accepted job and is heading to pickup area"
              : "Driver is heading to pickup",
          "customerNotice": chauffeur
              ? "A verified GoRide Chauffeur driver accepted your job. You can now contact the driver."
              : "Driver accepted your ride. You can now contact the driver.",
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

  Future<void> markArrived(String requestId, Map<String, dynamic> ride) async {
    final bool chauffeur = isChauffeurRide(ride);

    await FirebaseFirestore.instance.collection("ride_requests").doc(requestId).update({
      "status": "arrived",
      "arrivedAt": FieldValue.serverTimestamp(),
      "waitingStartedAt": chauffeur ? null : FieldValue.serverTimestamp(),
      "driverEtaMinutes": 0,
      "driverDistanceToPickupKm": 0,
      "driverMovementStatus": chauffeur
          ? "Chauffeur driver arrived. Please hand over car key when ready."
          : "Driver arrived at pickup",
      "customerNotice": chauffeur
          ? "Your GoRide Chauffeur driver has arrived. Car plate is added only after key handover."
          : "Driver has arrived. You have 5 free waiting minutes. Extra charges apply after 5 minutes.",
    });
  }

  Future<void> addCustomerCarPlate(String requestId) async {
    plateController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Customer Car Plate"),
          content: TextField(
            controller: plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: "Example: KDA 123A",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final plate = plateController.text.trim().toUpperCase();
                if (plate.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection("ride_requests")
                    .doc(requestId)
                    .update({
                      "customerCarPlate": plate,
                      "carPlateAddedByDriver": true,
                      "plateAddedAt": FieldValue.serverTimestamp(),
                      "customerNotice":
                          "Driver added your car plate after arrival and key handover.",
                    });

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmKeyReceived(String requestId) async {
    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "keyReceived": true,
          "keyReceivedAt": FieldValue.serverTimestamp(),
          "customerNotice":
              "Driver confirmed key received. Chauffeur job can now start.",
          "driverMovementStatus": "Customer key received",
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Key received confirmed")));
  }

  Future<void> startTrip(String requestId, Map<String, dynamic> ride) async {
    final bool chauffeur = isChauffeurRide(ride);

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "status": "in_progress",
          "tripStartedAt": FieldValue.serverTimestamp(),
          "chauffeurStartedAt": chauffeur ? FieldValue.serverTimestamp() : null,
          "driverMovementStatus": chauffeur
              ? "Chauffeur job is in progress"
              : "Trip is in progress",
          "customerNotice": chauffeur
              ? "Your Chauffeur job has started. GoRide is calculating time automatically."
              : "Your trip has started.",
        });
  }

  Future<void> addParking(String requestId, Map<String, dynamic> ride) async {
    if (isChauffeurRide(ride)) return;

    final double currentParking = toDouble(ride["parkingFee"]);

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "parkingFee": currentParking + 100,
          "customerNotice": "Parking fee has been added to the trip.",
        });
  }

  Future<void> addToll(String requestId, Map<String, dynamic> ride) async {
    if (isChauffeurRide(ride)) return;

    final double currentToll = toDouble(ride["tollFee"]);

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "tollFee": currentToll + 100,
          "customerNotice": "Toll fee has been added to the trip.",
        });
  }

  Future<void> addDeadMileage(
    String requestId,
    Map<String, dynamic> ride,
  ) async {
    if (isChauffeurRide(ride)) return;

    final double currentDeadMileage = toDouble(ride["deadMileageFee"]);

    await FirebaseFirestore.instance
        .collection("ride_requests")
        .doc(requestId)
        .update({
          "deadMileageFee": currentDeadMileage + 100,
          "customerNotice": "Dead mileage fee has been added to the trip.",
        });
  }

  double calculateChauffeurFinalFare(Map<String, dynamic> ride) {
    final double baseFare = toDouble(ride["originalFare"] ?? ride["fare"]);
    final String packageName = ride["selectedVehicleCategory"] ?? "";

    if (packageName == "Chauffeur - 1 Hour") {
      final Timestamp? startedAt = ride["chauffeurStartedAt"];
      if (startedAt == null) return baseFare;

      final int totalMinutes = DateTime.now()
          .difference(startedAt.toDate())
          .inMinutes;

      if (totalMinutes <= 60) return baseFare;

      final int extraMinutes = totalMinutes - 60;
      final double perMinuteRate = baseFare / 60;

      return baseFare + (extraMinutes * perMinuteRate);
    }

    return baseFare;
  }

  Future<void> completeTrip(String requestId, Map<String, dynamic> ride) async {
    final bool chauffeur = isChauffeurRide(ride);
    final String paymentMethod = ride["paymentMethod"] ?? "Cash";

    double baseFare = toDouble(ride["originalFare"] ?? ride["fare"]);
    double parkingFee = 0;
    double tollFee = 0;
    double deadMileageFee = 0;
    double waitingFee = 0;
    int waitingMinutes = 0;
    int chargeableWaitingMinutes = 0;

    if (chauffeur) {
      baseFare = calculateChauffeurFinalFare(ride);
    } else {
      parkingFee = toDouble(ride["parkingFee"]);
      tollFee = toDouble(ride["tollFee"]);
      deadMileageFee = toDouble(ride["deadMileageFee"]);

      final Timestamp? waitingStartedAt = ride["waitingStartedAt"];

      if (waitingStartedAt != null) {
        waitingMinutes = DateTime.now()
            .difference(waitingStartedAt.toDate())
            .inMinutes;
      }

      chargeableWaitingMinutes = waitingMinutes > freeWaitingMinutes
          ? waitingMinutes - freeWaitingMinutes
          : 0;

      waitingFee = chargeableWaitingMinutes * waitingChargePerMinute;
    }

    final double originalTotal =
        baseFare + parkingFee + tollFee + deadMileageFee + waitingFee;

    final double discountAmount = toDouble(ride["customerDiscountAmount"]);
    final double customerPays = originalTotal - discountAmount;

    final double commissionAmount = originalTotal * commissionPercent / 100;
    final double driverNetEarnings = originalTotal - commissionAmount;

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
          "isChauffeur": chauffeur,
          "baseTripFare": baseFare,
          "waitingMinutes": waitingMinutes,
          "chargeableWaitingMinutes": chargeableWaitingMinutes,
          "waitingFee": waitingFee,
          "parkingFee": parkingFee,
          "tollFee": tollFee,
          "deadMileageFee": deadMileageFee,
          "originalTotalFare": originalTotal,
          "customerDiscountAmount": discountAmount,
          "customerPayableFare": customerPays,
          "gorideCoversDiscount": discountAmount,
          "appCommissionPercent": commissionPercent,
          "appCommissionAmount": commissionAmount,
          "driverNetEarnings": driverNetEarnings,
          "paymentMethod": paymentMethod,
          "driverWalletBalanceAfterTrip": newWalletBalance,
          "driverCommissionDueAfterTrip": newCommissionDue,
          "driverMovementStatus": chauffeur
              ? "Chauffeur job completed"
              : "Trip completed",
          "customerNotice":
              "Trip completed. Final amount: KES ${customerPays.toStringAsFixed(0)}",
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Trip completed. You can now rate/comment customer."),
      ),
    );
  }

  Future<void> rateCustomer(String requestId) async {
    customerCommentController.clear();
    int rating = 5;
    bool paymentIssue = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Rate Customer"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: rating,
                    decoration: const InputDecoration(
                      labelText: "Rating",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text("5 Stars")),
                      DropdownMenuItem(value: 4, child: Text("4 Stars")),
                      DropdownMenuItem(value: 3, child: Text("3 Stars")),
                      DropdownMenuItem(value: 2, child: Text("2 Stars")),
                      DropdownMenuItem(value: 1, child: Text("1 Star")),
                    ],
                    onChanged: (value) {
                      setDialogState(() => rating = value ?? 5);
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: paymentIssue,
                    title: const Text("Payment issue / failed to pay"),
                    onChanged: (value) {
                      setDialogState(() => paymentIssue = value ?? false);
                    },
                  ),
                  TextField(
                    controller: customerCommentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Comment about customer",
                      hintText: "Positive or negative comment",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("ride_requests")
                    .doc(requestId)
                    .update({
                      "driverRatingToCustomer": rating,
                      "driverCommentToCustomer": customerCommentController.text
                          .trim(),
                      "customerPaymentIssueReportedByDriver": paymentIssue,
                      "driverRatedCustomerAt": FieldValue.serverTimestamp(),
                    });

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void callCustomer(String phone) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Call customer: $phone")));
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
        content: Text(
          "Withdrawal request sent. Auto payout also runs Saturday midnight.",
        ),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("GoRide balance cleared.")));
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
          const SizedBox(height: 6),
          Text(
            suspended
                ? "Pay GoRide balance to receive requests"
                : isOnline
                ? "Ready to receive ride and chauffeur requests"
                : "Go online to receive rides",
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
                  onPressed: loading
                      ? null
                      : () => updateDriverStatus(!isOnline),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: payGoRideBalance,
                    child: const Text(
                      "Pay Balance",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Card/Binance earnings can be withdrawn anytime. Auto payout: Saturday midnight.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
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
              : "You are offline.\nGo online to receive rides.",
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

        final activeDocs = snapshot.data!.docs.where((doc) {
          final ride = doc.data() as Map<String, dynamic>;

          final String status = ride["status"] ?? "";
          final String assignedDriverId = ride["assignedDriverId"] ?? "";
          final String rideDriverId = ride["driverId"] ?? "";

          final bool pendingForAll = status == "pending";
          final bool mine =
              assignedDriverId == driverId || rideDriverId == driverId;

          final bool activeStatus =
              status == "pending" ||
              status == "accepted" ||
              status == "arrived" ||
              status == "in_progress";

          return pendingForAll || (mine && activeStatus);
        }).toList();

        final completedDocs = snapshot.data!.docs.where((doc) {
          final ride = doc.data() as Map<String, dynamic>;

          final String status = ride["status"] ?? "";
          final String assignedDriverId = ride["assignedDriverId"] ?? "";
          final String rideDriverId = ride["driverId"] ?? "";

          final bool mine =
              assignedDriverId == driverId || rideDriverId == driverId;

          return mine && status == "completed";
        }).toList();

        final docs = activeDocs.isNotEmpty ? activeDocs : completedDocs;

        if (docs.isEmpty) {
          return const Center(child: Text("No ride request yet"));
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
    final String payment = ride["paymentMethod"] ?? "Cash";
    final String customerName = ride["customerName"] ?? "Customer";
    final String customerPhone = ride["customerPhone"] ?? "0700000000";
    final bool isEV = ride["isEV"] == true;
    final bool chauffeur = isChauffeurRide(ride);
    final bool keyReceived = ride["keyReceived"] == true;
    final bool plateAdded = ride["carPlateAddedByDriver"] == true;
    final String plate = ride["customerCarPlate"] ?? "";
    final bool acceptedOrLater = status != "pending" && status != "rejected";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Card(
        color: chauffeur ? Colors.green : Colors.orange,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                chauffeur
                    ? "${status.toUpperCase()} CHAUFFEUR JOB"
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
              rideLine("Service", isEV ? "⚡ $category" : category),
              rideLine("Payment", payment),

              if (chauffeur) rideLine("Privacy", "Plate hidden until arrival"),
              if (plateAdded) rideLine("Car Plate", plate),

              const Divider(color: Colors.white),

              rideLine(
                "Original Fare",
                "KES ${toDouble(ride["originalFare"] ?? ride["fare"]).toStringAsFixed(0)}",
              ),
              rideLine(
                "Customer Discount",
                "KES ${toDouble(ride["customerDiscountAmount"]).toStringAsFixed(0)}",
              ),
              rideLine(
                "Customer Pays",
                "KES ${toDouble(ride["customerPayableFare"]).toStringAsFixed(0)}",
              ),
              rideLine(
                "GoRide Covers",
                "KES ${toDouble(ride["gorideCoversDiscount"]).toStringAsFixed(0)}",
              ),

              if (status == "completed") ...[
                const Divider(color: Colors.white),
                rideLine(
                  "Final Total",
                  "KES ${toDouble(ride["originalTotalFare"]).toStringAsFixed(0)}",
                ),
                rideLine(
                  "Commission",
                  "KES ${toDouble(ride["appCommissionAmount"]).toStringAsFixed(0)}",
                ),
                rideLine(
                  "Driver Net",
                  "KES ${toDouble(ride["driverNetEarnings"]).toStringAsFixed(0)}",
                ),
              ],

              const SizedBox(height: 10),

              if (status == "pending")
                buttonRow(
                  chauffeur ? "ACCEPT JOB" : "ACCEPT",
                  Colors.green,
                  () => acceptRide(requestId, ride),
                  "REJECT",
                  Colors.red,
                  () => rejectRide(requestId),
                ),

              if (status == "accepted")
                fullButton(
                  chauffeur ? "ARRIVED AT CUSTOMER AREA" : "ARRIVED AT PICKUP",
                  Colors.green,
                  () => markArrived(requestId, ride),
                ),

              if (chauffeur && status == "arrived") ...[
                if (!plateAdded)
                  fullButton(
                    "ADD CUSTOMER CAR PLATE",
                    Colors.blue,
                    () => addCustomerCarPlate(requestId),
                  ),
                if (plateAdded && !keyReceived)
                  fullButton(
                    "CONFIRM KEY RECEIVED",
                    Colors.deepPurple,
                    () => confirmKeyReceived(requestId),
                  ),
                if (plateAdded && keyReceived)
                  fullButton(
                    "START CHAUFFEUR JOB",
                    Colors.blue,
                    () => startTrip(requestId, ride),
                  ),
              ],

              if (!chauffeur && status == "arrived")
                fullButton(
                  "START TRIP",
                  Colors.blue,
                  () => startTrip(requestId, ride),
                ),

              if (status == "in_progress") ...[
                if (!chauffeur) ...[
                  buttonRow(
                    "PARKING",
                    Colors.purple,
                    () => addParking(requestId, ride),
                    "TOLL",
                    Colors.brown,
                    () => addToll(requestId, ride),
                  ),
                  const SizedBox(height: 8),
                  fullButton(
                    "ADD DEAD MILEAGE",
                    Colors.deepOrange,
                    () => addDeadMileage(requestId, ride),
                  ),
                  const SizedBox(height: 8),
                ],
                fullButton(
                  chauffeur
                      ? "END CHAUFFEUR JOB & CALCULATE TIME"
                      : "END TRIP & CALCULATE FINAL FARE",
                  Colors.green,
                  () => completeTrip(requestId, ride),
                ),
              ],

              if (status == "completed") ...[
                const SizedBox(height: 8),
                fullButton(
                  "RATE / COMMENT CUSTOMER",
                  Colors.black,
                  () => rateCustomer(requestId),
                ),
              ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
