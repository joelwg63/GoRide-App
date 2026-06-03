import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.person), title: Text("Profile")),
          ListTile(leading: Icon(Icons.phone), title: Text("Phone Number")),
          ListTile(leading: Icon(Icons.email), title: Text("Email")),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Privacy & Security"),
          ),
          ListTile(leading: Icon(Icons.language), title: Text("Language")),
          ListTile(leading: Icon(Icons.help), title: Text("Help Center")),
          ListTile(leading: Icon(Icons.logout), title: Text("Logout")),
        ],
      ),
    );
  }
}
