import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../main.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  FirebaseDatabase? _db;
  FirebaseAuth? _auth;
  List<String> tripHistory = [];
  
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  // Bluetooth/Offline status support
  final _bluetoothStatusController = BehaviorSubject<String>.seeded('STABLE');
  Stream<String> get bluetoothStatusStream => _bluetoothStatusController.stream;

  // Critical warning for dashboard
  final _criticalWarningController = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get criticalWarningStream => _criticalWarningController.stream;

  FirebaseService._internal() {
    loadHistory();
  }

  void saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("tripHistory", tripHistory);
  }

  void loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList("tripHistory");

    if (saved != null) {
      tripHistory = saved;
      // Re-evaluate warning state after load
      if (tripHistory.length >= 5) {
        _criticalWarningController.add("Multiple trips detected! Please check your wiring and appliances for safety.");
      }
    }
  }

  FirebaseDatabase get _getDb {
    return _db ??= FirebaseDatabase.instance;
  }
  
  FirebaseAuth get _getAuth {
    return _auth ??= FirebaseAuth.instance;
  }

  // Authentication Methods
  User? get currentUser => _getAuth.currentUser;
  Stream<User?> get authStateChanges => _getAuth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password, {String name = '', String phone = ''}) async {
    final creds = await _getAuth.createUserWithEmailAndPassword(email: email, password: password);
    if (creds.user != null) {
      // Initialize database structure for new user
      await resetDatabase(initialProfile: UserModel(name: name, email: email, phone: phone));
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
  String? get _userPath => currentUser?.uid != null ? 'users/${currentUser!.uid}' : null;

  // Listen to current ELCB status (Unified Firebase & Bluetooth)
  Stream<String> get statusStream {
    if (_userPath == null) {
      return bluetoothStatusStream;
    }

    // Combine Firebase and Bluetooth streams
    return Rx.combineLatest2<String, String, String>(
      _getDb.ref('$_userPath/device_ids').onValue.switchMap((event) {
        final data = event.snapshot.value;
        if (data == null || (data is Map && data.isEmpty)) {
          return _getDb.ref('$_userPath/ELCB_SYSTEM/status').onValue.map((e) => e.snapshot.value?.toString() ?? 'STABLE');
        } else if (data is Map) {
          final deviceId = data.values.first.toString();
          return _getDb.ref('devices/$deviceId/status').onValue.map((e) => e.snapshot.value?.toString() ?? 'STABLE');
        } else {
          return Stream.value('STABLE');
        }
      }),
      bluetoothStatusStream,
      (fbStatus, btStatus) {
        // Correct Trip logic: if EITHER says TRIPPED, we are TRIPPED
        if (fbStatus.toUpperCase() == 'TRIPPED' || btStatus.toUpperCase() == 'TRIPPED') {
          return 'TRIPPED';
        }
        return fbStatus;
      },
    ).distinct();
  }

  // Get reactive profile updates
  Stream<UserModel> get profileStream {
    if (_userPath == null) {
      return Stream.value(const UserModel());
    }
    return _getDb.ref('$_userPath/profile').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return UserModel.fromJson(data);
      }
      return const UserModel();
    }).distinct();
  }

  // Get Trip Logs
  Stream<List<TripLog>> get tripLogsStream {
    if (_userPath == null) {
      return Stream.value([]);
    }

    return _getDb.ref('$_userPath/device_ids').onValue.switchMap((event) {
      final data = event.snapshot.value;
      String path;
      if (data == null || (data is Map && data.isEmpty)) {
        path = '$_userPath/logs';
      } else if (data is Map) {
        final deviceId = data.values.first.toString();
        path = 'devices/$deviceId/logs';
      } else {
        path = '$_userPath/logs';
      }

      return _getDb.ref(path).onValue.map((event) {
        final List<TripLog> logs = [];
        final dynamic val = event.snapshot.value;
        
        if (val != null && val is Map) {
          val.forEach((key, value) {
            if (key == 'init' || value == null) return; 
            if (value is Map) {
              final dateStr = value['date']?.toString() ?? '';
              final timeStr = value['time']?.toString() ?? '';
              
              DateTime timestamp;
              try {
                timestamp = DateTime.parse('${dateStr}T$timeStr');
              } catch (e) {
                try {
                  timestamp = DateTime.parse('$dateStr $timeStr');
                } catch (e2) {
                  timestamp = DateTime.now();
                }
              }

              logs.add(TripLog(
                timestamp: timestamp,
                isTripped: value['status']?.toString().toUpperCase() == 'TRIPPED',
                description: value['status']?.toString() ?? 'Unknown',
              ));
            }
          });
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          // Sync warning state with remote logs
          final remoteTripCount = logs.where((l) => l.isTripped).length;
          final totalCount = (remoteTripCount > tripHistory.length) ? remoteTripCount : tripHistory.length;
          
          if (totalCount >= 5) {
            _criticalWarningController.add("Multiple trips detected! Please check your wiring and appliances for safety.");
          } else {
             _criticalWarningController.add(null);
          }
        }
        return List<TripLog>.unmodifiable(logs);
      });
    }).distinct();
  }

  // Check if user has any devices linked
  Stream<bool> get hasDevicesStream {
    if (_userPath == null) return Stream.value(false);
    return _getDb.ref('$_userPath/device_ids').onValue.map((event) {
      final data = event.snapshot.value;
      return data is Map && data.isNotEmpty;
    }).distinct();
  }

  // Save/Update Profile
  Future<void> saveProfile(UserModel user) async {
    if (_userPath == null) throw Exception("User not authenticated.");
    try {
      await _getDb.ref('$_userPath/profile').set(user.toJson());
    } catch (e) {
      debugPrint("Save error: $e");
      rethrow;
    }
  }

  // Get Profile
  Future<UserModel?> getProfile() async {
    if (_userPath == null) return const UserModel();
    try {
      final snapshot = await _getDb.ref('$_userPath/profile').get();
      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          return UserModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
    return const UserModel();
  }

  // Reset and Initialize Database
  Future<void> resetDatabase({UserModel? initialProfile}) async {
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
      "profile": (initialProfile ?? const UserModel()).toJson()
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
        handleTrip();
      }
    });
  }

  Future<void> clearHistory() async {
    tripHistory.clear();
    _criticalWarningController.add(null);
    saveHistory();

    if (_userPath == null) return;
    
    try {
      final deviceSnap = await _getDb.ref('$_userPath/device_ids').get();
      final data = deviceSnap.value;
      if (data is Map && data.isNotEmpty) {
        final deviceId = data.values.first.toString();
        await _getDb.ref('devices/$deviceId/logs').remove();
      } else {
        await _getDb.ref('$_userPath/logs').remove();
      }
    } catch (e) {
      debugPrint("Error clearing history: $e");
    }
  }

  void onDataReceived(String msg) {
    if (msg.contains("TRIPPED")) {
      _bluetoothStatusController.add("TRIPPED");
      handleTrip();
    } else if (msg.contains("STABLE")) {
      _bluetoothStatusController.add("STABLE");
    }
  }

  void handleTrip() {
    final now = DateTime.now();

    final formattedTime =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

    tripHistory.insert(0, formattedTime); // newest on top

    saveHistory(); // IMPORTANT
    showTripNotification();

    if (tripHistory.length >= 5) {
      const warningMsg = "Multiple trips detected! Please check your wiring and appliances for safety.";
      _criticalWarningController.add(warningMsg);
      showTripAlert(warningMsg, "⚠️ CRITICAL WARNING");
    }
  }

  Future<void> showTripNotification() async {
    if (tripHistory.isNotEmpty) {
      await showTripAlert("Trip detected at ${tripHistory[0]}");
    } else {
      await showTripAlert();
    }
  }
}

// Extension to add startWith to Stream is removed as we now use rxdart
