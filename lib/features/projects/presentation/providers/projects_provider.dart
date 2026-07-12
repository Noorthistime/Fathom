import 'package:flutter/material.dart';
import '../../data/models/project_model.dart';
import '../../data/datasources/projects_remote_data_source.dart';
import 'dart:async';

class ProjectsProvider extends ChangeNotifier {
  final ProjectsRemoteDataSource _dataSource = ProjectsRemoteDataSource();
  
  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _subscription;

  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get pinnedProjects => _projects.where((p) => p.isPinned).toList();
  List<ProjectModel> get unpinnedProjects => _projects.where((p) => !p.isPinned).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initialize(String userId) {
    _isLoading = true;
    notifyListeners();
    _subscription?.cancel();
    
    _subscription = _dataSource.streamProjects(userId).listen(
      (data) {
        _projects = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> createProject(String userId, String name) async {
    try {
      await _dataSource.createProject(userId: userId, name: name);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> renameProject(String projectId, String newName) async {
    try {
      await _dataSource.renameProject(projectId, newName);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _dataSource.deleteProject(projectId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> togglePinProject(ProjectModel project) async {
    try {
      await _dataSource.togglePinProject(project.id, project.isPinned);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProjectsOrder(List<ProjectModel> reorderedList) async {
    try {
      for (int i = 0; i < reorderedList.length; i++) {
        final p = reorderedList[i];
        if (p.order != i) {
          await _dataSource.updateProjectOrder(p.id, i);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
