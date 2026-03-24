import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'wifi_setup.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingCode = false;

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery scan is only supported on Mobile devices.")),
      );
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final capture = await _controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null) {
          _handleDeepLinking(code);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No QR code found in photo"), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error analyzing image: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDeepLinking(String code) async {
    if (_isHandlingCode) return;
    _isHandlingCode = true;
    
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device Linked Successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WifiSetupPage()),
        );
      }
    } catch (e) {
      _isHandlingCode = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error linking device: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Device QR"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: _pickImage,
              tooltip: "Upload from Gallery",
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: MobileScanner(
        controller: _controller,
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              _handleDeepLinking(code);
            }
          }
        },
      ),
      floatingActionButton: kIsWeb 
        ? null 
        : FloatingActionButton.extended(
            onPressed: _pickImage,
            label: const Text("FROM GALLERY", style: TextStyle(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.photo_library_outlined),
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            foregroundColor: Colors.black,
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
