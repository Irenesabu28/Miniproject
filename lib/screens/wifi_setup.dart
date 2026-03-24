import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/theme.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiSetupPage extends StatefulWidget {
  final String? ssid;
  final String? password;
  const WifiSetupPage({super.key, this.ssid, this.password});

  @override
  State<WifiSetupPage> createState() => _WifiSetupPageState();
}

class _WifiSetupPageState extends State<WifiSetupPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  BluetoothConnection? _connection;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
  }

  Future<void> _checkBluetooth() async {
    // Request permissions first (vital for Android 12+ to avoid app crashing)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    try {
      _bluetoothState = await FlutterBluetoothSerial.instance.state;
      if (_bluetoothState == BluetoothState.STATE_OFF) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      debugPrint("Bluetooth error: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devicesList = [];
    });

    try {
      FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        final existingIndex = _devicesList.indexWhere((element) => element.address == r.device.address);
        if (existingIndex >= 0) {
          _devicesList[existingIndex] = r.device;
        } else {
          setState(() {
            _devicesList.add(r.device);
          });
        }
      }, onError: (dynamic error) {
        debugPrint("Scan error: $error");
        if (mounted) setState(() => _isScanning = false);
      }).onDone(() {
        if (mounted) setState(() => _isScanning = false);
      });
    } catch (e) {
      debugPrint("Scan exception: $e");
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text("Connecting to device...", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );

      // Add timeout to connection attempt
      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("Connection timed out. Ensure the device is powered on and within range."),
      );
      
      // Listen for data
      _connection!.input?.listen((data) {
        String msg = String.fromCharCodes(data);
        // Unified workflow: Update the service so status reflects everywhere
        FirebaseService().onDataReceived(msg);
      }).onDone(() {
        debugPrint("Link to device closed.");
        if (mounted) setState(() {});
      });

      if (mounted) Navigator.pop(context); // Close loading dialog
      
      // Auto-send if credentials provided, else show input
      if (widget.ssid != null && widget.ssid!.isNotEmpty) {
        _sendDirectly(widget.ssid!, widget.password ?? "");
      } else {
        _showCredentialsDialog(device);
      }
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError("Connection failed: ${e.toString()}");
      }
    }
  }

  Future<void> _sendDirectly(String ssid, String pass) async {
    try {
      String data = "$ssid,$pass";
      _connection!.output.add(utf8.encode(data));
      await _connection!.output.allSent;
      
      if (mounted) {
        _showSuccess("Credentials sent! Device is connecting to $ssid...");
        // Auto-quit after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showError("Failed to send: $e");
    }
  }

  void _showCredentialsDialog(BluetoothDevice device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          left: 24,
          right: 24,
          top: 40,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WiFi Configuration",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Configuring: ${device.name ?? 'Device'}",
              style: GoogleFonts.outfit(color: Colors.white60),
            ),
            const SizedBox(height: 32),
            _buildTextField(_ssidController, "WiFi SSID", Icons.wifi),
            const SizedBox(height: 16),
            _buildTextField(_passController, "WiFi Password", Icons.lock, isPassword: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _sendCredentials(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("SEND TO DEVICE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCredentials(BluetoothDevice device) async {
    if (_ssidController.text.isEmpty) {
      _showError("SSID cannot be empty");
      return;
    }

    try {
      String data = "${_ssidController.text},${_passController.text}";
      _connection!.output.add(utf8.encode(data));
      await _connection!.output.allSent;
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _showSuccess("Credentials sent! Device is connecting...");
      }
    } catch (e) {
      _showError("Failed to send data: $e");
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _connection?.dispose();
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Device Setup",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                FadeInDown(
                  child: Text(
                    "Setup via Bluetooth",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    "Select your CircuGuard device below to configure its WiFi settings.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textBody,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      final device = _devicesList[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: 100 * index),
                        child: Card(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.bluetooth, color: Colors.white),
                            ),
                            title: Text(
                              device.name ?? "Unknown Device",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              device.address,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                            onTap: () => _connectToDevice(device),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        _isScanning ? "SCANNING..." : "SCAN FOR DEVICES",
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
