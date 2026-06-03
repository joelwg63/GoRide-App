import 'package:flutter/material.dart';

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
  String loginMethod = "Email";
  String selectedCountryCode = "+254";

  bool faceConfirmed = false;
  bool fingerprintConfirmed = false;

  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
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
    phoneController.dispose();
    codeController.dispose();
    jobCardController.dispose();
    super.dispose();
  }

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget roleHomePage() {
    if (selectedRole == "Driver") return const DriverHome();
    if (selectedRole == "Admin") return const AdminHome();
    if (selectedRole == "Super Admin") return const SuperAdminHome();
    return const CustomerHome();
  }

  bool get isStaffLogin =>
      selectedRole == "Admin" || selectedRole == "Super Admin";

  void sendCode() {
    final target = loginMethod == "Email"
        ? emailController.text.trim()
        : "$selectedCountryCode${phoneController.text.trim()}";

    if (target.isEmpty || target == selectedCountryCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email or phone first")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Verification code sent to $target")),
    );
  }

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

  void loginUser() {
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

    if (codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter verification code")));
      return;
    }

    openPage(roleHomePage());
  }

  void showLoginForm() {
    setState(() {
      faceConfirmed = false;
      fingerprintConfirmed = false;
      jobCardController.clear();
      codeController.clear();
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
                      initialValue: selectedRole,
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
                        DropdownMenuItem(value: "Admin", child: Text("Admin")),
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

                    DropdownButtonFormField<String>(
                      initialValue: loginMethod,
                      decoration: const InputDecoration(
                        labelText: "Login Method",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Email", child: Text("Email")),
                        DropdownMenuItem(
                          value: "Phone",
                          child: Text("Phone Number"),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() => loginMethod = value ?? "Email");
                      },
                    ),

                    const SizedBox(height: 12),

                    if (loginMethod == "Email")
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          border: OutlineInputBorder(),
                        ),
                      ),

                    if (loginMethod == "Phone") ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedCountryCode,
                        decoration: const InputDecoration(
                          labelText: "Country",
                          border: OutlineInputBorder(),
                        ),
                        items: countries.map((country) {
                          return DropdownMenuItem(
                            value: country["code"],
                            child: Text(
                              "${country["name"]} ${country["code"]}",
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setSheetState(
                            () => selectedCountryCode = value ?? "+254",
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixText: "$selectedCountryCode ",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],

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

                    const SizedBox(height: 12),

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

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: loginUser,
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.white, fontSize: 17),
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
