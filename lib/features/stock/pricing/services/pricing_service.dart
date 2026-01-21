// features/stock/pricing/services/pricing_service.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';

/// Service for automatic pricing based on margin plans
/// Implements cascading priority: Item Branch → Item → Location → Branch → Company
class PricingService {
  final LocalDatabaseService databaseService;
  final ItemUomConversionsRepository uomConversionRepository;
  final SystemConstantsService systemConstantService;
  final LotMasterRepository lotMasterRepository;

  PricingService({
    required this.databaseService,
    required this.uomConversionRepository,
    required this.systemConstantService,
    required this.lotMasterRepository,
  });

  /// Updates unit prices based on item cost and margin plans
  ///
  /// This is called after item cost updates during purchase order receipt.
  /// Only runs if autoSalesPrice system constant is enabled.
  ///
  /// Priority order for margin plans:
  /// 1. Item Branch level
  /// 2. Item level
  /// 3. Location level
  /// 4. Branch level
  /// 5. Company level
  Future<void> unitPriceUpdate({
    required ItemCost itemCost,
    required PurchaseOrderReceiver receiver,
    required int companyId,
    required int userId,
  }) async {
    try {
      // Ensure system constants are loaded before checking
      await systemConstantService.ensureLoaded();

      // Check if auto pricing is enabled
      final isAutoSalesPriceEnabled = systemConstantService.autoSalesPrice;

      if (kDebugMode) {
        developer.log(
          '🔍 Auto pricing check: autoSalesPrice=$isAutoSalesPriceEnabled',
        );
      }

      if (!isAutoSalesPriceEnabled) {
        if (kDebugMode) {
          developer.log('ℹ️ Auto pricing disabled, skipping unit price update');
        }
        return;
      }

      // Validate inputs
      if (itemCost.id == null ||
          itemCost.amountUnitCost == null ||
          itemCost.amountUnitCost == 0.0 ||
          receiver.id == null) {
        if (kDebugMode) {
          developer.log('⚠️ Invalid inputs for unit price update');
        }
        return;
      }

      if (kDebugMode) {
        developer.log(
          '🔄 unitPriceUpdate: item=${itemCost.itemNumber}, cost=${itemCost.amountUnitCost}',
        );
      }

      double? calculatedPrice;
      String? source;

      // Step 1: Check Item Branch level margin
      if (kDebugMode) {
        developer.log(
          '🔍 Step 1: Checking Item Branch margin for item=${itemCost.itemNumber}, branch=${receiver.branchRecieved}',
        );
      }

      final itemBranch = await _getItemBranch(
        itemCost.itemNumber!,
        receiver.branchRecieved ?? 0,
        companyId,
      );

      if (kDebugMode) {
        developer.log(
          '   Item Branch found: ${itemBranch != null}, marginType: ${itemBranch?['margin_type']}, marginRate: ${itemBranch?['margin_rate']}',
        );
      }

      if (itemBranch != null &&
          itemBranch['margin_type'] != null &&
          itemBranch['margin_rate'] != null &&
          (itemBranch['margin_rate'] as num) != 0.0) {
        // Calculate price with UOM conversion
        calculatedPrice = await _calculatePriceWithUomConversion(
          baseCost: itemCost.amountUnitCost!,
          marginType: itemBranch['margin_type'] as String,
          marginRate: (itemBranch['margin_rate'] as num).toDouble(),
          itemNumber: itemCost.itemNumber!,
          fromUomId: itemCost.itemNumber!, // item's primary UOM
          toUomId: itemBranch['unit_of_measure'] as int?,
        );
        source = 'Item Branch';

        // Update only item branch
        if (calculatedPrice != null) {
          await _updateItemBranchPrice(
            itemBranchId: itemBranch['id'] as int,
            unitPrice: calculatedPrice,
            companyId: companyId,
            itemNumber: itemCost.itemNumber!,
            branchId: receiver.branchRecieved ?? 0,
          );
        }
      }
      // Step 2: Check Item level margin
      else {
        if (kDebugMode) {
          developer.log(
            '🔍 Step 2: Checking Item margin for item=${itemCost.itemNumber}',
          );
        }

        final item = await _getItem(itemCost.itemNumber!, companyId);

        if (kDebugMode) {
          developer.log(
            '   Item found: ${item != null}, marginType: ${item?['margin_type']}, marginRate: ${item?['margin_rate']}',
          );
        }

        if (item != null &&
            item['margin_type'] != null &&
            item['margin_rate'] != null &&
            (item['margin_rate'] as num) != 0.0) {
          calculatedPrice = _calculatePrice(
            baseCost: itemCost.amountUnitCost!,
            marginType: item['margin_type'] as String,
            marginRate: (item['margin_rate'] as num).toDouble(),
          );
          source = 'Item';

          // Update item and all item branches
          if (calculatedPrice != null) {
            await _updateItemAndAllBranches(
              itemNumber: itemCost.itemNumber!,
              unitPrice: calculatedPrice,
              companyId: companyId,
            );
          }
        }
        // Step 3: Check Location level margin
        else if (receiver.location != null) {
          if (kDebugMode) {
            developer.log(
              '🔍 Step 3: Checking Location margin for location=${receiver.location}',
            );
          }

          final location = await _getLocation(receiver.location!, companyId);

          if (kDebugMode) {
            developer.log(
              '   Location found: ${location != null}, marginType: ${location?['margin_type']}, marginRate: ${location?['margin_rate']}',
            );
          }

          if (location != null &&
              location['margin_type'] != null &&
              location['margin_rate'] != null &&
              (location['margin_rate'] as num) != 0.0) {
            calculatedPrice = _calculatePrice(
              baseCost: itemCost.amountUnitCost!,
              marginType: location['margin_type'] as String,
              marginRate: (location['margin_rate'] as num).toDouble(),
            );
            source = 'Location';

            // Update item and all item branches
            if (calculatedPrice != null) {
              await _updateItemAndAllBranches(
                itemNumber: itemCost.itemNumber!,
                unitPrice: calculatedPrice,
                companyId: companyId,
              );
            }
          }
          // Step 4: Check Branch level margin
          else if (receiver.branchRecieved != null) {
            if (kDebugMode) {
              developer.log(
                '🔍 Step 4: Checking Branch margin for branch=${receiver.branchRecieved}',
              );
            }

            final branch = await _getBranch(
              receiver.branchRecieved!,
              companyId,
            );

            if (kDebugMode) {
              developer.log(
                '   Branch found: ${branch != null}, marginType: ${branch?['margin_type']}, marginRate: ${branch?['margin_rate']}',
              );
            }

            if (branch != null &&
                branch['margin_type'] != null &&
                branch['margin_rate'] != null &&
                (branch['margin_rate'] as num) != 0.0) {
              calculatedPrice = _calculatePrice(
                baseCost: itemCost.amountUnitCost!,
                marginType: branch['margin_type'] as String,
                marginRate: (branch['margin_rate'] as num).toDouble(),
              );
              source = 'Branch';

              // Update item branches for this branch only
              if (calculatedPrice != null) {
                await _updateItemBranchesByBranch(
                  itemNumber: itemCost.itemNumber!,
                  branchId: receiver.branchRecieved!,
                  unitPrice: calculatedPrice,
                  companyId: companyId,
                );
              }
            }
            // Step 5: Check Company level margin
            else {
              if (kDebugMode) {
                developer.log(
                  '🔍 Step 5: Checking Company margin for company=$companyId',
                );
              }

              final company = await _getCompany(companyId);

              if (kDebugMode) {
                developer.log(
                  '   Company found: ${company != null}, marginType: ${company?['margin_type']}, marginRate: ${company?['margin_rate']}',
                );
              }

              if (company != null &&
                  company['margin_type'] != null &&
                  company['margin_rate'] != null &&
                  (company['margin_rate'] as num) != 0.0) {
                calculatedPrice = _calculatePrice(
                  baseCost: itemCost.amountUnitCost!,
                  marginType: company['margin_type'] as String,
                  marginRate: (company['margin_rate'] as num).toDouble(),
                );
                source = 'Company';

                // Update item and all item branches
                if (calculatedPrice != null) {
                  await _updateItemAndAllBranches(
                    itemNumber: itemCost.itemNumber!,
                    unitPrice: calculatedPrice,
                    companyId: companyId,
                  );
                }
              }
            }
          }
        }
      }

      if (kDebugMode && calculatedPrice != null) {
        developer.log(
          '✅ Updated unit price: \$${calculatedPrice.toStringAsFixed(2)} (source: $source)',
        );
      } else if (kDebugMode) {
        developer.log(
          '⚠️ No margin plan found at any level - unit price NOT updated',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error in unitPriceUpdate: $e');
      }
      // Don't rethrow - pricing is not critical to receipt process
    }
  }

  double? _calculatePrice({
    required double baseCost,
    required String marginType,
    required double marginRate,
  }) {
    double price;

    if (kDebugMode) {
      developer.log(
        '💰 Calculating price: baseCost=$baseCost, marginType=$marginType, marginRate=$marginRate',
      );
    }

    switch (marginType) {
      case 'F': // Flat
        price = baseCost + marginRate;
        break;
      case 'P': // Percentage
        price = baseCost * (1 + marginRate / 100.0);
        break;
      default:
        if (kDebugMode) {
          developer.log(
            '❌ Unknown margin type: "$marginType" (expected "P" or "F")',
          );
        }
        return null;
    }

    // Round to 2 decimal places
    return (price * 100).roundToDouble() / 100;
  }

  /// Calculate price with UOM conversion
  Future<double?> _calculatePriceWithUomConversion({
    required double baseCost,
    required String marginType,
    required double marginRate,
    required int itemNumber,
    required int fromUomId,
    int? toUomId,
  }) async {
    double adjustedCost = baseCost;

    // Apply UOM conversion if needed
    if (toUomId != null && toUomId != fromUomId) {
      try {
        final conversionFactor = await uomConversionRepository
            .fromOtherToAnother(
              itemNumber,
              fromUomId,
              toUomId,
              await databaseService.database.then((db) async {
                final result = await db.query(
                  'items_table',
                  columns: ['company'],
                  where: 'id = ?',
                  whereArgs: [itemNumber],
                );
                return (result.first['company'] as int?) ?? 0;
              }),
            );
        adjustedCost = baseCost * conversionFactor;
      } catch (e) {
        if (kDebugMode) {
          developer.log('⚠️ UOM conversion failed, using base cost: $e');
        }
      }
    }

    return _calculatePrice(
      baseCost: adjustedCost,
      marginType: marginType,
      marginRate: marginRate,
    );
  }

  // Database query helpers

  Future<Map<String, dynamic>?> _getItemBranch(
    int itemNumber,
    int branchId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.query(
      'items_in_branch',
      where: 'item_number = ? AND branch = ? AND company = ?',
      whereArgs: [itemNumber, branchId, companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> _getItem(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final result = await db.query(
      'items_table',
      where: 'id = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> _getLocation(
    int locationId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.query(
      'location_master',
      where: 'id = ? AND company = ?',
      whereArgs: [locationId, companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> _getBranch(int branchId, int companyId) async {
    final db = await databaseService.database;
    final result = await db.query(
      'branch_table',
      where: 'id = ? AND company = ?',
      whereArgs: [branchId, companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> _getCompany(int companyId) async {
    final db = await databaseService.database;
    final result = await db.query(
      'company_table',
      where: 'id = ?',
      whereArgs: [companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update methods

  Future<void> _updateItemBranchPrice({
    required int itemBranchId,
    required double unitPrice,
    required int companyId,
    required int itemNumber,
    required int branchId,
  }) async {
    final db = await databaseService.database;
    await db.update(
      'items_in_branch',
      {'unit_price': unitPrice},
      where: 'id = ? AND company = ?',
      whereArgs: [itemBranchId, companyId],
    );

    // Sync lot prices
    await lotMasterRepository.updateUnitPriceByItemAndBranch(
      itemNumber: itemNumber,
      branch: branchId,
      unitPrice: unitPrice,
      companyId: companyId,
    );

    if (kDebugMode) {
      developer.log('✅ Item branch price updated successfully');
    }
  }

  Future<void> _updateItemAndAllBranches({
    required int itemNumber,
    required double unitPrice,
    required int companyId,
  }) async {
    final db = await databaseService.database;

    // Update item master
    await db.update(
      'items_table',
      {'unit_price': unitPrice},
      where: 'id = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );

    // Update all item branches
    await db.update(
      'items_in_branch',
      {'unit_price': unitPrice},
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );

    // Sync lot prices
    await lotMasterRepository.updateUnitPriceByItem(
      itemNumber: itemNumber,
      unitPrice: unitPrice,
      companyId: companyId,
    );
  }

  Future<void> _updateItemBranchesByBranch({
    required int itemNumber,
    required int branchId,
    required double unitPrice,
    required int companyId,
  }) async {
    final db = await databaseService.database;
    await db.update(
      'items_in_branch',
      {'unit_price': unitPrice},
      where: 'item_number = ? AND branch = ? AND company = ?',
      whereArgs: [itemNumber, branchId, companyId],
    );

    // Sync lot prices
    await lotMasterRepository.updateUnitPriceByItemAndBranch(
      itemNumber: itemNumber,
      branch: branchId,
      unitPrice: unitPrice,
      companyId: companyId,
    );
  }
}
