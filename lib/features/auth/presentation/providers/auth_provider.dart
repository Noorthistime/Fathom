import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../data/models/user_model.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _authDataSource.authStateChanges.listen((fb.User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          _user = await _authDataSource.getUserData(firebaseUser.uid);
        } catch (e) {
          _user = null;
        }
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkCurrentUser() async {
    final firebaseUser = _authDataSource.currentUser;
    if (firebaseUser != null) {
      try {
        _user = await _authDataSource.getUserData(firebaseUser.uid);
      } catch (e) {
        _user = null;
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authDataSource.signInWithEmail(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authDataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authDataSource.signInAnonymously();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> upgradeGuest(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final oldUid = _user?.uid;
      await _authDataSource.upgradeAnonymousAccount(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      // Update local state model
      if (oldUid != null) {
        _user = await _authDataSource.getUserData(oldUid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authDataSource.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateDisplayName(String name) async {
    try {
      await _authDataSource.updateDisplayName(name);
      if (_user != null) {
        _user = _user!.copyWith(displayName: name);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await _authDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authDataSource.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> incrementChatCount() async {
    if (_user != null) {
      final newCount = _user!.dailyChatCount + 1;
      _user = _user!.copyWith(dailyChatCount: newCount);
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'dailyChatCount': newCount,
      });
      notifyListeners();
    }
  }

  Future<void> resetDailyChatCount() async {
    if (_user != null) {
      _user = _user!.copyWith(dailyChatCount: 0, lastChatReset: DateTime.now());
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'dailyChatCount': 0,
        'lastChatReset': Timestamp.fromDate(_user!.lastChatReset),
      });
      notifyListeners();
    }
  }
}
