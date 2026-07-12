import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/settings_model.dart';
import 'dart:async';

class SettingsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  SettingsModel _settings = SettingsModel(themeMode: 'system', accentColorHex: '#2F58CD');
  StreamSubscription? _subscription;

  SettingsModel get settings => _settings;
  
  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Color get accentColor {
    final hexString = _settings.accentColorHex;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void initialize(String userId) {
    _subscription?.cancel();
    _subscription = _firestore.collection('settings').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _settings = SettingsModel.fromMap(snapshot.data()!);
        notifyListeners();
      } else {
        // Create default settings if not exists
        _firestore.collection('settings').doc(userId).set(_settings.toMap());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> updateThemeMode(String theme) async {
    _settings = _settings.copyWith(themeMode: theme);
    notifyListeners();
  }

  Future<void> updateThemeModeWithUser(String userId, String theme) async {
    _settings = _settings.copyWith(themeMode: theme);
    notifyListeners();
    await _firestore.collection('settings').doc(userId).set(_settings.toMap(), SetOptions(merge: true));
  }

  Future<void> updateAccentColorWithUser(String userId, Color color) async {
    final hex = '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
    _settings = _settings.copyWith(accentColorHex: hex);
    notifyListeners();
    await _firestore.collection('settings').doc(userId).set(_settings.toMap(), SetOptions(merge: true));
  }
}
