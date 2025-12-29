import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/repo/next_number_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/models/item_master_model.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/repo/item_master_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/stock/location_entry/repo/location_master_repository.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:sqflite/sqflite.dart';

class MigrationService {
  final AuthBloc authBloc;
  final StockItemsEntryRepository itemsEntryRepository;
  final LocationMasterRepository locationMasterRepository;
  final StockItemInBranchRepository itemsInBranchRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final LotMasterRepository lotMasterRepository;
  final ItemCostRepository itemCostRepository;
  final ItemMasterRepository itemMasterRepository;
  final UdcRepository udcRepository;
  final NextNumberRepository nextNumberRepository;
  final SystemConstantBloc systemConstantBloc;
  final LocalDatabaseService databaseService;

  MigrationService({
    required this.authBloc,
    required this.itemsEntryRepository,
    required this.locationMasterRepository,
    required this.itemsInBranchRepository,
    required this.itemLocationsRepository,
    required this.lotMasterRepository,
    required this.itemCostRepository,
    required this.itemMasterRepository,
    required this.udcRepository,
    required this.nextNumberRepository,
    required this.systemConstantBloc,
    required this.databaseService,
  });

  /// Main migration method with proper error handling
  Future<MigrationResult> applyMigration(ItemMaster item) async {
    // Validate input before starting transaction
    final validationResult = _validateMigrationInput(item);
    if (!validationResult.isValid) {
      return MigrationResult(
        success: false,
        message: validationResult.errorMessage!,
      );
    }

    final db = await databaseService.database;

    try {
      return await db.transaction((txn) async {
        try {
          final companyId = authBloc.state.companyId;
          final userId = authBloc.state.userId;

          if (companyId == null || userId == null) {
            throw Exception(
              'User not authenticated - Company ID: $companyId, User ID: $userId',
            );
          }

          print('🔄 Starting migration for: ${item.itemDescription}');

          // Step 1: Create/Update ItemsTable
          final itemsTable = await _processItemsTable(
            item,
            companyId,
            userId.id,
            txn,
          );
          if (itemsTable == null) {
            throw Exception(
              'Failed to process ItemsTable - no items table created',
            );
          }

          // Step 2: Update Item Costs
          await _updateItemCosts(item, itemsTable, txn);

          // Step 3: Create/Update LocationMaster
          final locationMaster = await _processLocationMaster(
            item,
            companyId,
            userId.id,
            txn,
          );
          if (locationMaster == null) {
            throw Exception('Failed to process LocationMaster');
          }

          // Step 4: Create/Update ItemsInBranch
          final itemsInBranch = await _processItemsInBranch(
            item,
            itemsTable.id,
            companyId,
            txn,
          );
          if (itemsInBranch == null) {
            throw Exception('Failed to process ItemsInBranch');
          }

          // Step 5: Create/Update ItemLocations
          final itemLocations = await _processItemLocations(
            item,
            itemsTable.id,
            locationMaster.id!,
            companyId,
            userId.id,
            txn,
          );
          if (itemLocations == null) {
            throw Exception('Failed to process ItemLocations');
          }

          // Step 6: Create/Update LotMaster if applicable
          if (_shouldCreateLotMaster(item)) {
            final lotMaster = await _processLotMaster(
              item,
              itemsTable.id,
              itemLocations.id!,
              companyId,
              userId.id,
              txn,
            );
            if (lotMaster == null) {
              throw Exception('Failed to process LotMaster');
            }
          }

          print(
            '✅ Migration completed successfully for: ${item.itemDescription}',
          );

          return MigrationResult(
            success: true,
            message: 'Migration applied successfully',
          );
        } catch (e) {
          // This will trigger transaction rollback
          print('❌ Migration transaction failed: $e');
          rethrow; // Important: rethrow to ensure transaction rollback
        }
      });
    } catch (e) {
      print('❌ Migration failed with rollback: $e');
      return MigrationResult(success: false, message: 'Migration failed: $e');
    }
  }

  /// Step 1: Process ItemsTable with proper null safety
  Future<ItemEntryModel?> _processItemsTable(
    ItemMaster item,
    int companyId,
    int userId,
    Transaction? txn,
  ) async {
    try {
      // Safe null checking
      if (item.itemDescription == null || item.itemDescription!.isEmpty) {
        throw Exception('Item description is required');
      }

      final existingItems = await itemsEntryRepository.findByItemDescription(
        item.itemDescription!,
        companyId,
        txn: txn,
      );

      if (existingItems != null) {
        print('📦 Using existing ItemsTable: ${item.itemDescription}');
        return existingItems;
      } else {
        final newItemsTable = await _createItemsTable(
          item,
          companyId,
          userId,
          txn,
        );
        print('📦 Created new ItemsTable: ${item.itemDescription}');
        return newItemsTable;
      }
    } catch (e) {
      print('❌ Error processing ItemsTable: $e');
      rethrow;
    }
  }

  /// Create new ItemsTable entry with proper validation
  Future<ItemEntryModel> _createItemsTable(
    ItemMaster item,
    int companyId,
    int userId,
    Transaction? txn,
  ) async {
    // Validate required fields
    if (item.defualtUom == null) {
      throw Exception('Default UoM is required');
    }

    final itemsTable = ItemEntryModel(
      id: 0,
      itemsId: item.itemDescription,
      itemDescription: item.itemDescription,
      unitOfMeasure: item.defualtUom.toString(),
      unitPrice: item.unitPrice ?? 0.0,
      taxable: item.taxableFlag ?? 'Y',
      company: companyId,
    );

    // Check if barcode should be generated
    final systemConstant = systemConstantBloc.state.selected;
    if (systemConstant?.generateBarcodeForItemBoolean == true) {
      final barcode = await itemsEntryRepository.generateUniqueBarcode(
        companyId,
        txn: txn,
      );
      itemsTable.barcode = barcode;
    }

    final id = await itemsEntryRepository.create(itemsTable, txn: txn);
    return itemsTable.copyWith(id: id);
  }

  /// Step 2: Update Item Costs with proper error handling
  Future<void> _updateItemCosts(
    ItemMaster item,
    ItemEntryModel itemsTable,
    Transaction? txn,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not available');

      final existingItemCost = await itemCostRepository
          .findByItemNumberAndCompany(itemsTable.id, companyId, txn: txn);

      final itemCost = ItemCost(
        itemNumber: itemsTable.id,
        amountUnitCost: item.unitCost ?? 0.0,
        company: companyId,
        dateUpdated: DateTime.now(),
      );

      if (existingItemCost.isNotEmpty) {
        final updatedCost = existingItemCost.first.copyWith(
          amountUnitCost: item.unitCost ?? 0.0,
        );
        await itemCostRepository.update(updatedCost, txn: txn);
        print('💰 Updated item costs for: ${item.itemDescription}');
      } else {
        await itemCostRepository.create(itemCost, txn: txn);
        print('💰 Created item costs for: ${item.itemDescription}');
      }
    } catch (e) {
      print('❌ Error updating item costs: $e');
      rethrow;
    }
  }

  /// Step 3: Process LocationMaster with proper typing
  Future<LocationMaster?> _processLocationMaster(
    ItemMaster item,
    int companyId,
    int userId,
    Transaction? txn,
  ) async {
    try {
      if (item.branch == null) {
        throw Exception('Branch is required for LocationMaster');
      }

      final locationDescription = _generateLocationDescription(item);
      final existingLocation = await locationMasterRepository
          .getLocationsByBranch(
            locationDescription,
            item.branch!,
            companyId,
            txn: txn,
          );

      if (existingLocation.isNotEmpty) {
        print('📍 Using existing LocationMaster: $locationDescription');
        return existingLocation.first;
      } else {
        final newLocation = await _createLocationMaster(
          item,
          companyId,
          userId,
          txn,
        );
        print('📍 Created new LocationMaster: $locationDescription');
        return newLocation;
      }
    } catch (e) {
      print('❌ Error processing LocationMaster: $e');
      rethrow;
    }
  }

  /// Create new LocationMaster with proper model usage
  Future<LocationMaster> _createLocationMaster(
    ItemMaster item,
    int companyId,
    int userId,
    Transaction? txn,
  ) async {
    final locationDescription = _generateLocationDescription(item);

    final locationMaster = LocationMaster(
      branch: item.branch!,
      code01: item.locationCode1,
      code02: item.locationCode2,
      code03: item.locationCode3,
      code04: item.locationCode4,
      code05: item.locationCode5,
      code06: item.locationCode6,
      code07: item.locationCode7,
      code08: item.locationCode8,
      code09: item.locationCode9,
      code10: item.locationCode10,
      locationDescription: locationDescription,
      company: companyId,
      createdBy: userId,
      dateCreated: DateTime.now(),
    );

    final id = await locationMasterRepository.createLocationMaster(
      locationMaster,
      userId,
      companyId,
      txn: txn,
    );

    return locationMaster.copyWith(id: id);
  }

  /// Step 4: Process ItemsInBranch with proper typing
  Future<ItemInBranchModel?> _processItemsInBranch(
    ItemMaster item,
    int itemNumber,
    int companyId,
    Transaction? txn,
  ) async {
    try {
      if (item.branch == null) {
        throw Exception('Branch is required for ItemsInBranch');
      }

      final existingItemsInBranch = await itemsInBranchRepository
          .findByItemAndBranch(itemNumber, item.branch!, companyId, txn: txn);

      final itemsInBranch = ItemInBranchModel(
        id: 0,
        branch: item.branch!,
        itemNumber: itemNumber,
        unitPrice: item.unitPrice ?? 0.0,
        unitOfMeasure: item.defualtUom,
        quantityAvailable: item.quantity ?? 0.0,
        company: companyId,
      );

      if (existingItemsInBranch != null && item.quantity != null) {
        final updatedItem = existingItemsInBranch.copyWith(
          quantityAvailable:
              (existingItemsInBranch.quantityAvailable ?? 0.0) + item.quantity!,
          unitPrice: item.unitPrice ?? existingItemsInBranch.unitPrice,
        );

        await itemsInBranchRepository.update(updatedItem, txn: txn);
        print('🏬 Updated ItemsInBranch for: ${item.itemDescription}');
        return updatedItem;
      } else if (existingItemsInBranch == null) {
        final id = await itemsInBranchRepository.create(
          itemsInBranch,
          txn: txn,
        );
        print('🏬 Created new ItemsInBranch for: ${item.itemDescription}');
        return itemsInBranch.copyWith(id: id);
      }

      return existingItemsInBranch;
    } catch (e) {
      print('❌ Error processing ItemsInBranch: $e');
      rethrow;
    }
  }

  /// Step 5: Process ItemLocations with proper typing
  Future<ItemLocation?> _processItemLocations(
    ItemMaster item,
    int itemNumber,
    int locationId,
    int companyId,
    int userId,
    Transaction? txn,
  ) async {
    try {
      if (item.branch == null) {
        throw Exception('Branch is required for ItemLocations');
      }

      final existingItemLocations = await itemLocationsRepository
          .getItemLocationsByBranchAndItem(
            branchId: item.branch!,
            itemId: itemNumber,
            companyId: companyId,
            txn: txn,
          );

      final itemLocation = ItemLocation(
        branch: item.branch!,
        itemNumber: itemNumber,
        location: locationId,
        quantityOnHand: item.quantity ?? 0.0,
        company: companyId,
        createdBy: userId,
        dateCreated: DateTime.now(),
      );

      if (existingItemLocations.isNotEmpty && item.quantity != null) {
        final updatedLocation = existingItemLocations.first.copyWith(
          quantityOnHand:
              (existingItemLocations.first.quantityOnHand ?? 0.0) +
              item.quantity!,
        );

        await itemLocationsRepository.updateItemLocation(
          updatedLocation,
          txn: txn,
        );
        print('📍 Updated ItemLocations for: ${item.itemDescription}');
        return updatedLocation;
      } else if (existingItemLocations.isEmpty) {
        final id = await itemLocationsRepository.createItemLocation(
          itemLocation,
          txn: txn,
        );
        print('📍 Created new ItemLocations for: ${item.itemDescription}');
        return itemLocation.copyWith(id: id);
      }

      return existingItemLocations.first;
    } catch (e) {
      print('❌ Error processing ItemLocations: $e');
      rethrow;
    }
  }

  /// Step 6: Process LotMaster with proper error handling
  Future<LotMaster?> _processLotMaster(
    ItemMaster item,
    int itemNumber,
    int locationId,
    int companyId,
    int userId,
    Transaction? txn,
  ) async {
    try {
      if (item.branch == null) {
        throw Exception('Branch is required for LotMaster');
      }

      final existingLotMaster = await lotMasterRepository
          .getLotMasterByItemAndLocation(
            itemNumber,
            locationId,
            companyId,
            txn: txn,
          );

      final lotStatus = await udcRepository.getUdcDetailId('LS', 'A', txn: txn);
      if (lotStatus == null) {
        throw Exception('Could not find Lot Status UDC');
      }

      final lotNumber = await nextNumberRepository.generateNextNumber(
        'LM',
        companyId,
        txn: txn,
      );

      final lotMaster = LotMaster(
        branch: item.branch!,
        itemNumber: itemNumber,
        location: locationId,
        lotNumber: lotNumber,
        unitPrice: item.unitPrice ?? 0.0,
        quantityAvailable: item.quantity ?? 0.0,
        batchNumberSupplier: item.batchNumber,
        lotStatus: lotStatus,
        company: companyId,
      );

      // Set appropriate date field
      final systemConstant = systemConstantBloc.state.selected;
      final lotType = await udcRepository.getUdcDetailById(
        systemConstant?.lotType,
        txn: txn,
      );

      if (lotType?.detailCode == 'X' || lotType == null) {
        lotMaster.dateExpiration = item.dateExpired;
      } else if (lotType.detailCode == 'F') {
        lotMaster.dateEffective = item.dateExpired;
      } else if (lotType.detailCode == 'R') {
        lotMaster.dateReceived = item.dateExpired;
      }

      if (existingLotMaster != null && item.quantity != null) {
        final updatedLotMaster = existingLotMaster.copyWith(
          quantityAvailable:
              (existingLotMaster.quantityAvailable ?? 0.0) + item.quantity!,
        );
        await lotMasterRepository.updateLotMaster(updatedLotMaster, txn: txn);
        print('🏷️ Updated LotMaster for: ${item.itemDescription}');
        return updatedLotMaster;
      } else if (existingLotMaster == null) {
        final id = await lotMasterRepository.createLotMaster(
          lotMaster,
          txn: txn,
        );
        print('🏷️ Created new LotMaster for: ${item.itemDescription}');
        return lotMaster.copyWith(id: id);
      }

      return existingLotMaster;
    } catch (e) {
      print('❌ Error processing LotMaster: $e');
      rethrow;
    }
  }

  // ========== HELPER METHODS ==========

  /// Check if LotMaster should be created
  bool _shouldCreateLotMaster(ItemMaster item) {
    final systemConstant = systemConstantBloc.state.selected;
    return systemConstant?.applyLotMgmBoolean == true;
  }

  /// Generate location description from codes
  String _generateLocationDescription(ItemMaster item) {
    final codes = [
      item.locationCode1,
      item.locationCode2,
      item.locationCode3,
      item.locationCode4,
      item.locationCode5,
      item.locationCode6,
      item.locationCode7,
      item.locationCode8,
      item.locationCode9,
      item.locationCode10,
    ];

    final nonEmptyCodes = codes
        .where((code) => code != null && code.isNotEmpty)
        .toList();
    return nonEmptyCodes.isNotEmpty
        ? nonEmptyCodes.join('-')
        : 'Unknown-Location';
  }

  /// Validate migration input
  MigrationValidationResult _validateMigrationInput(ItemMaster item) {
    final errors = <String>[];

    if (item.itemDescription == null || item.itemDescription!.isEmpty) {
      errors.add('Item description is required');
    }

    if (item.branch == null) {
      errors.add('Branch is required');
    }

    if (item.defualtUom == null) {
      errors.add('Default UoM is required');
    }

    if (item.locationCode1 == null || item.locationCode1!.isEmpty) {
      errors.add('Location Code 1 is required');
    }

    return MigrationValidationResult(
      isValid: errors.isEmpty,
      errorMessage: errors.isEmpty ? null : errors.join(', '),
    );
  }
}

// ========== SUPPORTING CLASSES ==========

class MigrationResult {
  final bool success;
  final String message;
  final dynamic data;

  MigrationResult({required this.success, required this.message, this.data});
}

class MigrationValidationResult {
  final bool isValid;
  final String? errorMessage;

  MigrationValidationResult({required this.isValid, this.errorMessage});
}
