import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/theme.dart';
import 'screens/home.dart';
import 'screens/auth.dart';
import 'services/firebase_service.dart';
import 'utils/responsive.dart';
import 'firebase_options.dart';

// Initialize Global Notification Plugin
final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings);
}

bool isTripAlertShowing = false;

Future<void> showTripAlert([String message = "Check immediately!", String title = "⚠️ ELCB TRIPPED"]) async {
  // Show notification in tray
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'elcb_channel',
    'ELCB Alerts',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails details =
      NotificationDetails(android: androidDetails);

  await notificationsPlugin.show(
    0,
    title,
    message,
    details,
  );
  
  // Also show the "Alert Screen" modal if navigator is available
  if (navigatorKey.currentState != null && !isTripAlertShowing) {
    showTripAlertModal(navigatorKey.currentState!.context, message);
  }
}

void showTripAlertModal(BuildContext context, String message) {
  isTripAlertShowing = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TripAlertModal(message: message),
  ).then((_) => isTripAlertShowing = false);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  await initNotifications();
  
  // Initialize Firebase (Alternative to FutureBuilder approach for better performance)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CircuGuard',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          
          if (snapshot.hasData) {
            // Setup FCM when user is logged in
            FirebaseService().setupFCM();
            return const HomePage();
          }
          
          return const AuthPage();
        },
      ),
      builder: (context, child) {
        return ResponsiveWrapper(child: child!);
      },
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class TripAlertModal extends StatelessWidget {
  final String message;
  const TripAlertModal({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
            const SizedBox(height: 24),
            const Text(
              "EMERGENCY TRIP",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("RESET / ACKNOWLEDGE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
