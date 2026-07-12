import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.userId,
    this.projectId,
    required this.title,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      userId: map['userId'] ?? '',
      projectId: map['projectId'],
      title: map['title'] ?? '',
      isPinned: map['isPinned'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'projectId': projectId,
      'title': title,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ChatModel copyWith({
    String? projectId,
    String? title,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
