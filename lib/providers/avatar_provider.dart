import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvatarProvider extends ChangeNotifier {
  static final AvatarProvider _instance = AvatarProvider._internal();
  factory AvatarProvider() => _instance;
  AvatarProvider._internal();

  String? _currentAvatar;
  
  String? get currentAvatar => _currentAvatar;

  void updateAvatar(String? avatar) {
    _currentAvatar = avatar;
    notifyListeners();
  }

  // Initialize avatar from Firebase
  void initializeAvatar() {
    _currentAvatar = FirebaseAuth.instance.currentUser?.photoURL;
    notifyListeners();
  }
}