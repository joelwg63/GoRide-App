import 'package:flutter/material.dart';

class ChauffeurRegisterScreen extends StatelessWidget {
  const ChauffeurRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Chauffeur Registration"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Register as Chauffeur Driver",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            inputBox("Full Names"),
            inputBox("Phone Number +2547..."),
            inputBox("Email Address"),
            inputBox("Password", password: true),
            inputBox("Confirm Password", password: true),
            inputBox("Verification Code"),
            inputBox("National ID Number"),
            inputBox("Driving License Number"),
            inputBox("Years of Driving Experience"),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Chauffeur Drivers do not upload vehicle documents. "
                "Only personal and professional documents are required.",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {},
                child: const Text(
                  "Submit Chauffeur Registration",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputBox(String label, {bool password = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        obscureText: password,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
