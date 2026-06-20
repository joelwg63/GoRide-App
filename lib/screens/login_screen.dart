import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer_home.dart';
import 'driver_home.dart';
import 'admin_home.dart';
import 'super_admin_home.dart';
import 'register_choice_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = "Customer";
  String selectedCountryCode = "+254";

  bool faceConfirmed = false;
  bool fingerprintConfirmed = false;
  bool loading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final jobCardController = TextEditingController();

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    jobCardController.dispose();
    super.dispose();
  }

  void openPage(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget roleHomePage() {
    if (selectedRole == "Driver") return const DriverHome();
    if (selectedRole == "Admin") return const AdminHome();
    if (selectedRole == "Super Admin") return const SuperAdminHome();
    return const CustomerHome();
  }

  String roleCollection() {
    if (selectedRole == "Driver") return "drivers";
    if (selectedRole == "Admin") return "admins";
    if (selectedRole == "Super Admin") return "admins";
    return "customers";
  }

  String expectedRole() {
    if (selectedRole == "Driver") return "driver";
    if (selectedRole == "Admin") return "admin";
    if (selectedRole == "Super Admin") return "super_admin";
    return "customer";
  }

  bool get isStaffLogin =>
      selectedRole == "Admin" || selectedRole == "Super Admin";

  void confirmFace() {
    setState(() => faceConfirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Face confirmation completed")),
    );
  }

  void confirmFingerprint() {
    setState(() => fingerprintConfirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fingerprint confirmation completed")),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password")),
      );
      return;
    }

    if (isStaffLogin && jobCardController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter GoRide Job Card Number")),
      );
      return;
    }

    if (selectedRole == "Super Admin" &&
        (!faceConfirmed || !fingerprintConfirmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Super Admin requires face and fingerprint confirmation",
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection(roleCollection())
          .doc(uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        throw Exception("No $selectedRole profile found in Firestore.");
      }

      final data = doc.data() ?? {};
      final role = (data["role"] ?? "").toString();
      final accountStatus = (data["accountStatus"] ?? "active").toString();
      final jobCard = (data["jobCardNumber"] ?? "").toString();

      if (role != expectedRole()) {
        await FirebaseAuth.instance.signOut();
        throw Exception("This account is not registered as $selectedRole.");
      }

      if (accountStatus == "blocked" || accountStatus == "suspended") {
        await FirebaseAuth.instance.signOut();
        throw Exception("This account is $accountStatus.");
      }

      if (selectedRole == "Driver" && accountStatus != "active") {
        await FirebaseAuth.instance.signOut();
        throw Exception("Driver account is not approved yet.");
      }

      if (isStaffLogin && jobCard.isNotEmpty) {
        final enteredJobCard = jobCardController.text.trim().toUpperCase();

        if (enteredJobCard != jobCard.toUpperCase()) {
          await FirebaseAuth.instance.signOut();
          throw Exception("Invalid GoRide Job Card Number.");
        }
      }

      if (!mounted) return;

      Navigator.pop(context);
      openPage(roleHomePage());
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      if (e.code == "user-not-found") {
        message = "No account found with this email";
      } else if (e.code == "wrong-password" ||
          e.code == "invalid-credential") {
        message = "Wrong email or password";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => loading = false);
  }

  void showLoginForm() {
    setState(() {
      faceConfirmed = false;
      fingerprintConfirmed = false;
      jobCardController.clear();
      passwordController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool staff =
                selectedRole == "Admin" || selectedRole == "Super Admin";
            final bool superAdmin = selectedRole == "Super Admin";

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Login to GoRide",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Login As",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Customer",
                          child: Text("Customer"),
                        ),
                        DropdownMenuItem(
                          value: "Driver",
                          child: Text("Driver"),
                        ),
                        DropdownMenuItem(
                          value: "Admin",
                          child: Text("Admin"),
                        ),
                        DropdownMenuItem(
                          value: "Super Admin",
                          child: Text("Super Admin"),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedRole = value ?? "Customer";
                          faceConfirmed = false;
                          fingerprintConfirmed = false;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (staff) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: jobCardController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: superAdmin
                              ? "Super Admin Job Card Number"
                              : "Admin Job Card Number",
                          hintText: superAdmin ? "GR-SA-0001" : "GR-AD-0001",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],

                    if (superAdmin) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Super Admin Security",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setSheetState(() {
                                        faceConfirmed = true;
                                      });
                                      confirmFace();
                                    },
                                    icon: Icon(
                                      faceConfirmed
                                          ? Icons.check_circle
                                          : Icons.face,
                                    ),
                                    label: Text(
                                      faceConfirmed
                                          ? "Face Confirmed"
                                          : "Face Check",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setSheetState(() {
                                        fingerprintConfirmed = true;
                                      });
                                      confirmFingerprint();
                                    },
                                    icon: Icon(
                                      fingerprintConfirmed
                                          ? Icons.check_circle
                                          : Icons.fingerprint,
                                    ),
                                    label: Text(
                                      fingerprintConfirmed
                                          ? "Confirmed"
                                          : "Fingerprint",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Customer and company data require Super Admin approval for export or transfer.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: loading ? null : loginUser,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "LOGIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Image.asset(
                'assets/images/goride_logo.png',
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.local_taxi,
                    size: 110,
                    color: Colors.green,
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text(
                "GoRide",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const Text(
                "Your Ride, Your Way",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 45),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: showLoginForm,
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    openPage(const RegisterChoiceScreen());
                  },
                  child: const Text("REGISTER", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}