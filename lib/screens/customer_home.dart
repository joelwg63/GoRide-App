import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final TextEditingController pickupController =
      TextEditingController(text: "Current Location");
  final TextEditingController destinationController = TextEditingController();

  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController senderPhoneController = TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController receiverPhoneController = TextEditingController();
  final TextEditingController parcelDescriptionController =
      TextEditingController();
  final TextEditingController pickupNotesController = TextEditingController();
  final TextEditingController dropOffNotesController = TextEditingController();

  String selectedGroup = "Rides";
  String selectedService = "GoRide Economy";
  String selectedPayment = "Cash";

  String parcelAction = "Send";
  String parcelTransport = "Bike";

  bool loading = false;
  bool showServiceChoices = false;
  bool hasActiveRequest = false;

  final String customerName = "Joel";
  final String customerPhone = "0700000000";
  final String customerCountry = "Kenya";

  final String nearestDriverId = "demo_driver_001";
  final double distanceKm = 8.0;
  final double usdRate = 130.0;

  final Map<String, List<Map<String, dynamic>>> serviceGroups = {
    "Rides": [
      {
        "name": "GoRide Economy",
        "icon": Icons.directions_car,
        "base": 150.0,
        "perKm": 50.0,
        "subtitle": "Affordable everyday ride",
        "driverType": "Car",
        "capacity": 3,
        "eta": 3,
      },
      {
        "name": "GoRide Comfort",
        "icon": Icons.local_taxi,
        "base": 250.0,
        "perKm": 70.0,
        "subtitle": "Comfortable car",
        "driverType": "Car",
        "capacity": 4,
        "eta": 4,
      },
      {
        "name": "GoRide XL",
        "icon": Icons.airport_shuttle,
        "base": 350.0,
        "perKm": 90.0,
        "subtitle": "Bigger car for groups",
        "driverType": "XL",
        "capacity": 6,
        "eta": 5,
      },
      {
        "name": "GoRide EV",
        "icon": Icons.electric_car,
        "base": 180.0,
        "perKm": 55.0,
        "subtitle": "Electric vehicle",
        "driverType": "EV",
        "capacity": 4,
        "eta": 4,
      },
    ],
    "Schedule": [
      {
        "name": "Schedule Ride",
        "icon": Icons.schedule,
        "base": 200.0,
        "perKm": 55.0,
        "subtitle": "Book for later",
        "driverType": "Car",
        "capacity": 3,
        "eta": 10,
      },
      {
        "name": "Airport Schedule",
        "icon": Icons.flight_takeoff,
        "base": 2000.0,
        "perKm": 0.0,
        "subtitle": "Airport trip later",
        "driverType": "Airport",
        "capacity": 3,
        "eta": 10,
      },
    ],
    "Motorbike": [
      {
        "name": "GoRide Bike",
        "icon": Icons.two_wheeler,
        "base": 80.0,
        "perKm": 30.0,
        "subtitle": "Fast and cheap",
        "driverType": "Bike",
        "capacity": 1,
        "eta": 2,
      },
      {
        "name": "GoRide EV Bike",
        "icon": Icons.electric_bike,
        "base": 100.0,
        "perKm": 35.0,
        "subtitle": "Electric bike",
        "driverType": "EV Bike",
        "capacity": 1,
        "eta": 3,
      },
    ],
    "Food/Parcel": [
      {
        "name": "Food Delivery",
        "icon": Icons.fastfood,
        "base": 100.0,
        "perKm": 30.0,
        "subtitle": "Send or receive food",
        "driverType": "Bike",
        "capacity": 1,
        "eta": 3,
      },
      {
        "name": "Small Parcel",
        "icon": Icons.inventory_2,
        "base": 120.0,
        "perKm": 35.0,
        "subtitle": "Documents, phone, small items",
        "driverType": "Bike",
        "capacity": 1,
        "eta": 3,
      },
      {
        "name": "Medium Parcel",
        "icon": Icons.local_shipping,
        "base": 200.0,
        "perKm": 45.0,
        "subtitle": "Boxes and medium goods",
        "driverType": "Car",
        "capacity": 3,
        "eta": 5,
      },
      {
        "name": "Large Parcel",
        "icon": Icons.fire_truck,
        "base": 350.0,
        "perKm": 60.0,
        "subtitle": "Large packages",
        "driverType": "XL",
        "capacity": 6,
        "eta": 6,
      },
    ],
    "Chauffeur": [
      {
        "name": "Chauffeur - 1 Hour",
        "icon": Icons.badge,
        "base": 800.0,
        "perKm": 0.0,
        "subtitle": "Driver for your own car",
        "driverType": "Chauffeur",
        "capacity": 0,
        "eta": 10,
      },
      {
        "name": "Chauffeur - Half Day",
        "icon": Icons.work_history,
        "base": 2500.0,
        "perKm": 0.0,
        "subtitle": "Half day trusted driver",
        "driverType": "Chauffeur",
        "capacity": 0,
        "eta": 10,
      },
      {
        "name": "Chauffeur - Full Day",
        "icon": Icons.work,
        "base": 5000.0,
        "perKm": 0.0,
        "subtitle": "Full day trusted driver",
        "driverType": "Chauffeur",
        "capacity": 0,
        "eta": 10,
      },
    ],
  };

  bool get isParcelService => selectedGroup == "Food/Parcel";

  bool get isForeignCustomer => customerCountry.toLowerCase() != "kenya";

  String money(double kes) {
    if (!isForeignCustomer) return "KES ${kes.toStringAsFixed(0)}";
    return "KES ${kes.toStringAsFixed(0)} / USD ${(kes / usdRate).toStringAsFixed(2)}";
  }

  Map<String, dynamic> get selectedServiceData {
    return serviceGroups[selectedGroup]!.firstWhere(
      (item) => item["name"] == selectedService,
      orElse: () => serviceGroups["Rides"]!.first,
    );
  }

  double fareFor(Map<String, dynamic> service) {
    final double base = (service["base"] ?? 0).toDouble();
    final double perKm = (service["perKm"] ?? 0).toDouble();
    return base + (distanceKm * perKm);
  }

  double get selectedFare => fareFor(selectedServiceData);

  double oldFareFor(Map<String, dynamic> service) {
    return fareFor(service) * 1.15;
  }

  String get selectedDriverType {
    if (isParcelService) return parcelTransport;
    return selectedServiceData["driverType"] ?? "Car";
  }

  String get searchingText {
    final service = selectedService.toLowerCase();

    if (service.contains("ev bike")) return "Searching available EV bike rider...";
    if (service.contains("ev")) return "Searching available EV driver...";
    if (selectedGroup == "Motorbike") return "Searching available bike rider...";

    if (selectedGroup == "Food/Parcel") {
      if (parcelTransport == "Bike") return "Searching available bike rider for your package...";
      if (parcelTransport == "Car") return "Searching available car driver for your package...";
      if (parcelTransport == "XL") return "Searching available XL driver for your package...";
      if (parcelTransport == "Van") return "Searching available van driver for your package...";
      return "Searching available parcel rider...";
    }

    if (selectedGroup == "Chauffeur") return "Searching available chauffeur driver...";
    if (selectedGroup == "Schedule") return "Searching available scheduled ride driver...";

    return "Searching available car driver...";
  }

  String get fallbackText {
    final service = selectedService.toLowerCase();

    if (service.contains("ev")) {
      return "If no EV is near you, GoRide may offer an available normal driver.";
    }
    if (selectedGroup == "Food/Parcel" && parcelTransport == "Bike") {
      return "If no bike rider is near you, GoRide may offer an available car driver.";
    }
    return "";
  }

  Future<void> confirmThenRequest() async {
    if (hasActiveRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already have an active request.")),
      );
      return;
    }

    if (pickupController.text.trim().isEmpty ||
        destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter pickup and destination")),
      );
      return;
    }

    if (isParcelService) {
      if (senderNameController.text.trim().isEmpty ||
          senderPhoneController.text.trim().isEmpty ||
          receiverNameController.text.trim().isEmpty ||
          receiverPhoneController.text.trim().isEmpty ||
          parcelDescriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fill sender, receiver and package details"),
          ),
        );
        return;
      }
    }

    final bool? ready = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Ready to request?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              rowTextPlain("Service", selectedService),
              rowTextPlain("Distance", "${distanceKm.toStringAsFixed(1)} KM"),
              rowTextPlain(
                "Capacity",
                selectedServiceData["capacity"] == 0
                    ? "Own car"
                    : "${selectedServiceData["capacity"]} passengers",
              ),
              rowTextPlain("ETA", "${selectedServiceData["eta"]} min"),
              const Divider(),
              rowTextPlain("Estimated Fare", money(selectedFare)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                "Request",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (ready == true) {
      await requestRide();
    }
  }

  Future<void> requestRide() async {
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection("ride_requests").add({
        "customerName": customerName,
        "customerPhone": customerPhone,
        "customerCountry": customerCountry,
        "pickup": pickupController.text.trim(),
        "destination": destinationController.text.trim(),
        "serviceGroup": selectedGroup,
        "selectedVehicleCategory": selectedService,
        "requestedDriverType": selectedDriverType,
        "paymentMethod": selectedPayment,
        "distanceKm": distanceKm,
        "estimatedFareVisibleToCustomer": selectedFare,
        "estimatedFareHiddenFromCustomer": selectedFare,
        "serviceEtaMinutes": selectedServiceData["eta"],
        "serviceCapacity": selectedServiceData["capacity"],
        "oldFare": oldFareFor(selectedServiceData),
        "isParcel": isParcelService,
        "parcelAction": isParcelService ? parcelAction : "",
        "parcelTransport": isParcelService ? parcelTransport : "",
        "senderName": isParcelService ? senderNameController.text.trim() : "",
        "senderPhone": isParcelService ? senderPhoneController.text.trim() : "",
        "receiverName": isParcelService ? receiverNameController.text.trim() : "",
        "receiverPhone": isParcelService ? receiverPhoneController.text.trim() : "",
        "parcelDescription": isParcelService ? parcelDescriptionController.text.trim() : "",
        "pickupNotes": isParcelService ? pickupNotesController.text.trim() : "",
        "dropOffNotes": isParcelService ? dropOffNotesController.text.trim() : "",
        "confirmedFare": 0,
        "customerPayableFare": 0,
        "totalFare": 0,
        "fareConfirmed": false,
        "targetDriverId": nearestDriverId,
        "assignedDriverId": "",
        "driverId": "",
        "driverName": "",
        "driverPhone": "",
        "driverEtaMinutes": 0,
        "driverDistanceToPickupKm": 0,
        "allowFallbackDriver": true,
        "fallbackMessage": fallbackText,
        "status": "pending",
        "customerCanViewDriverDetails": false,
        "driverCanViewCustomerDetails": false,
        "driverMovementStatus": searchingText,
        "customerNotice": searchingText,
        "cancelledBy": "",
        "cancelReason": "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => hasActiveRequest = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request failed: $e")),
      );
    }

    if (mounted) setState(() => loading = false);
  }  Future<void> cancelRide(String requestId) async {
    String reason = "Changed my mind";

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Cancel Ride"),
          content: DropdownButtonFormField<String>(
            initialValue: reason,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "Driver taking too long", child: Text("Driver taking too long")),
              DropdownMenuItem(value: "Wrong pickup/destination", child: Text("Wrong pickup/destination")),
              DropdownMenuItem(value: "Changed my mind", child: Text("Changed my mind")),
              DropdownMenuItem(value: "Price issue", child: Text("Price issue")),
              DropdownMenuItem(value: "Found another ride", child: Text("Found another ride")),
              DropdownMenuItem(value: "Other reason", child: Text("Other reason")),
            ],
            onChanged: (value) => reason = value ?? reason,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("ride_requests")
                    .doc(requestId)
                    .update({
                  "status": "cancelled_by_customer",
                  "cancelledBy": "customer",
                  "cancelReason": reason,
                  "cancelledAt": FieldValue.serverTimestamp(),
                  "customerNotice": "You cancelled this request.",
                  "driverMovementStatus": "Customer cancelled request",
                });

                if (mounted) setState(() => hasActiveRequest = false);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel Ride",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void callDriver(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Call driver: $phone")),
    );
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
    senderNameController.dispose();
    senderPhoneController.dispose();
    receiverNameController.dispose();
    receiverPhoneController.dispose();
    parcelDescriptionController.dispose();
    pickupNotesController.dispose();
    dropOffNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 125),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                topHeader(),
                promoBanner(),
                quickServices(),
                whereToCard(),
                if (showServiceChoices) selectedGroupTitle(),
                if (showServiceChoices) serviceOptions(),
                if (showServiceChoices && isParcelService) parcelDetailsCard(),
                if (showServiceChoices) paymentCard(),
                liveRideUpdates(),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 18,
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
          if (showServiceChoices) bottomRequestBar(),
        ],
      ),
    );
  }

  Widget topHeader() {
    return Container(
      width: double.infinity,
      height: 95,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/goride_logo.png',
            height: 42,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_taxi, color: Colors.green, size: 38);
            },
          ),
          const SizedBox(width: 8),
          const Text(
            "GoRide",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget promoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "30% OFF your first 3 trips",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget quickServices() {
    final groups = [
      {"name": "Rides", "icon": Icons.directions_car},
      {"name": "Schedule", "icon": Icons.schedule},
      {"name": "Motorbike", "icon": Icons.two_wheeler},
      {"name": "Food/Parcel", "icon": Icons.inventory_2},
      {"name": "Chauffeur", "icon": Icons.badge},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.78,
        children: groups.map((group) {
          final groupName = group["name"] as String;
          final selected = selectedGroup == groupName;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedGroup = groupName;
                selectedService = serviceGroups[groupName]!.first["name"];
                showServiceChoices =
                    destinationController.text.trim().isNotEmpty;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    group["icon"] as IconData,
                    color: selected ? Colors.white : Colors.green,
                    size: 25,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    groupName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget whereToCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Where are you going?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.radio_button_checked, color: Colors.green),
                labelText: "Current Location",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
                labelText: "Destination",
                hintText: "Enter destination",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  showServiceChoices = value.trim().isNotEmpty;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: savedPlace(Icons.home, "Home")),
                const SizedBox(width: 8),
                Expanded(child: savedPlace(Icons.business, "Work")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget savedPlace(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget selectedGroupTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            selectedGroup,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const Text("Choose service", style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget serviceOptions() {
    final services = serviceGroups[selectedGroup] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: services.map((service) {
          final selected = selectedService == service["name"];
          final double fare = fareFor(service);
          final double oldFare = oldFareFor(service);
          final int eta = service["eta"] ?? 5;
          final int capacity = service["capacity"] ?? 1;

          return Card(
            elevation: selected ? 4 : 1,
            color: selected ? Colors.green.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected ? Colors.green : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(service["icon"], color: Colors.green),
              ),
              title: Text(
                service["name"],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$eta min   👤 ${capacity == 0 ? "Own car" : capacity}"),
                  Text(service["subtitle"] ?? "Tap to select"),
                  if (selected)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "SELECTED",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    money(fare),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    money(oldFare),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  selectedService = service["name"];
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget parcelDetailsCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "Delivery Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: parcelAction,
              decoration: const InputDecoration(
                labelText: "Send or Receive",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Send", child: Text("Send")),
                DropdownMenuItem(value: "Receive", child: Text("Receive")),
              ],
              onChanged: (value) => setState(() => parcelAction = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: parcelTransport,
              decoration: const InputDecoration(
                labelText: "Transport that can fit package",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Bike", child: Text("Bike")),
                DropdownMenuItem(value: "Car", child: Text("Car")),
                DropdownMenuItem(value: "XL", child: Text("XL Car")),
                DropdownMenuItem(value: "Van", child: Text("Van")),
              ],
              onChanged: (value) => setState(() => parcelTransport = value!),
            ),
            const SizedBox(height: 10),
            textField(senderNameController, "Sender Name", Icons.person),
            const SizedBox(height: 10),
            textField(senderPhoneController, "Sender Phone", Icons.phone),
            const SizedBox(height: 10),
            textField(receiverNameController, "Receiver Name", Icons.person_pin),
            const SizedBox(height: 10),
            textField(receiverPhoneController, "Receiver Phone", Icons.phone_android),
            const SizedBox(height: 10),
            textField(parcelDescriptionController, "Package Description", Icons.inventory),
            const SizedBox(height: 10),
            textField(pickupNotesController, "Pickup Notes", Icons.notes, requiredField: false),
            const SizedBox(height: 10),
            textField(dropOffNotesController, "Drop-off Notes", Icons.notes, requiredField: false),
            const SizedBox(height: 12),
            requirementsCard(),
          ],
        ),
      ),
    );
  }

  Widget requirementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        "Check requirements\n"
        "• Fits in a backpack or selected vehicle\n"
        "• Not illegal or dangerous\n"
        "• No drugs, weapons, alcohol, firearms, or prescription medicine\n"
        "• Customer is responsible for package details",
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool requiredField = true,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green),
        labelText: requiredField ? "$label *" : label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget paymentCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            DropdownMenuItem(value: "Binance", child: Text("Binance Pay / Crypto")),
          ],
          onChanged: (value) => setState(() => selectedPayment = value!),
        ),
      ),
    );
  }

  Widget liveRideUpdates() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("ride_requests")
          .orderBy("createdAt", descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          hasActiveRequest = false;
          return const SizedBox(height: 20);
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final String status = data["status"] ?? "pending";
        final bool active = status == "pending" ||
            status == "accepted" ||
            status == "arrived" ||
            status == "in_progress";

        hasActiveRequest = active;

        final bool acceptedOrLater = status == "accepted" ||
            status == "arrived" ||
            status == "in_progress" ||
            status == "completed";
        final bool cancelled = status == "cancelled_by_customer";

        final String driverName = data["driverName"] ?? "";
        final String driverPhone = data["driverPhone"] ?? "";
        final double fare =
            (data["confirmedFare"] ?? data["customerPayableFare"] ?? 0)
                .toDouble();
        final dynamic eta = data["driverEtaMinutes"] ?? 0;
        final double distance =
            (data["driverDistanceToPickupKm"] ?? 0).toDouble();
        final String notice = data["customerNotice"] ?? "";

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      acceptedOrLater
                          ? Icons.verified
                          : cancelled
                              ? Icons.cancel
                              : Icons.search,
                      color: acceptedOrLater
                          ? Colors.green
                          : cancelled
                              ? Colors.red
                              : Colors.orange,
                    ),
                    title: Text(
                      "${data["serviceGroup"] ?? "Ride"} • ${data["selectedVehicleCategory"] ?? ""}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${data["pickup"] ?? ""} → ${data["destination"] ?? ""}"),
                    trailing: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (notice.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: acceptedOrLater ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        notice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (status == "pending") ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                    if ((data["fallbackMessage"] ?? "").toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          data["fallbackMessage"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                  ],
                  if (acceptedOrLater) ...[
                    const Divider(),
                    rowText("Driver", driverName),
                    rowText("Phone", driverPhone),
                    rowText("ETA", "$eta minutes"),
                    rowText("Distance", "${distance.toStringAsFixed(1)} KM away"),
                    rowText("Fare", money(fare)),
                    if (data["isParcel"] == true) ...[
                      const Divider(),
                      rowText("Parcel", data["parcelAction"] ?? ""),
                      rowText("Transport", data["parcelTransport"] ?? ""),
                      rowText("Package", data["parcelDescription"] ?? ""),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Please prepare before driver arrives.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    fullButton("CALL DRIVER", Colors.green, () => callDriver(driverPhone)),
                    const SizedBox(height: 8),
                    if (status == "accepted")
                      fullButton("CANCEL RIDE", Colors.red, () => cancelRide(doc.id)),
                  ],
                  if (cancelled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Cancelled: ${data["cancelReason"] ?? ""}",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasActiveRequest ? Colors.grey : Colors.green,
              ),
              onPressed: loading || hasActiveRequest ? null : confirmThenRequest,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      hasActiveRequest
                          ? "REQUEST SENT"
                          : isParcelService
                              ? "CONFIRM DELIVERY • ${money(selectedFare)}"
                              : "SELECT $selectedService • ${money(selectedFare)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
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

  Widget rowTextPlain(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
}