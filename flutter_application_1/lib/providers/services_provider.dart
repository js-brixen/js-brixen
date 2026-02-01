import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/service.dart';
import '../services/firestore_admin_service.dart';

class ServicesProvider with ChangeNotifier {
  final FirestoreAdminService _firestoreService = FirestoreAdminService();

  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  String? _selectedStatus;
  String? _searchQuery;

  StreamSubscription<List<Service>>? _servicesSubscription;

  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStatus => _selectedStatus;
  String? get searchQuery => _searchQuery;

  ServicesProvider() {
    startListening();
  }

  void startListening() {
    _isLoading = true;
    notifyListeners();

    _servicesSubscription?.cancel();
    _servicesSubscription = _firestoreService
        .streamServices(status: _selectedStatus, searchQuery: _searchQuery)
        .listen(
          (services) {
            _services = services;
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

  void setSearchQuery(String? query) {
    _searchQuery = query?.trim();
    startListening();
  }

  void clearFilters() {
    _selectedStatus = null;
    _searchQuery = null;
    startListening();
  }

  Future<String> createService(Map<String, dynamic> serviceData) async {
    try {
      final serviceId = await _firestoreService.createService(serviceData);
      return serviceId;
    } catch (e) {
      _error = 'Failed to create service: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestoreService.updateService(serviceId, updates);
    } catch (e) {
      _error = 'Failed to update service: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _firestoreService.deleteService(serviceId);
    } catch (e) {
      _error = 'Failed to delete service: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleServiceStatus(String serviceId, String newStatus) async {
    try {
      await _firestoreService.toggleServiceStatus(serviceId, newStatus);
    } catch (e) {
      _error = 'Failed to toggle status: $e';
      notifyListeners();
      rethrow;
    }
  }

  int getCountByStatus(ServiceStatus status) {
    return _services.where((s) => s.status == status).length;
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    super.dispose();
  }
}
