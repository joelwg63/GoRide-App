import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final pickupController = TextEditingController(text: "Nairobi CBD");
  final destinationController = TextEditingController();

  String selectedRide = "Economy Car";
  String selectedPayment = "Cash";
  bool showRideOptions = false;
  bool loading = false;

  final double distanceKm = 8.0;
  final int customerTripCount = 0;

  final String customerName = "Joel";
  final String customerPhone = "0700000000";

  final List<Map<String, dynamic>> rides = [
    {
      "name": "Bike",
      "icon": Icons.two_wheeler,
      "base": 80.0,
      "perKm": 30.0,
      "tag": "Cheapest",
      "ev": false,
      "serviceType": "normal",
    },
    {
      "name": "Electric Bike",
      "icon": Icons.electric_bike,
      "base": 100.0,
      "perKm": 35.0,
      "tag": "Eco Friendly",
      "ev": true,
      "serviceType": "normal",
    },
    {
      "name": "Economy Car",
      "icon": Icons.directions_car,
      "base": 150.0,
      "perKm": 50.0,
      "tag": "Recommended",
      "ev": false,
      "serviceType": "normal",
    },
    {
      "name": "Electric Car",
      "icon": Icons.electric_car,
      "base": 180.0,
      "perKm": 55.0,
      "tag": "EV Ride",
      "ev": true,
      "serviceType": "normal",
    },
    {
      "name": "Comfort",
      "icon": Icons.local_taxi,
      "base": 250.0,
      "perKm": 70.0,
      "tag": "Premium",
      "ev": false,
      "serviceType": "normal",
    },
    {
      "name": "XL",
      "icon": Icons.airport_shuttle,
      "base": 350.0,
      "perKm": 90.0,
      "tag": "Group Ride",
      "ev": false,
      "serviceType": "normal",
    },
    {
      "name": "Chauffeur - 1 Hour",
      "icon": Icons.badge,
      "base": 800.0,
      "perKm": 0.0,
      "tag": "Hire trusted driver",
      "ev": false,
      "serviceType": "chauffeur",
    },
    {
      "name": "Chauffeur - 1 Day",
      "icon": Icons.work_history,
      "base": 5000.0,
      "perKm": 0.0,
      "tag": "Full day driver",
      "ev": false,
      "serviceType": "chauffeur",
    },
    {
      "name": "Airport Go & Return",
      "icon": Icons.flight_takeoff,
      "base": 2000.0,
      "perKm": 0.0,
      "tag": "Own car airport service",
      "ev": false,
      "serviceType": "chauffeur",
    },
  ];

  Map<String, dynamic> get selectedRideData {
    return rides.firstWhere(
      (ride) => ride["name"] == selectedRide,
      orElse: () => rides[2],
    );
  }

  bool get isChauffeur => selectedRideData["serviceType"] == "chauffeur";

  double fareFor(Map<String, dynamic> ride) {
    final double base = (ride["base"] ?? 0).toDouble();
    final double perKm = (ride["perKm"] ?? 0).toDouble();
    final String serviceType = ride["serviceType"] ?? "normal";
    if (serviceType == "chauffeur") return base;
    return base + (distanceKm * perKm);
  }

  double get originalFare => fareFor(selectedRideData);
  double get discountPercent => customerTripCount < 3 ? 30.0 : 0.0;
  double get discountAmount => originalFare * discountPercent / 100;
  double get customerPays => originalFare - discountAmount;
  double get appCommission => originalFare * 0.18;
  double get driverNetEarnings => originalFare * 0.82;

  Future<void> requestRide() async {
    if (pickupController.text.trim().isEmpty ||
        destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter pickup and destination")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection("ride_requests").add({
        "customerName": customerName,
        "customerPhone": customerPhone,
        "pickup": pickupController.text.trim(),
        "destination": destinationController.text.trim(),
        "distanceKm": isChauffeur ? 0 : distanceKm,

        "selectedVehicleCategory": selectedRide,
        "serviceType": selectedRideData["serviceType"],
        "isChauffeur": isChauffeur,
        "customerOwnsCar": isChauffeur,
        "driverHasCar": !isChauffeur,
        "isEV": selectedRideData["ev"],
        "paymentMethod": selectedPayment,

        "originalFare": originalFare,
        "fare": originalFare,
        "customerDiscountPercent": discountPercent,
        "customerDiscountAmount": discountAmount,
        "customerPayableFare": customerPays,
        "gorideCoversDiscount": discountAmount,

        "appCommissionPercent": 18,
        "appCommissionAmount": appCommission,
        "driverNetEarnings": driverNetEarnings,

        "waitingFreeMinutes": 5,
        "waitingChargePerMinute": 30,
        "waitingMinutes": 0,
        "waitingExtraFare": 0,
        "parkingFee": 0,
        "tollFee": 0,
        "deadMileageFee": 0,
        "totalFare": customerPays,

        "assignedDriverId": "",
        "assignedDriverName": "",
        "driverId": "",
        "driverName": "",
        "driverPhone": "",

        "status": "pending",
        "customerCanViewDriverDetails": false,
        "driverCanViewCustomerDetails": false,
        "driverMovementStatus": "Waiting for driver to accept",
        "customerNotice": isChauffeur
            ? "Chauffeur request sent. Waiting for a trusted GoRide driver."
            : "Ride requested. Waiting for driver.",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$selectedRide requested. You pay KES ${customerPays.toStringAsFixed(0)}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Request failed: $e")));
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> rateDriver(String requestId) async {
    int rating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Rate Driver"),
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
                    onChanged: (value) =>
                        setDialogState(() => rating = value ?? 5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Comment driver",
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
                      "customerRatingToDriver": rating,
                      "customerCommentToDriver": commentController.text.trim(),
                      "customerRatedDriverAt": FieldValue.serverTimestamp(),
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

  Future<void> tipDriver(String requestId) async {
    final tipController = TextEditingController(text: "100");

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tip Driver"),
          content: TextField(
            controller: tipController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Tip amount KES",
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
                final double tip =
                    double.tryParse(tipController.text.trim()) ?? 0;
                await FirebaseFirestore.instance
                    .collection("ride_requests")
                    .doc(requestId)
                    .update({
                      "customerTipAmount": tip,
                      "customerTippedDriverAt": FieldValue.serverTimestamp(),
                    });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text("Send Tip"),
            ),
          ],
        );
      },
    );
  }

  void callDriver(String phone) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Call driver: $phone")));
  }

  void openSOS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SOS alert will notify GoRide Admin and support."),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 150),
            child: Column(
              children: [
                mapHeader(),
                promoBanner(),
                chauffeurBanner(),
                whereToCard(),
                savedPlaces(),
                if (showRideOptions) rideOptions(),
                if (showRideOptions) paymentCard(),
                if (showRideOptions) fareBreakdown(),
                liveRideUpdates(),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: FloatingActionButton.small(
              heroTag: "customer_sos",
              backgroundColor: Colors.red,
              onPressed: openSOS,
              child: const Text(
                "SOS",
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          if (showRideOptions) bottomRequestBar(),
        ],
      ),
    );
  }

  Widget mapHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.green.shade50,
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.map, size: 90, color: Colors.green.shade400),
          ),
          Positioned(
            left: 16,
            top: 18,
            child: Row(
              children: [
                Image.asset(
                  'assets/images/goride_logo.png',
                  height: 46,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.local_taxi, color: Colors.green);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "GoRide",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () => pickupController.text = "Current Location",
              icon: const Icon(Icons.my_location, color: Colors.green),
              label: const Text(
                "Use current location",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget promoBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "30% OFF for your first 3 GoRide trips",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget chauffeurBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.badge, color: Colors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "New: Hire a trusted GoRide driver for your own car.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget whereToCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.radio_button_checked,
                  color: Colors.green,
                ),
                labelText: "Pickup",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
                labelText: "Where to?",
                hintText: "Enter destination",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty && !showRideOptions) {
                  setState(() => showRideOptions = true);
                }
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => setState(() => showRideOptions = true),
                child: const Text(
                  "SHOW RIDES",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget savedPlaces() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: savedPlaceTile(Icons.home, "Home")),
          const SizedBox(width: 8),
          Expanded(child: savedPlaceTile(Icons.business, "Work")),
        ],
      ),
    );
  }

  Widget savedPlaceTile(IconData icon, String title) {
    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: const Text("Saved place"),
      ),
    );
  }

  Widget rideOptions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Choose your GoRide service",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...rides.map((ride) {
            final bool selected = selectedRide == ride["name"];
            final double price = fareFor(ride);
            final bool isEV = ride["ev"] == true;
            final bool chauffeur = ride["serviceType"] == "chauffeur";

            return Card(
              color: selected ? Colors.green.shade50 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected ? Colors.green : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  ride["icon"],
                  color: isEV || chauffeur ? Colors.green : Colors.black87,
                  size: 32,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ride["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isEV) badge("⚡ EV"),
                    if (chauffeur) badge("DRIVER"),
                  ],
                ),
                subtitle: Text(
                  chauffeur
                      ? "${ride["tag"]} • Customer own car"
                      : "${ride["tag"]} • ${distanceKm.toStringAsFixed(1)} KM",
                ),
                trailing: Text(
                  "KES ${price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () => setState(() => selectedRide = ride["name"]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget badge(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget paymentCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          initialValue: selectedPayment,
          decoration: const InputDecoration(
            labelText: "Payment Method",
            prefixIcon: Icon(Icons.payment),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: "Cash", child: Text("Cash")),
            DropdownMenuItem(value: "M-Pesa", child: Text("M-Pesa")),
            DropdownMenuItem(value: "Card", child: Text("Bank Card")),
            DropdownMenuItem(
              value: "Binance",
              child: Text("Binance Pay / Crypto"),
            ),
          ],
          onChanged: (value) => setState(() => selectedPayment = value!),
        ),
      ),
    );
  }

  Widget fareBreakdown() {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            moneyLine("Original fare", originalFare),
            moneyLine("GoRide discount 30%", -discountAmount),
            const Divider(),
            moneyLine("You pay", customerPays, big: true),
            const SizedBox(height: 6),
            Text(
              isChauffeur
                  ? "A verified GoRide driver will drive your own car."
                  : "GoRide covers the discount so driver receives the full original fare.",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget liveRideUpdates() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("ride_requests")
          .orderBy("createdAt", descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(height: 20);
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Live ride updates",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String status = data["status"] ?? "pending";
                final num amount =
                    data["customerPayableFare"] ?? data["totalFare"] ?? 0;
                final bool acceptedOrLater =
                    status != "pending" && status != "rejected";
                final bool completed = status == "completed";
                final String driverName = data["driverName"] ?? "";
                final String driverPhone = data["driverPhone"] ?? "";

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            "${data["selectedVehicleCategory"] ?? "Ride"} • $status",
                          ),
                          subtitle: Text(
                            "${data["pickup"] ?? ""} → ${data["destination"] ?? ""}",
                          ),
                          trailing: Text(
                            "KES ${amount.toDouble().toStringAsFixed(0)}",
                          ),
                        ),
                        if (acceptedOrLater && driverName.isNotEmpty) ...[
                          const Divider(),
                          rowText("Driver", driverName),
                          rowText("Phone", driverPhone),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => callDriver(driverPhone),
                              child: const Text("CALL DRIVER"),
                            ),
                          ),
                        ],
                        if (completed) ...[
                          const Divider(),
                          rowText(
                            "Final Total",
                            "KES ${(data["originalTotalFare"] ?? 0).toDouble().toStringAsFixed(0)}",
                          ),
                          rowText(
                            "GoRide Discount",
                            "KES ${(data["customerDiscountAmount"] ?? 0).toDouble().toStringAsFixed(0)}",
                          ),
                          rowText(
                            "You Paid",
                            "KES ${(data["customerPayableFare"] ?? 0).toDouble().toStringAsFixed(0)}",
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => tipDriver(doc.id),
                                  child: const Text("TIP DRIVER"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => rateDriver(doc.id),
                                  child: const Text("RATE DRIVER"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget rowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomRequestBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "$selectedPayment • KES ${customerPays.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: loading ? null : requestRide,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "REQUEST",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget moneyLine(String label, double amount, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          amount < 0
              ? "- KES ${amount.abs().toStringAsFixed(0)}"
              : "KES ${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: big ? 18 : 14,
            fontWeight: big ? FontWeight.bold : FontWeight.normal,
            color: big ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}
