import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/errors/exceptions.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_repository.dart';

class SystemConstantsService with ChangeNotifier {
  final SystemConstantRepository _repository;
  SystemConstant? _currentSystemConstant;
  bool _isLoading = false;
  String? _error;

  // Add stream controller for bloc integration
  final StreamController<SystemConstant?> _streamController =
      StreamController<SystemConstant?>.broadcast();

  SystemConstantsService(this._repository);

  SystemConstant? get currentSystemConstant => _currentSystemConstant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add stream for bloc integration
  Stream<SystemConstant?> get systemConstantsStream => _streamController.stream;

  // Tax and withholding properties with better null safety
  double get vatRate => _currentSystemConstant?.rateVatPercentage ?? 15.0;
  double get withholdingRate =>
      _currentSystemConstant?.rateWithholdingPercentage ?? 2.0;
  double get withholdingInitial =>
      _currentSystemConstant?.withHoldInitials ?? 1000.0;

  // Other useful properties
  int get decimalPlaces => _currentSystemConstant?.decimalPlaces ?? 2;
  bool get applyLotManagement => _currentSystemConstant?.applyLotMgm == 'Y';
  bool get autoGenerateBarcode =>
      _currentSystemConstant?.generateBarcodeForItem == 'Y';
  bool get autoSalesPrice => _currentSystemConstant?.autoSalesPrice == 'Y';
  bool get lotQtyAutoForSales =>
      _currentSystemConstant?.lotQtyAutoForSales == 'Y';
  bool get discountDisplay => _currentSystemConstant?.discountDisplay == 'Y';
  bool get taxInfoDisplay => _currentSystemConstant?.taxInfoDisplay == 'Y';
  bool get reorderPointUomType =>
      _currentSystemConstant?.reorderPointUomType == 'I';
  int get locationCategoryLevel =>
      _currentSystemConstant?.locationCategoryLevel ?? 1;
  bool get applyLocationManagement =>
      _currentSystemConstant?.applyLocationMgm == 'Y';

  Future<void> _loadSystemConstants() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSystemConstant = await _repository
          .getCurrentCompanySystemConstants();

      developer.log(
        'Loaded system constants from database: ${_currentSystemConstant?.toJson()}',
      );

      // If still null, create a default and save it
      if (_currentSystemConstant == null) {
        developer.log('No system constants found, creating default...');
        final companyId = await _repository.getCurrentCompanySystemConstants();
        _currentSystemConstant = SystemConstant(
          company: companyId.id,
          applyLotMgm: 'N',
          applyLocationMgm: 'Y',
          decimalPlaces: 2,
          rateVatPercentage: 15.0,
          rateWithholdingPercentage: 2.0,
          withHoldInitials: 1000.0,
          autoSalesPrice: 'N',
          generateBarcodeForItem: 'N',
          lotQtyAutoForSales: 'Y',
          discountDisplay: 'N',
          taxInfoDisplay: 'N',
          reorderPointUomType: 'I',
          locationCategoryLevel: 1,
          isSynced: false,
        );

        // Save to database
        await _repository.createSystemConstant(_currentSystemConstant!);
      }

      developer.log(
        'System constants loaded: ${_currentSystemConstant?.toJson()}',
      );

      _error = null;
      notifyListeners();

      // Notify stream listeners
      _streamController.add(_currentSystemConstant);
    } on NetworkException catch (e) {
      _error = 'Using offline data: ${e.message}';
      developer.log('Using offline data: ${e.message}');

      // Even in error, try to get local data
      try {
        _currentSystemConstant = await _getLocalSystemConstants();
        _streamController.add(_currentSystemConstant);
      } catch (localError) {
        _error = 'Completely offline: $localError';
        _streamController.addError(localError);
      }
    } on ServerException catch (e) {
      _error = 'Server error: ${e.message}';
      developer.log('Server error: ${e.message}');
      _streamController.addError(e);
    } catch (e) {
      _error = 'Failed to load system constants: $e';
      developer.log('Failed to load system constants: $e');
      _streamController.addError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get local constants as fallback
  Future<SystemConstant> _getLocalSystemConstants() async {
    try {
      final constants = await _repository.getLocalSystemConstants();
      if (constants.isNotEmpty) {
        return constants.first;
      }
      throw Exception('No local system constants found');
    } catch (e) {
      // Return a default if everything fails
      // Return a default if everything fails
      final defaultConstant = SystemConstant(
        applyLotMgm: 'N',
        applyLocationMgm: 'Y',
        decimalPlaces: 2,
        rateVatPercentage: 15.0,
        rateWithholdingPercentage: 2.0,
        withHoldInitials: 1000.0,
        autoSalesPrice: 'N',
        generateBarcodeForItem: 'N',
        lotQtyAutoForSales: 'Y',
        discountDisplay: 'N',
        taxInfoDisplay: 'N',
        reorderPointUomType: 'I',
        locationCategoryLevel: 1,
        // Ensure company ID is set if possible, or handle it upstream
        company: 1, // Default company ID or fetch from auth if possible
      );

      // Try to persist this default so we don't keep creating it
      try {
        await _repository.createSystemConstant(defaultConstant);
      } catch (e) {
        developer.log('Failed to persist default constants: $e');
      }

      return defaultConstant;
    }
  }

  Future<void> refreshSystemConstants() async {
    await _loadSystemConstants();
  }

  Future<void> updateSystemConstant(SystemConstant systemConstant) async {
    _isLoading = true;
    _currentSystemConstant = systemConstant;
    notifyListeners();

    try {
      if (systemConstant.id == null) {
        await _repository.createSystemConstant(systemConstant);
      } else {
        await _repository.updateSystemConstant(systemConstant);
      }

      // Reload after update
      await _loadSystemConstants();
    } on NetworkException catch (e) {
      _error = 'Updated locally (will sync later): ${e.message}';
      // Still update local reference
      _currentSystemConstant = systemConstant;
      _streamController.add(_currentSystemConstant);
    } catch (e) {
      _error = 'Failed to update system constant: $e';
      _streamController.addError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
    _currentSystemConstant = null;
    _isLoading = false;
  }

  // Improved helper methods with error handling
  bool shouldApplyWithholding(double subtotal) {
    try {
      return subtotal >= withholdingInitial;
    } catch (e) {
      developer.log('Error in shouldApplyWithholding: $e');
      return false;
    }
  }

  double calculateTaxAmount(double subtotal) {
    try {
      return subtotal * (vatRate / 100);
    } catch (e) {
      developer.log('Error in calculateTaxAmount: $e');
      return 0.0;
    }
  }

  double calculateWithholdingAmount(double subtotal) {
    try {
      if (shouldApplyWithholding(subtotal)) {
        return (subtotal * (withholdingRate / 100));
      }
      return 0.0;
    } catch (e) {
      developer.log('Error in calculateWithholdingAmount: $e');
      return 0.0;
    }
  }

  double roundToDecimalPlaces(double value, int decimalPlaces) {
    try {
      final factor = pow(10, decimalPlaces);
      return (value * factor).round() / factor;
    } catch (e) {
      developer.log('Error in formatNumber: $e');
      return value;
    }
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  // Ensure system constants are loaded before use
  Future<void> ensureLoaded() async {
    if (_currentSystemConstant == null && !_isLoading) {
      await _loadSystemConstants();
    }
  }
}
