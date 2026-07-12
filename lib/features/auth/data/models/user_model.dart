import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final DateTime createdAt;
  final bool isAnonymous;
  final int dailyChatCount;
  final DateTime lastChatReset;

  UserModel({
    required this.uid,
    required this.displayName,
    this.email,
    required this.createdAt,
    required this.isAnonymous,
    required this.dailyChatCount,
    required this.lastChatReset,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAnonymous: map['isAnonymous'] ?? false,
      dailyChatCount: map['dailyChatCount'] ?? 0,
      lastChatReset: (map['lastChatReset'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAnonymous': isAnonymous,
      'dailyChatCount': dailyChatCount,
      'lastChatReset': Timestamp.fromDate(lastChatReset),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    bool? isAnonymous,
    int? dailyChatCount,
    DateTime? lastChatReset,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      dailyChatCount: dailyChatCount ?? this.dailyChatCount,
      lastChatReset: lastChatReset ?? this.lastChatReset,
    );
  }
}
