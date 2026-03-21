import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ScanQRPage extends StatelessWidget {
  const ScanQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Device QR"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) async {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;

            if (code != null) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              String uid = user.uid;

              try {
                // Link device to user
                await FirebaseDatabase.instance
                    .ref("database/users/$uid/device_ids")
                    .push()
                    .set(code);

                // Link user to device
                await FirebaseDatabase.instance
                    .ref("devices/$code/assigned_to")
                    .set(uid);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Device Linked Successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error linking device: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
        },
      ),
    );
  }
}
