import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/theme.dart';
import 'screens/get_started.dart';
import 'screens/home.dart';
import 'screens/auth.dart';
import 'services/firebase_service.dart';
import 'utils/responsive.dart';
import 'firebase_options.dart';

// Initialize Global Notification Plugin
final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings);
}

Future<void> showTripAlert() async {
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
    "⚠️ ELCB TRIPPED",
    "Check immediately!",
    details,
  );
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
