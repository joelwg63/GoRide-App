import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer_home.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  String selectedCountryCode = "+254";
  bool loading = false;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();

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
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void sendCode() {
    final phone = "$selectedCountryCode${phoneController.text.trim()}";
    final email = emailController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Verification code sent to $phone and $email")),
    );
  }

  Future<void> createCustomerAccount() async {
    final fullName = fullNameController.text.trim();
    final phone = "$selectedCountryCode${phoneController.text.trim()}";
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final code = codeController.text.trim();

    if (fullName.isEmpty ||
        phoneController.text.trim().isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
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

      await FirebaseFirestore.instance.collection("customers").doc(uid).set({
        "customerId": uid,
        "fullName": fullName,
        "phone": phone,
        "countryCode": selectedCountryCode,
        "email": email,
        "role": "customer",
        "accountStatus": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer account created successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHome()),
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
        title: const Text("Customer Registration"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Create Customer Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

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

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: loading ? null : createCustomerAccount,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Create Customer Account",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
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
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
