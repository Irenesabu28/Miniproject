import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../main.dart';
import '../models/models.dart';

class FirebaseService {
  FirebaseDatabase? _db;
  FirebaseAuth? _auth;
  bool _initialized = false;
  
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  FirebaseService._internal();

  FirebaseDatabase get _getDb {
    _initialized = true;
    return _db ??= FirebaseDatabase.instance;
  }
  
  FirebaseAuth get _getAuth {
    _initialized = true;
    return _auth ??= FirebaseAuth.instance;
  }

  // Authentication Methods
  User? get currentUser => _getAuth.currentUser;
  Stream<User?> get authStateChanges => _getAuth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password) async {
    final creds = await _getAuth.createUserWithEmailAndPassword(email: email, password: password);
    if (creds.user != null) {
      // Initialize database structure for new user
      await resetDatabase();
      setupFCM(); // Don't await FCM setup to keep UI responsive
    }
    return creds;
  }

  Future<UserCredential?> login(String email, String password) async {
    final creds = await _getAuth.signInWithEmailAndPassword(email: email, password: password);
    if (creds.user != null) {
      setupFCM(); // Don't await FCM setup to keep UI responsive
    }
    return creds;
  }

  Future<void> logout() async {
    await _getAuth.signOut();
  }

  // Scoped Data Paths
  String? get _userPath => currentUser?.uid != null ? 'database/users/${currentUser!.uid}' : null;

  // Listen to current ELCB status
  Stream<String> get statusStream {
    if (_userPath == null) {
      return Stream.periodic(const Duration(seconds: 5), (i) => i % 10 == 0 ? 'TRIPPED' : 'STABLE')
          .startWith('STABLE')
          .distinct();
    }

    // First find the device ID, then listen to its status
    return _getDb.ref('$_userPath/device_ids').onValue.switchMap((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || data.isEmpty) {
        // Fallback to old user-path for backward compatibility or empty state
        return _getDb.ref('$_userPath/ELCB_SYSTEM/status').onValue.map((e) => e.snapshot.value?.toString() ?? 'STABLE');
      }
      final deviceId = data.values.first.toString();
      return _getDb.ref('devices/$deviceId/status').onValue.map((e) => e.snapshot.value?.toString() ?? 'STABLE');
    }).distinct();
  }

  // Get reactive profile updates
  Stream<UserModel> get profileStream {
    if (_userPath == null) {
      return Stream.value(const UserModel());
    }
    return _getDb.ref('$_userPath/profile').onValue.map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return UserModel.fromJson(data);
      }
      return const UserModel();
    }).distinct();
  }

  // Get Trip Logs
  Stream<List<TripLog>> get tripLogsStream {
    if (_userPath == null) {
      return Stream.value([
        TripLog(timestamp: DateTime.now().subtract(const Duration(days: 1)), isTripped: true, description: "TRIPPED"),
      ]);
    }

    return _getDb.ref('$_userPath/device_ids').onValue.switchMap((event) {
      final data = event.snapshot.value as Map?;
      String path;
      if (data == null || data.isEmpty) {
        path = '$_userPath/logs';
      } else {
        final deviceId = data.values.first.toString();
        path = 'devices/$deviceId/logs';
      }

      return _getDb.ref(path).onValue.map((event) {
        final List<TripLog> logs = [];
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        
        if (data != null) {
          data.forEach((key, value) {
            if (key == 'init') return; 
            final logMap = value as Map<dynamic, dynamic>;
            final dateStr = logMap['date'] ?? '';
            final timeStr = logMap['time'] ?? '';
            
            DateTime timestamp;
            try {
              timestamp = DateTime.parse('$dateStr $timeStr');
            } catch (e) {
              timestamp = DateTime.now();
            }

            logs.add(TripLog(
              timestamp: timestamp,
              isTripped: logMap['status'] == 'TRIPPED',
              description: logMap['status'] ?? 'Unknown',
            ));
          });
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        return List<TripLog>.unmodifiable(logs);
      });
    }).distinct(listEquals);
  }

  // Check if user has any devices linked
  Stream<bool> get hasDevicesStream {
    if (_userPath == null) return Stream.value(false);
    return _getDb.ref('$_userPath/device_ids').onValue.map((event) {
      final data = event.snapshot.value;
      return data != null && (data as Map).isNotEmpty;
    }).distinct();
  }

  // Save/Update Profile
  Future<void> saveProfile(UserModel user) async {
    if (_userPath == null) return;
    await _getDb.ref('$_userPath/profile').set(user.toJson());
  }

  // Get Profile
  Future<UserModel?> getProfile() async {
    if (_userPath == null) return UserModel();
    final snapshot = await _getDb.ref('$_userPath/profile').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromJson(data);
    }
    return null;
  }

  // Reset and Initialize Database
  Future<void> resetDatabase() async {
    if (_userPath == null) return;
    
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
    final timeStr = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";

    await _getDb.ref(_userPath).set({
      "ELCB_SYSTEM": {
        "status": "STABLE",
        "last_updated": "$dateStr $timeStr"
      },
      "logs": {
        "init": {
          "status": "STABLE",
          "date": dateStr,
          "time": timeStr
        }
      },
      "profile": UserModel().toJson()
    });
  }

  // FCM Setup
  Future<void> setupFCM() async {
    try {
      if (kIsWeb) return; // Skip mobile-specific FCM setup for web if needed, or handle separately

      // Setup FCM for Foreground Alerts
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission for push notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
        
        // Get the token for this device
        String? token = await messaging.getToken();
        debugPrint("FCM Token: $token");
        
        // Save token for push notifications
        if (token != null && _userPath != null) {
          await _getDb.ref('$_userPath/fcm_token').set(token);
        }
        
        // Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Notification received: ${message.notification?.title}");
        });
        
        // Listen for foreground status changes
        _setupLocalAlerts();
      }
    } catch (e) {
      debugPrint("FCM initialization failed: $e");
    }
  }

  void _setupLocalAlerts() {
    if (_userPath == null) return;

    statusStream.listen((status) {
      if (status == "TRIPPED") {
        _showLocalNotification();
      }
    });
  }

  Future<void> _showLocalNotification() async {
    await showTripAlert();
  }
}

// Extension to add startWith to Stream is removed as we now use rxdart
