import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class FirebaseService {
  FirebaseDatabase? _db;
  FirebaseAuth? _auth;
  bool _initialized = false;
  
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  FirebaseService._internal() {
    try {
      _db = FirebaseDatabase.instance;
      _auth = FirebaseAuth.instance;
      _initialized = true;
    } catch (e) {
      debugPrint("Firebase services not available: $e");
      _initialized = false;
    }
  }

  // Authentication Methods
  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  Future<UserCredential?> signUp(String email, String password) async {
    if (!_initialized) return null;
    final creds = await _auth!.createUserWithEmailAndPassword(email: email, password: password);
    if (creds.user != null) {
      // Initialize database structure for new user
      await resetDatabase();
    }
    return creds;
  }

  Future<UserCredential?> login(String email, String password) async {
    if (!_initialized) return null;
    return await _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    if (!_initialized) return;
    await _auth!.signOut();
  }

  // Scoped Data Paths
  String? get _userPath => currentUser?.uid != null ? 'users/${currentUser!.uid}' : null;

  // Listen to current ELCB status
  Stream<String> get statusStream {
    if (!_initialized || _db == null || _userPath == null) {
      return Stream.periodic(const Duration(seconds: 5), (i) => i % 10 == 0 ? 'tripped' : 'stable').startWith('stable');
    }
    return _db!.ref('$_userPath/status/current').onValue.map((event) {
      return event.snapshot.value?.toString() ?? 'stable';
    });
  }

  // Get Trip Logs
  Stream<List<TripLog>> get tripLogsStream {
    if (!_initialized || _db == null || _userPath == null) {
      return Stream.value([
        TripLog(timestamp: DateTime.now().subtract(const Duration(days: 1)), isTripped: true, description: "System Trip"),
        TripLog(timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)), isTripped: true, description: "Voltage drop"),
        TripLog(timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)), isTripped: true, description: "Manual test"),
      ]);
    }
    return _db!.ref('$_userPath/logs').onValue.map((event) {
      final List<TripLog> logs = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          final logMap = value as Map<dynamic, dynamic>;
          logs.add(TripLog(
            timestamp: DateTime.parse(logMap['timestamp'] ?? DateTime.now().toIso8601String()),
            isTripped: true,
            description: logMap['reason'] ?? 'ELCB Tripped',
          ));
        });
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return logs;
    });
  }

  // Save/Update Profile
  Future<void> saveProfile(UserModel user) async {
    if (!_initialized || _db == null || _userPath == null) {
      debugPrint("Firebase not initialized or user not logged in.");
      return;
    }
    await _db!.ref('$_userPath/profile').set(user.toJson());
  }

  // Get Profile
  Future<UserModel?> getProfile() async {
    if (!_initialized || _db == null || _userPath == null) {
      return UserModel();
    }
    final snapshot = await _db!.ref('$_userPath/profile').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromJson(data);
    }
    return null;
  }

  // Reset and Initialize Database
  Future<void> resetDatabase() async {
    if (!_initialized || _db == null || _userPath == null) return;
    
    await _db!.ref(_userPath).set({
      "status": {"current": "stable"},
      "logs": {
        "init": {
          "timestamp": DateTime.now().toIso8601String(),
          "reason": "Database Reset"
        }
      },
      "profile": UserModel().toJson()
    });
  }
}

// Extension to add startWith to Stream
extension StreamExtension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
