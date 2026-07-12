import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String role; // 'user' | 'model'
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
