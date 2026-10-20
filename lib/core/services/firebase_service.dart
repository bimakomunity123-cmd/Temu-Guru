import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('[FirebaseService] Firebase successfully initialized.');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Firebase initialization notice: $e');
      // If live credentials are not yet configured on the cloud console,
      // fallback to safe mode without crashing the UI.
      _isInitialized = false;
      return false;
    }
  }
}
