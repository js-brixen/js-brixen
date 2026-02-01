import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../services/firestore_admin_service.dart';

class ProjectsProvider with ChangeNotifier {
  final FirestoreAdminService _firestoreService = FirestoreAdminService();

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  String? _selectedStatus;
  String? _selectedType;
  String? _searchQuery;
  bool _featuredOnly = false;

  StreamSubscription<List<Project>>? _projectsSubscription;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStatus => _selectedStatus;
  String? get selectedType => _selectedType;
  String? get searchQuery => _searchQuery;
  bool get featuredOnly => _featuredOnly;

  ProjectsProvider() {
    startListening();
  }

  void startListening() {
    _isLoading = true;
    notifyListeners();

    _projectsSubscription?.cancel();
    _projectsSubscription = _firestoreService
        .streamProjects(
          status: _selectedStatus,
          type: _selectedType,
          searchQuery: _searchQuery,
          featuredOnly: _featuredOnly,
        )
        .listen(
          (projects) {
            _projects = projects;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    startListening();
  }

  void setTypeFilter(String? type) {
    _selectedType = type;
    startListening();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query?.trim();
    startListening();
  }

  void toggleFeaturedOnly() {
    _featuredOnly = !_featuredOnly;
    startListening();
  }

  void clearFilters() {
    _selectedStatus = null;
    _selectedType = null;
    _searchQuery = null;
    _featuredOnly = false;
    startListening();
  }

  Future<String> createProject(Map<String, dynamic> projectData) async {
    try {
      final projectId = await _firestoreService.createProject(projectData);
      return projectId;
    } catch (e) {
      _error = 'Failed to create project: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestoreService.updateProject(projectId, updates);
    } catch (e) {
      _error = 'Failed to update project: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _firestoreService.deleteProject(projectId);
    } catch (e) {
      _error = 'Failed to delete project: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleProjectStatus(String projectId, String newStatus) async {
    try {
      await _firestoreService.toggleProjectStatus(projectId, newStatus);
    } catch (e) {
      _error = 'Failed to toggle status: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFeatured(String projectId, bool isFeatured) async {
    try {
      await _firestoreService.toggleFeatured(projectId, isFeatured);
    } catch (e) {
      _error = 'Failed to toggle featured: $e';
      notifyListeners();
      rethrow;
    }
  }

  int getCountByStatus(ProjectStatus status) {
    return _projects.where((p) => p.status == status).length;
  }

  int getCountByType(ProjectType type) {
    return _projects.where((p) => p.type == type).length;
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
