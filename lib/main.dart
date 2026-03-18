import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'screens/get_started.dart';
import 'screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth.dart';
import 'services/firebase_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup Cloud Messaging
  await FirebaseService().setupFCM();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          return const AuthPage();
        },
      ),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
