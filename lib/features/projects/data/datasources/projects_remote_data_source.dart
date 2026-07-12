import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ProjectModel>> streamProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectModel.fromMap(doc.data(), doc.id);
      }).toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return a.order.compareTo(b.order);
        });
    });
  }

  Future<void> createProject({
    required String userId,
    required String name,
  }) async {
    final docRef = _firestore.collection('projects').doc();
    final project = ProjectModel(
      id: docRef.id,
      userId: userId,
      name: name,
      isPinned: false,
      order: 0,
      createdAt: DateTime.now(),
    );
    await docRef.set(project.toMap());
  }

  Future<void> renameProject(String projectId, String newName) async {
    await _firestore.collection('projects').doc(projectId).update({
      'name': newName,
    });
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore.collection('projects').doc(projectId).delete();
  }

  Future<void> togglePinProject(String projectId, bool currentPinnedState) async {
    await _firestore.collection('projects').doc(projectId).update({
      'isPinned': !currentPinnedState,
    });
  }

  Future<void> updateProjectOrder(String projectId, int newOrder) async {
    await _firestore.collection('projects').doc(projectId).update({
      'order': newOrder,
    });
  }
}
