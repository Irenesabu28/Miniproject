import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'screens/get_started.dart';
import 'screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth.dart';
import 'services/firebase_service.dart';
import 'utils/responsive.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: FutureBuilder(
        future: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Setup FCM once Firebase is ready
            FirebaseService().setupFCM();
            
            return StreamBuilder<User?>(
              stream: FirebaseService().authStateChanges,
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
                }
                if (authSnapshot.hasData) {
                  return const HomePage();
                }
                return const AuthPage();
              },
            );
          }
          
          // Initial Flutter-native splash screen while waiting for Firebase
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.bolt_rounded, size: 80, color: AppColors.primary),
                   SizedBox(height: 24),
                   CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
          );
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
