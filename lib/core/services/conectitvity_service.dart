import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:savvy_stock/core/errors/failures.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;

  /// Stream controller for broadcasting connectivity changes.
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool get isConnected => _isConnected;

  /// Stream of connectivity status changes (true = online, false = offline).
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    initConnectivity();
    _setupListeners();
  }

  Future<void> initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isConnected);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Could not check connectivity: $e');
      }
    }
  }

  void _setupListeners() {
    _connectivity.onConnectivityChanged.listen((result) {
      final newStatus = !result.contains(ConnectivityResult.none);
      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        _connectivityController.add(_isConnected);
        notifyListeners();
      }
    });
  }

  /// Check if there is actual internet access (not just WiFi connected).
  /// Performs a DNS lookup to verify real connectivity.
  Future<bool> hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  //check connectivity
  Future<Object> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return NetworkFailure('No internet connection');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Could not check connectivity: $e');
      }
      return false;
    }
  }

  @override
  void dispose() {
    _connectivityController.close();
    super.dispose();
  }
}
