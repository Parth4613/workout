import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  UserProvider() {
    _user = _auth.currentUser;
    // Listen for auth state changes
    _auth.userChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> refreshUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.currentUser?.updateDisplayName(name);
      await refreshUser();
    } catch (e) {
      debugPrint('Error updating display name: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}