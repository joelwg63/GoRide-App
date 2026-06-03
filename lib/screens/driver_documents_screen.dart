import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  bool loading = false;

  final String demoDriverId = "demo_driver_001";

  final Map<String, String> documentStatus = {
    "National ID Front": "not_uploaded",
    "National ID Back": "not_uploaded",
    "Driving License Front": "not_uploaded",
    "Driving License Back": "not_uploaded",
    "Live Selfie Photo": "not_uploaded",
    "Profile Photo": "not_uploaded",
    "Police Clearance": "not_uploaded",
    "PSV Badge": "not_uploaded",
    "KRA PIN Certificate": "not_uploaded",
    "Vehicle Photo": "not_uploaded",
    "Vehicle Registration Plate": "not_uploaded",
    "Original Logbook": "not_uploaded",
    "NTSA Inspection Certificate": "not_uploaded",
    "PSV Insurance": "not_uploaded",
  };

  String firestoreFieldName(String title) {
    return title
        .replaceAll(" ", "_")
        .replaceAll("/", "_")
        .replaceAll("-", "_")
        .toLowerCase();
  }

  Future<void> uploadDocument(String title) async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text("Take Photo with Camera"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  markUploaded(title, "camera_photo_demo.jpg");
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text("Choose JPG / PNG from Gallery"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  markUploaded(title, "gallery_image_demo.png");
                },
              ),

              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text("Upload PDF Document"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  markUploaded(title, "document_demo.pdf");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> markUploaded(String title, String fileName) async {
    final field = firestoreFieldName(title);

    setState(() {
      documentStatus[title] = "uploaded_pending_review";
    });

    await FirebaseFirestore.instance
        .collection("driver_documents")
        .doc(demoDriverId)
        .set({
          "${field}_status": "uploaded_pending_review",
          "${field}_fileName": fileName,
          "${field}_uploadedAt": FieldValue.serverTimestamp(),
          "documentReviewStatus": "pending_admin_review",
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$title uploaded for admin review")));
  }

  Future<void> submitForVerification() async {
    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection("driver_documents")
        .doc(demoDriverId)
        .set({
          "driverId": demoDriverId,
          "documentReviewStatus": "submitted_for_verification",
          "submittedAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection("drivers")
        .doc(demoDriverId)
        .set({
          "verificationStatus": "pending_admin_review",
          "accountStatus": "pending_verification",
          "canReceiveRequests": false,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Documents submitted. Waiting for GoRide Admin approval.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadedCount = documentStatus.values
        .where((status) => status != "not_uploaded")
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Driver Documents"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "GoRide Driver Verification",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "$uploadedCount / ${documentStatus.length} documents uploaded",
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            sectionTitle("Personal Documents"),
            documentTile("National ID Front"),
            documentTile("National ID Back"),
            documentTile("Driving License Front"),
            documentTile("Driving License Back"),
            documentTile("Live Selfie Photo"),
            documentTile("Profile Photo"),

            const SizedBox(height: 20),

            sectionTitle("Driver Documents"),
            documentTile("Police Clearance"),
            documentTile("PSV Badge"),
            documentTile("KRA PIN Certificate"),

            const SizedBox(height: 20),

            sectionTitle("Vehicle Documents"),
            documentTile("Vehicle Photo"),
            documentTile("Vehicle Registration Plate"),
            documentTile("Original Logbook"),
            documentTile("NTSA Inspection Certificate"),
            documentTile("PSV Insurance"),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: loading ? null : submitForVerification,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit For Verification",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Supported uploads: Camera Photo, JPG, PNG and PDF. "
                "All documents are reviewed by GoRide Admin. "
                "You cannot go online until approval is completed.",
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
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget documentTile(String title) {
    final status = documentStatus[title] ?? "not_uploaded";
    final uploaded = status != "not_uploaded";

    return Card(
      child: ListTile(
        leading: Icon(
          uploaded ? Icons.check_circle : Icons.upload_file,
          color: uploaded ? Colors.green : Colors.orange,
        ),
        title: Text(title),
        subtitle: Text(
          uploaded ? "Uploaded • Pending Admin Review" : "Not Uploaded",
        ),
        trailing: ElevatedButton(
          onPressed: () => uploadDocument(title),
          child: Text(uploaded ? "Change" : "Upload"),
        ),
      ),
    );
  }
}
