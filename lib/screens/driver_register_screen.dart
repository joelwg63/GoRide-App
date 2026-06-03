import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'driver_documents_screen.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  String selectedCountryCode = "+254";
  String selectedVehicleCategory = "GoRide Economy";
  bool loading = false;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();

  final nationalIdController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final experienceController = TextEditingController();

  final vehiclePlateController = TextEditingController();
  final vehicleMakeController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleColorController = TextEditingController();
  final vehicleYearController = TextEditingController();

  final List<Map<String, String>> countries = [
    {"name": "Kenya", "code": "+254"},
    {"name": "USA", "code": "+1"},
    {"name": "UK", "code": "+44"},
    {"name": "Tanzania", "code": "+255"},
    {"name": "Uganda", "code": "+256"},
    {"name": "Rwanda", "code": "+250"},
    {"name": "South Africa", "code": "+27"},
    {"name": "Nigeria", "code": "+234"},
    {"name": "UAE", "code": "+971"},
    {"name": "India", "code": "+91"},
  ];

  final List<String> vehicleCategories = [
    "GoRide Economy",
    "GoRide Comfort",
    "GoRide XL",
    "GoRide Taxi",
    "GoRide EV Car",
    "GoRide Bike",
    "GoRide EV Bike",
  ];

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();

    nationalIdController.dispose();
    licenseNumberController.dispose();
    experienceController.dispose();

    vehiclePlateController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleColorController.dispose();
    vehicleYearController.dispose();

    super.dispose();
  }

  void sendCode() {
    final phone = "$selectedCountryCode${phoneController.text.trim()}";
    final email = emailController.text.trim();

    if (phoneController.text.trim().isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter phone and email first")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Verification code sent to $phone and $email")),
    );
  }

  Future<void> createDriverAccount() async {
    final fullName = fullNameController.text.trim();
    final phone = "$selectedCountryCode${phoneController.text.trim()}";
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final code = codeController.text.trim();

    final nationalId = nationalIdController.text.trim();
    final licenseNumber = licenseNumberController.text.trim();
    final experienceYears = experienceController.text.trim();

    final vehiclePlate = vehiclePlateController.text.trim().toUpperCase();
    final vehicleMake = vehicleMakeController.text.trim();
    final vehicleModel = vehicleModelController.text.trim();
    final vehicleColor = vehicleColorController.text.trim();
    final vehicleYear = vehicleYearController.text.trim();

    if (fullName.isEmpty ||
        phoneController.text.trim().isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        nationalId.isEmpty ||
        licenseNumber.isEmpty ||
        experienceYears.isEmpty ||
        vehiclePlate.isEmpty ||
        vehicleMake.isEmpty ||
        vehicleModel.isEmpty ||
        vehicleColor.isEmpty ||
        vehicleYear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter verification code")));
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection("drivers").doc(uid).set({
        "driverId": uid,
        "fullName": fullName,
        "phone": phone,
        "countryCode": selectedCountryCode,
        "email": email,
        "role": "driver",

        "nationalIdNumber": nationalId,
        "drivingLicenseNumber": licenseNumber,
        "experienceYears": experienceYears,

        "vehiclePlate": vehiclePlate,
        "vehicleMake": vehicleMake,
        "vehicleModel": vehicleModel,
        "vehicleColor": vehicleColor,
        "vehicleYear": vehicleYear,
        "vehicleCategory": selectedVehicleCategory,

        "verificationStatus": "pending_documents",
        "accountStatus": "pending_verification",
        "canReceiveRequests": false,
        "online": false,
        "suspended": false,

        "walletBalance": 0,
        "commissionDue": 0,
        "todayEarnings": 0,
        "tipsReceived": 0,

        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("driver_documents")
          .doc(uid)
          .set({
            "driverId": uid,
            "fullName": fullName,
            "role": "driver",
            "documentReviewStatus": "pending_uploads",
            "nationalIdFrontStatus": "not_uploaded",
            "nationalIdBackStatus": "not_uploaded",
            "licenseFrontStatus": "not_uploaded",
            "licenseBackStatus": "not_uploaded",
            "liveSelfieStatus": "not_uploaded",
            "vehiclePhotoStatus": "not_uploaded",
            "logbookStatus": "not_uploaded",
            "ntsaInspectionStatus": "not_uploaded",
            "psvInsuranceStatus": "not_uploaded",
            "policeClearanceStatus": "not_uploaded",
            "psvBadgeStatus": "not_uploaded",
            "kraPinStatus": "not_uploaded",
            "createdAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver account created. Upload documents next."),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverDocumentsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Registration failed";

      if (e.code == "email-already-in-use") {
        message = "This email is already registered";
      } else if (e.code == "weak-password") {
        message = "Password is too weak";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Driver Registration"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Register as GoRide Driver",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              "Driver with own vehicle",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            sectionTitle("Account Details"),

            inputBox(controller: fullNameController, label: "Full Names"),

            DropdownButtonFormField<String>(
              initialValue: selectedCountryCode,
              decoration: const InputDecoration(
                labelText: "Country Code",
                border: OutlineInputBorder(),
              ),
              items: countries.map((country) {
                return DropdownMenuItem(
                  value: country["code"],
                  child: Text("${country["name"]} ${country["code"]}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCountryCode = value ?? "+254");
              },
            ),

            const SizedBox(height: 12),

            inputBox(
              controller: phoneController,
              label: "Phone Number",
              keyboardType: TextInputType.phone,
              prefixText: "$selectedCountryCode ",
            ),

            inputBox(
              controller: emailController,
              label: "Email Address",
              keyboardType: TextInputType.emailAddress,
            ),

            inputBox(
              controller: passwordController,
              label: "Password",
              password: true,
            ),

            inputBox(
              controller: confirmPasswordController,
              label: "Confirm Password",
              password: true,
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Verification Code",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: sendCode,
                  child: const Text("Send Code"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            sectionTitle("Driver Details"),

            inputBox(
              controller: nationalIdController,
              label: "National ID Number",
              keyboardType: TextInputType.number,
            ),

            inputBox(
              controller: licenseNumberController,
              label: "Driving License Number",
            ),

            inputBox(
              controller: experienceController,
              label: "Years of Driving Experience",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            sectionTitle("Vehicle Details"),

            inputBox(
              controller: vehiclePlateController,
              label: "Vehicle Registration Number",
            ),

            inputBox(controller: vehicleMakeController, label: "Vehicle Make"),

            inputBox(
              controller: vehicleModelController,
              label: "Vehicle Model",
            ),

            inputBox(
              controller: vehicleColorController,
              label: "Vehicle Color",
            ),

            inputBox(
              controller: vehicleYearController,
              label: "Vehicle Year",
              keyboardType: TextInputType.number,
            ),

            DropdownButtonFormField<String>(
              initialValue: selectedVehicleCategory,
              decoration: const InputDecoration(
                labelText: "Vehicle Category",
                border: OutlineInputBorder(),
              ),
              items: vehicleCategories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(
                  () => selectedVehicleCategory = value ?? "GoRide Economy",
                );
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: loading
                    ? const SizedBox()
                    : const Icon(Icons.folder, color: Colors.white),
                label: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Create Account & Upload Documents",
                        style: TextStyle(color: Colors.white),
                      ),
                onPressed: loading ? null : createDriverAccount,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Your driver account must be reviewed and approved by GoRide Admin before you can receive requests.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget inputBox({
    required TextEditingController controller,
    required String label,
    bool password = false,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: password,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
