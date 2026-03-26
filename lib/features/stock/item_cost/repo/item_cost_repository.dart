// features/stock/item_cost/repositories/item_cost_repository.dart
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';
import 'package:savvy_stock/features/stock/item_cost/models/paginated_item_cost.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:sqflite/sqflite.dart';

class ItemCostRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final ItemUomConversionsRepository uomConversionRepository;

  ItemCostRepository({
    required this.databaseService,
    required this.uomConversionRepository,
  });

  // Create new item cost
  Future<int> create(ItemCost itemCost, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = itemCost.toMap();
    itemMap.remove('id'); // Remove id for new insertion
    final id = await db.insert('item_cost', itemMap);
    itemMap['id'] = id;
    captureSync(
      tableName: 'item_cost',
      entityMap: itemMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: itemCost.company?.toString(),
    );
    return id;
  }

  // Update existing item cost
  Future<int> update(ItemCost itemCost, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.update(
      'item_cost',
      itemCost.toMap(),
      where: 'id = ?',
      whereArgs: [itemCost.id],
    );
    captureSync(
      tableName: 'item_cost',
      entityMap: itemCost.toMap(),
      entityId: itemCost.id.toString(),
      operation: 'UPDATE',
      company: itemCost.company?.toString(),
    );
    return result;
  }

  // Delete item cost
  Future<int> delete(int id, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemCost = await findById(id);
    final result = await db.delete('item_cost', where: 'id = ?', whereArgs: [id]);
    if (itemCost != null) {
      captureSync(
        tableName: 'item_cost',
        entityMap: {'id': id, 'company': itemCost.company},
        entityId: id.toString(),
        operation: 'DELETE',
        company: itemCost.company?.toString(),
      );
    }
    return result;
  }

  // Delete multiple item costs
  Future<void> deleteMultiple(List<ItemCost> items, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      if (item.id != null) {
        batch.delete('item_cost', where: 'id = ?', whereArgs: [item.id]);
      }
    }

    await batch.commit();
  }

  // Find item cost by ID
  Future<ItemCost?> findById(int id) async {
    final db = await databaseService.database;
    final maps = await db.query('item_cost', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return ItemCost.fromMap(maps.first);
    }
    return null;
  }

  // Find all item costs
  Future<List<ItemCost>> findAll(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''SELECT ic.*,
    i.item_description,
    i.barcode,
    u.user_name as user_name,
    c.company_name as company_name,
    udc.description_1 as unit_of_measure_description,
    udc.detail_code as unit_of_measure_code
    FROM item_cost ic
    LEFT JOIN items_table i ON ic.item_number = i.id
    LEFT JOIN user_table u ON ic.user_id = u.id
    LEFT JOIN company_table c ON ic.company = c.id
    LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
    WHERE ic.company = ?''',
      [companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Find item costs by item number and company
  Future<List<ItemCost>> findByItemNumberAndCompany(
    int itemNumber,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Find item cost by item
  Future<ItemCost?> findByItem(
    int itemNumber,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.rawQuery(
      '''SELECT ic.*,
      i.item_description,
          i.items_id as item_id,
          i.unit_of_measure,
          u.user_name as user_name,
          c.company_name as company_name,
          udc.description_1 as unit_of_measure_description,
          udc.detail_code as unit_of_measure_code
      FROM item_cost ic
      LEFT JOIN items_table i ON ic.item_number = i.id
      LEFT JOIN user_table u ON ic.user_id = u.id
      LEFT JOIN company_table c ON ic.company = c.id
      LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
    WHERE ic.item_number = ? AND ic.company = ?''',
      [itemNumber, companyId],
    );

    if (maps.isNotEmpty) {
      return ItemCost.fromMap(maps.first);
    }
    return null;
  }

  // Execute custom query
  Future<List<ItemCost>> executeCustomQuery(
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''SELECT ic.*,
    i.item_description,
    i.barcode,
    u.user_name as user_name,
    c.company_name as company_name,
    udc.description_1 as unit_of_measure_description,
    udc.detail_code as unit_of_measure_code
    FROM item_cost ic
    LEFT JOIN items_table i ON ic.item_number = i.id
    LEFT JOIN user_table u ON ic.user_id = u.id
    LEFT JOIN company_table c ON ic.company = c.id
    LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
    WHERE $whereClause''', whereArgs);
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Get items with joins for detailed information
  Future<List<Map<String, dynamic>>> findDetailedItemCosts(
    int companyId,
  ) async {
    final db = await databaseService.database;
    return await db.rawQuery(
      '''
      SELECT ic.*, 
             i.item_description, i.barcode,
             u.user_name as user_name,
             c.company_name as company_name,
             udc.description_1 as unit_of_measure_description,
             udc.detail_code as unit_of_measure_code
      FROM item_cost ic
      LEFT JOIN items_table i ON ic.item_number = i.id
      LEFT JOIN user_table u ON ic.user_id = u.id
      LEFT JOIN company_table c ON ic.company = c.id
      LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
      WHERE ic.company = ?
      ORDER BY ic.date_updated DESC
    ''',
      [companyId],
    );
  }

  // Get purchase history for item
  Future<List<ItemCost>> getPurchaseHistory(int itemId, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemId, companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Update multiple item costs in batch
  Future<void> updateBatch(List<ItemCost> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      if (item.id != null) {
        batch.update(
          'item_cost',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }

    await batch.commit();
  }

  // Check if item cost exists for item and company
  Future<bool> existsByItemAndCompany(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<double> calculateItemCost({
    required SalesOrderDetail item,
    required int companyId,
  }) async {
    try {
      // Get standard cost from item cost table
      final itemCost = await findByItemNumberAndCompany(
        item.itemsTableId!,
        companyId,
      );

      double unitCost = 0.0;

      if (itemCost.isNotEmpty) {
        unitCost = itemCost.first.amountUnitCost ?? 0.0;
      } else {
        // Fallback: Use last purchase price or average cost
        final avgCost = await _getAverageCost(item.itemsTableId!, companyId);
        unitCost = avgCost;
      }

      // Apply UOM conversion if needed
      if (item.unitOfMeasure != null &&
          item.itemBranch?.unitOfMeasure != item.unitOfMeasure) {
        unitCost = await _convertCostUOM(
          unitCost,
          item.itemsTableId!,
          item.itemBranch!.unitOfMeasure!,
          item.unitOfMeasure!,
          companyId,
        );
      }

      return unitCost;
    } catch (e) {
      // Fallback to zero cost with error tracking
      return 0.0;
    }
  }

  Future<double> _getAverageCost(int itemId, int companyId) async {
    // Implement average cost calculation based on purchase history
    final purchaseHistory = await getPurchaseHistory(itemId, companyId);

    if (purchaseHistory.isEmpty) return 0.0;

    final totalValue = purchaseHistory.fold(
      0.0,
      (sum, record) =>
          sum + (record.amountUnitCost! * record.fromUOM!.quantityAvailable!),
    );
    final totalQuantity = purchaseHistory.fold(
      0.0,
      (sum, record) => sum + record.fromUOM!.quantityAvailable!,
    );

    return totalQuantity > 0 ? totalValue / totalQuantity : 0.0;
  }

  Future<double> _convertCostUOM(
    double cost,
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    // Get UOM conversion factor and adjust cost
    final conversion = await uomConversionRepository.getConversionFactor(
      itemId,
      fromUomId,
      toUomId,
      companyId,
    );

    return cost * conversion;
  }

  // Calculate total cost for all items in order
  Future<double> calculateTotalOrderCost(List<SalesOrderDetail> items) async {
    double totalCost = 0.0;

    for (final item in items) {
      final unitCost = await calculateItemCost(
        item: item,
        companyId: item.company!,
      );
      totalCost += unitCost * (item.quantity ?? 0.0);
    }

    return totalCost;
  }

  //item cost report method
  Future<PaginatedItemCostResult> getPaginatedItemCosts({
    required int companyId,
    required int page,
    required int pageSize,
    String? sortField,
    bool ascending = true,
  }) async {
    final db = await databaseService.database;

    // Build base query
    var query = '''
      SELECT ic.*,
          i.item_description,
          i.items_id as item_id,
          i.unit_of_measure,
          u.user_name as user_name,
          c.company_name as company_name,
          udc.description_1 as unit_of_measure_description,
          udc.detail_code as unit_of_measure_code
      FROM item_cost ic
      LEFT JOIN items_table i ON ic.item_number = i.id
      LEFT JOIN user_table u ON ic.user_id = u.id
      LEFT JOIN company_table c ON ic.company = c.id
      LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
      WHERE ic.company = ?
    ''';

    final params = <dynamic>[companyId];

    // Add sorting
    if (sortField != null) {
      query += ' ORDER BY $sortField ${ascending ? 'ASC' : 'DESC'}';
    }

    // Add pagination
    query += ' LIMIT ? OFFSET ?';
    params.add(pageSize);
    params.add((page - 1) * pageSize);

    // Execute main query
    final itemsData = await db.rawQuery(query, params);

    // Count total records
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM item_cost WHERE company = ?',
      [companyId],
    );

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Parse results
    final items = itemsData.map((row) {
      return ItemCost.fromMap(row);
    }).toList();

    return PaginatedItemCostResult(items: items, totalCount: totalCount);
  }

  /// Get total quantity available across all branches in primary UOM
  /// This is used for weighted average cost calculation
  Future<double> getTotalAvailabilityInPrimaryUom(
    int itemNumber,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // Get all items_in_branch records for this item
    final branchesResult = await db.query(
      'items_in_branch',
      columns: ['quantity_available', 'unit_of_measure'],
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );

    double totalQtyInPrimary = 0.0;

    for (final branch in branchesResult) {
      final qtyAvailable =
          (branch['quantity_available'] as num?)?.toDouble() ?? 0.0;
      final uomId = branch['unit_of_measure'] as int?;

      if (uomId != null && qtyAvailable > 0) {
        // Convert this branch's quantity to primary UOM
        final factor = await uomConversionRepository.fromOtherToPrimary(
          itemNumber,
          uomId,
          companyId,
          txn: txn,
        );
        totalQtyInPrimary += qtyAvailable * factor;
      }
    }

    return totalQtyInPrimary;
  }

  /// Updates item costs for all details in a purchase order header.
  /// This should be called BEFORE updating stock quantities.
  ///
  /// The cost calculation follows the Java formula:
  /// cost = (w * otherCost / qty + unitCost) / factor
  /// where:
  ///   - w = extendedCost / grossCost (weight of this item in total)
  ///   - otherCost = header's other costs to distribute
  ///   - qty = transaction quantity
  ///   - unitCost = detail's unit cost
  ///   - factor = UOM conversion factor (other to primary)
  Future<void> updatingItemCosts({
    required int headerId,
    required int companyId,
    required int userId,
  }) async {
    try {
      final db = await databaseService.database;

      if (kDebugMode) {
        developer.log('🔄 updatingItemCosts called for header: $headerId');
      }

      // Get header info for other costs and gross cost
      final headerResult = await db.query(
        'purchase_order_header',
        columns: ['amount_other_costs', 'amount_gross'],
        where: 'id = ?',
        whereArgs: [headerId],
      );

      if (headerResult.isEmpty) return;

      final header = headerResult.first;
      final otherCost =
          (header['amount_other_costs'] as num?)?.toDouble() ?? 0.0;
      final grossCost = (header['amount_gross'] as num?)?.toDouble() ?? 1.0;

      // Get all purchase order details for this header
      final detailsResult = await db.rawQuery(
        '''
        SELECT 
          pod.id,
          pod.item_number,
          pod.unit_of_measure,
          pod.unit_cost,
          pod.quantity_transaction,
          pod.amount_extended_cost
        FROM purchase_order_detail pod
        WHERE pod.po_header = ?
        ''',
        [headerId],
      );

      if (kDebugMode) {
        developer.log(
          'found ${detailsResult.length} details for header $headerId',
        );
      }

      for (final detail in detailsResult) {
        final detailId = detail['id'] as int?;
        final itemNumber = detail['item_number'] as int?;
        final unitOfMeasure = detail['unit_of_measure'] as int?;
        final unitCost = (detail['unit_cost'] as num?)?.toDouble() ?? 0.0;
        final qty = (detail['quantity_transaction'] as num?)?.toDouble() ?? 1.0;
        final extendedCost =
            (detail['amount_extended_cost'] as num?)?.toDouble() ?? 0.0;

        if (itemNumber == null || detailId == null) {
          if (kDebugMode) {
            developer.log('⚠️ Skipping detail due to null ID or Item Number');
          }
          continue;
        }

        // Get UOM conversion factor (from transaction UOM to primary UOM)
        double factor = 1.0;
        if (unitOfMeasure != null) {
          factor = await uomConversionRepository.fromOtherToPrimary(
            itemNumber,
            unitOfMeasure,
            companyId,
          );
        }

        // Calculate weighted cost including distributed other costs
        // Java formula: cost = (w * otherCost / qty + unitCost) / factor
        final w = grossCost != 0 ? extendedCost / grossCost : 0.0;
        final cost = qty != 0 ? (w * otherCost / qty + unitCost) / factor : 0.0;

        // Check if any receivers exist for this detail (only update if no receivers yet)
        final receiversResult = await db.rawQuery(
          '''
          SELECT COUNT(*) as count FROM purchase_order_receiver 
          WHERE po_detail = ?
          ''',
          [detailId],
        );

        final receiverCount = (receiversResult.first['count'] as int?) ?? 0;

        // Find existing item cost record
        final existingCostResult = await db.query(
          'item_cost',
          where: 'item_number = ? AND company = ?',
          whereArgs: [itemNumber, companyId],
        );

        // Calculate final unit cost (handle NaN/Infinite)
        double unitCostAvg = 0.0;
        if (!cost.isNaN && !cost.isInfinite) {
          // Round to 2 decimal places
          unitCostAvg = (cost * 100).roundToDouble() / 100;
        }

        if (existingCostResult.isNotEmpty) {
          // Only update if no receivers exist (first time receiving)
          if (receiverCount == 0) {
            // Get existing cost
            final existingCost =
                (existingCostResult.first['amount_unit_cost'] as num?)
                    ?.toDouble() ??
                0.0;

            // Get total quantity available in primary UOM across all branches
            final qtyOld = await getTotalAvailabilityInPrimaryUom(
              itemNumber,
              companyId,
            );

            // Calculate new quantity in primary UOM
            final qtyTrn = factor * qty;

            // Calculate total quantity
            final qtyTotal = qtyOld + qtyTrn;

            // Calculate weighted average cost
            double finalCost;
            if (qtyTotal > 0) {
              final amountOld = existingCost * qtyOld;
              final amountNew = unitCostAvg * qtyTrn;
              finalCost = (amountOld + amountNew) / qtyTotal;
              // Round to 2 decimal places
              finalCost = (finalCost * 100).roundToDouble() / 100;
            } else {
              // No inventory, use new cost
              finalCost = unitCostAvg;
            }

            if (kDebugMode) {
              developer.log(
                '💰 Weighted Average Calculation:\n'
                '   Old Cost: \$${existingCost.toStringAsFixed(2)}, Old Qty: ${qtyOld.toStringAsFixed(2)}\n'
                '   New Cost: \$${unitCostAvg.toStringAsFixed(2)}, New Qty: ${qtyTrn.toStringAsFixed(2)}\n'
                '   Total Qty: ${qtyTotal.toStringAsFixed(2)}\n'
                '   Average Cost: \$${finalCost.toStringAsFixed(2)}',
              );
            }

            await db.update(
              'item_cost',
              {
                'amount_unit_cost': finalCost,
                'date_updated': DateTime.now().toIso8601String(),
                'user_id': userId,
              },
              where: 'item_number = ? AND company = ?',
              whereArgs: [itemNumber, companyId],
            );

            captureSync(
              tableName: 'item_cost',
              entityMap: {
                'item_number': itemNumber,
                'amount_unit_cost': finalCost,
                'company': companyId,
                'user_id': userId,
                'date_updated': DateTime.now().toIso8601String(),
              },
              entityId: itemNumber.toString(),
              operation: 'UPDATE',
              company: companyId.toString(),
            );

            if (kDebugMode) {
              developer.log(
                '✅ Updated item cost for item $itemNumber to $unitCostAvg',
              );
            }
          } else {
            if (kDebugMode) {
              developer.log(
                'ℹ️ Skipped item cost update for item $itemNumber. Receivers exist: $receiverCount',
              );
            }
          }
        } else {
          // Create new item cost record
          await db.insert('item_cost', {
            'item_number': itemNumber,
            'amount_unit_cost': unitCostAvg,
            'company': companyId,
            'user_id': userId,
            'date_updated': DateTime.now().toIso8601String(),
          });

          captureSync(
            tableName: 'item_cost',
            entityMap: {
              'item_number': itemNumber,
              'amount_unit_cost': unitCostAvg,
              'company': companyId,
              'user_id': userId,
              'date_updated': DateTime.now().toIso8601String(),
            },
            entityId: itemNumber.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
          );

          if (kDebugMode) {
            developer.log(
              '✅ Created new item cost for item $itemNumber: $unitCostAvg',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error updating item costs: $e');
      }
      rethrow;
    }
  }
}
