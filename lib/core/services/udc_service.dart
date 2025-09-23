import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/models/udc_details.dart';
import '../repositories/udc_repository.dart';

class UdcService with ChangeNotifier {
  final UdcRepository _repository;
  List<UdcDetails> _lotTypes = [];
  bool _isLoading = false;

  UdcService(this._repository);

  List<UdcDetails> get lotTypes => _lotTypes;
  bool get isLoading => _isLoading;

  Future<void> loadLotTypes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // FIX: Search by header code 'LT' instead of detail code
      _lotTypes = await _repository.getUdcDetailsByHeaderCode('LT');
      developer.log('Loaded ${_lotTypes.length} lot types');
    } catch (e) {
      developer.log('Failed to load LOT types: $e');
      // Fallback to default lot types if loading fails
      _lotTypes = _getDefaultLotTypes();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add fallback default lot types
  List<UdcDetails> _getDefaultLotTypes() {
    return [
      UdcDetails(
        id: 1,
        detailCode: '01',
        description1: 'Expirationnnnnnnnnnn Date',
        description2: 'Select items by expiration date',
      ),
      UdcDetails(
        id: 2,
        detailCode: '02',
        description1: 'Effectiveeeeeeeeeee Date',
        description2: 'Select items by effective date',
      ),
      UdcDetails(
        id: 3,
        detailCode: '03',
        description1: 'Receipteeeeeeeeee Date',
        description2: 'Select items by receipt date',
      ),
    ];
  }

  UdcDetails? getLotTypeById(int? id) {
    if (id == null) return null;
    try {
      return _lotTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return _lotTypes.isNotEmpty ? _lotTypes.first : null;
    }
  }

  Map<int, String> getLotTypesMap() {
    final map = <int, String>{};
    for (final type in _lotTypes) {
      map[type.id] = type.description1 ?? 'Unknown';
    }

    // Ensure we always have some options
    if (map.isEmpty) {
      map[1] = 'Expiration Date';
      map[2] = 'Effective Date';
      map[3] = 'Receipt Date';
    }

    return map;
  }
}
