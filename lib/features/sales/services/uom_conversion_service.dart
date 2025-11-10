// features/sales/services/uom_conversion_service.dart
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class UOMConversionResult {
  final double convertedQuantity;
  final double conversionFactor;
  final UdcDetails fromUOM;
  final UdcDetails toUOM;
  final bool isSuccess;

  const UOMConversionResult({
    required this.convertedQuantity,
    required this.conversionFactor,
    required this.fromUOM,
    required this.toUOM,
    required this.isSuccess,
  });
}

class UOMConversionService {
  final ItemUomConversionsRepository conversionRepository;

  UOMConversionService({required this.conversionRepository});

  Future<UOMConversionResult> convertQuantity({
    required int itemId,
    required double quantity,
    required UdcDetails fromUOM,
    required UdcDetails toUOM,
    required int companyId,
  }) async {
    try {
      // Same UOM - no conversion needed
      if (fromUOM.id == toUOM.id) {
        return UOMConversionResult(
          convertedQuantity: quantity,
          conversionFactor: 1.0,
          fromUOM: fromUOM,
          toUOM: toUOM,
          isSuccess: true,
        );
      }

      // Get conversion factor from database
      final conversion = await conversionRepository.getConversionFactor(
        itemId,
        fromUOM.id,
        toUOM.id,
        companyId,
      );

      final convertedQuantity = quantity * conversion;

      return UOMConversionResult(
        convertedQuantity: convertedQuantity,
        conversionFactor: conversion,
        fromUOM: fromUOM,
        toUOM: toUOM,
        isSuccess: true,
      );
    } catch (e) {
      // Return error result
      return UOMConversionResult(
        convertedQuantity: quantity,
        conversionFactor: 1.0,
        fromUOM: fromUOM,
        toUOM: toUOM,
        isSuccess: false,
      );
    }
  }

  // Convert price based on UOM
  Future<double> convertPrice({
    required int itemId,
    required double price,
    required int fromUomId,
    required int toUomId,
    required int companyId,
  }) async {
    try {
      if (fromUomId == toUomId) return price;

      final conversion = await conversionRepository.getConversionFactor(
        itemId,
        fromUomId,
        toUomId,
        companyId,
      );

      return price * conversion;
    } catch (e) {
      return price;
    }
  }

  // Get all available UOMs for an item
  Future<List<ItemUomConversion>> getAvailableUOMsForItem(
    int itemId,
    int companyId,
  ) async {
    return await conversionRepository.getItemUomConversionsByItem(
      itemId,
      companyId,
    );
  }

  // Validate if conversion is possible
  Future<bool> validateUOMConversion({
    required int itemId,
    required int fromUomId,
    required int toUomId,
    required int companyId,
  }) async {
    if (fromUomId == toUomId) return true;

    final conversion = await conversionRepository.getConversionFactor(
      itemId,
      fromUomId,
      toUomId,
      companyId,
    );

    return conversion != null;
  }
}
