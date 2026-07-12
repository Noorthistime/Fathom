import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String userId;
  final String name;
  final bool isPinned;
  final int order;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.isPinned,
    required this.order,
    required this.createdAt,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      isPinned: map['isPinned'] ?? false,
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'isPinned': isPinned,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProjectModel copyWith({
    String? name,
    bool? isPinned,
    int? order,
  }) {
    return ProjectModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      isPinned: isPinned ?? this.isPinned,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
