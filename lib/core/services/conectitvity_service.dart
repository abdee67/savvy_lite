import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    initConnectivity();
    _setupListeners();
  }

  Future<void> initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Could not check connectivity: $e');
      }
    }
  }

  void _setupListeners() {
    _connectivity.onConnectivityChanged.listen((result) {
      final newStatus = result != ConnectivityResult.none;
      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        notifyListeners();
      }
    });
  }
}
