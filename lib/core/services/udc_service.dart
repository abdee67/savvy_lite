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
      _lotTypes = await _repository.getUdcDetailsByCode('LT');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load LOT types: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UdcDetails? getLotTypeById(int? id) {
    if (id == null) return null;
    return _lotTypes.firstWhere(
      (type) => type.id == id,
      orElse: () => _lotTypes.first,
    );
  }

  Map<int, String> getLotTypesMap() {
    final map = <int, String>{};
    for (final type in _lotTypes) {
      if (type.id != null) {
        map[type.id!] = type.description1;
      }
    }
    return map;
  }
}
