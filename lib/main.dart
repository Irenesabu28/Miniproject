import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'screens/get_started.dart';
import 'screens/home.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // For Web, you MUST provide FirebaseOptions. 
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSy... (Get from Firebase Console)",
        appId: "1:665406... (Get from Firebase Console)",
        messagingSenderId: "...",
        projectId: "miniproject-fc41e",
        databaseURL: "https://miniproject-fc41e-default-rtdb.firebaseio.com/",
        storageBucket: "miniproject-fc41e.appspot.com",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const ELCBMonitorApp());
}

class ELCBMonitorApp extends StatelessWidget {
  const ELCBMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELCB Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child,
          ),
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const GetStartedPage();
        },
      ),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
