import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/errors/exceptions.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/repositories/system_constant_repository.dart';

class SystemConstantsService with ChangeNotifier {
  final SystemConstantRepository _repository;
  SystemConstant? _currentSystemConstant;
  bool _isLoading = false;
  String? _error;

  SystemConstantsService(this._repository);

  SystemConstant? get currentSystemConstant => _currentSystemConstant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Tax and withholding properties
  double get vatRate => _currentSystemConstant?.rateVatPercentage ?? 0.15;
  double get withholdingRate =>
      _currentSystemConstant?.rateWithPercentage ?? 0.02;
  double get withholdingInitial =>
      _currentSystemConstant?.withHoldInitials ?? 1000.0;

  // Other useful properties
  int get decimalPlaces => _currentSystemConstant?.decimalPlaces ?? 2;
  bool get applyLotManagement => _currentSystemConstant?.applyLotMgm == 'Y';
  bool get autoGenerateBarcode =>
      _currentSystemConstant?.generateBarcodeForItem == 'Y';

  Future<void> loadSystemConstants() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSystemConstant = await _repository
          .getCurrentCompanySystemConstants();
      _error = null;
      developer.log('System constants loaded successfully');
    } on NetworkException catch (e) {
      _error = 'Using offline data: ${e.message}';
      developer.log('Using offline data: ${e.message}');
      if (kDebugMode) {
        print(_error);
      }
    } on ServerException catch (e) {
      _error = 'Server error: ${e.message}';
      developer.log('Server error: ${e.message}');
    } catch (e) {
      _error = 'Failed to load system constants: $e';
      developer.log('Failed to load system constants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSystemConstants() async {
    await loadSystemConstants();
  }

  Future<void> updateSystemConstant(SystemConstant systemConstant) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (systemConstant.id == null) {
        await _repository.createSystemConstant(systemConstant);
      } else {
        await _repository.updateSystemConstant(systemConstant);
      }

      // Reload after update
      await loadSystemConstants();
    } on NetworkException catch (e) {
      _error = 'Updated locally (will sync later): ${e.message}';
    } catch (e) {
      _error = 'Failed to update system constant: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to check if withholding should be applied
  bool shouldApplyWithholding(double subtotal) {
    return subtotal >= withholdingInitial;
  }

  // Helper method to calculate tax amount
  double calculateTaxAmount(double subtotal) {
    return subtotal * vatRate;
  }

  // Helper method to calculate withholding amount
  double calculateWithholdingAmount(double subtotal) {
    if (shouldApplyWithholding(subtotal)) {
      return subtotal * withholdingRate;
    }
    return 0.0;
  }

  // Helper method to format numbers based on decimal places
  String formatNumber(double value) {
    return value.toStringAsFixed(decimalPlaces);
  }
}
