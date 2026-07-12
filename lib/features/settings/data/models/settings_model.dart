class SettingsModel {
  final String themeMode; // 'system' | 'light' | 'dark'
  final String accentColorHex; // Hex string e.g. '#2F58CD'

  SettingsModel({
    required this.themeMode,
    required this.accentColorHex,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      themeMode: map['themeMode'] ?? 'system',
      accentColorHex: map['accentColorHex'] ?? '#2F58CD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'accentColorHex': accentColorHex,
    };
  }

  SettingsModel copyWith({
    String? themeMode,
    String? accentColorHex,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
    );
  }
}
