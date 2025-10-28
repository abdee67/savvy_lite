// bloc/item_uom_conversion_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_state.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';

class ItemUomConversionBloc
    extends Bloc<ItemUomConversionEvent, ItemUomConversionState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  ItemUomConversionBloc({required this.databaseService, required this.authBloc})
    : super(const ItemUomConversionState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItemUomConversions(authState.companyId!));
      }
    });
    on<LoadItemUomConversions>(_onLoadItems);
    on<SaveItemUomConversion>(_onSaveItem);
    on<UpdateItemUomConversion>(_onUpdateItem);
    on<DeleteItemUomConversion>(_onDeleteItem);
    on<PrepareCreateUomConversion>(_onPrepareCreate);
    on<AddToCreateList>(_onAddToCreateList);
    on<RemoveFromCreateList>(_onRemoveFromCreateList);
    on<SetSelectedItem>(_onSetSelectedItem);
    on<SetMultiSelectionItems>(_onSetMultiSelectionItems);
    on<ClearCreateList>(_onClearCreateList);
    on<CalculateUomConversion>(_onCalculateUomConversion);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadItems(
    LoadItemUomConversions event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.loading));
    try {
      final db = await databaseService.database;
      final items = await db.rawQuery(
        '''
        SELECT iuc.*
        FROM item_uom_conversions iuc
        WHERE iuc.company = ?
      ''',
        [event.companyId],
      );

      final itemList = items.map((p) => ItemUomConversion.fromMap(p)).toList();

      emit(
        state.copyWith(
          status: ItemUomConversionStatus.loaded,
          items: itemList,
          filteredItems: itemList,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.failure,
          message: 'Failed to load UoM conversions: $e',
        ),
      );
    }
  }

  Future<void> _onSaveItem(
    SaveItemUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.creating));
    try {
      // Check for duplication
      final isDuplication = await _checkDuplication(event.item);
      if (isDuplication) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.duplication,
            message: 'UoM conversion already exists for this item',
          ),
        );
        return;
      }
      // Check for structure validation
      final isStructureValid = await _checkStructureValidation(event.item);
      if (!isStructureValid) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.failure,
            message:
                'The UoM structure levels must be consecutive (1, 2, 3...). Please correct the level.',
          ),
        );
        return;
      }
      // ✅ Set validCell to true like Java does for successful validation
      final validItem = event.item.copyWith(validCell: true);

      final db = await databaseService.database;
      final itemMap = validItem.toMap();
      itemMap.remove('id');
      itemMap['created_by'] = authBloc.state.userId;
      itemMap['date_created'] = DateTime.now().toIso8601String();
      itemMap['company'] = authBloc.state.companyId;

      await db.insert('item_uom_conversions', itemMap);
      add(LoadItemUomConversions(authBloc.state.companyId!));
      add(ClearCreateList());

      emit(
        state.copyWith(
          status: ItemUomConversionStatus.success,
          message: 'UoM conversion added successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.failure,
          message: 'Failed to create UoM conversion: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateItem(
    UpdateItemUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.updating));
    try {
      // Check for duplication
      final isDuplication = await _checkDuplication(event.item);
      if (isDuplication) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.duplication,
            message: 'UoM conversion already exists for this item',
          ),
        );
        return;
      }
      // Check for structure validation
      final isStructureValid = await _checkStructureValidation(event.item);
      if (!isStructureValid) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.failure,
            message:
                'The UoM structure levels must be consecutive (1, 2, 3...). Please correct the level.',
          ),
        );
        return;
      }
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      if (companyId == null) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final itemMap = event.item.toMap();
      itemMap['updated_by'] = authBloc.state.userId;
      itemMap['date_updated'] = DateTime.now().toIso8601String();
      itemMap['company'] = companyId;

      await db.update(
        'item_uom_conversions',
        itemMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      add(LoadItemUomConversions(companyId));
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.success,
          message: 'UoM conversion updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.failure,
          message: 'Failed to update UoM conversion: $e',
        ),
      );
    }
  }

  Future<int?> _uoMByStructure(
    int itemId,
    int structureLevel,
    int companyId,
  ) async {
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT from_uom 
      FROM item_uom_conversions 
      WHERE item_number = ? AND uom_structure_level = ? AND company = ?
      ''',
        [itemId, structureLevel, companyId],
      );

      if (result.isNotEmpty) {
        return result.first['from_uom'] as int?;
      }
      return null;
    } catch (e) {
      print('uoMByStructure error: $e');
      return null;
    }
  }

  Future<double> _unstructuredUoMConversion(
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT conversion_factor 
      FROM item_uom_conversions 
      WHERE item_number = ? AND from_uom = ? AND to_uom = ? AND company = ?
      ''',
        [itemId, fromUomId, toUomId, companyId],
      );

      if (result.isNotEmpty && result.first['conversion_factor'] != null) {
        return result.first['conversion_factor'] as double;
      }
      return 1.0;
    } catch (e) {
      print('unstructuredUoMConversion error: $e');
      return 1.0;
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreateUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    // Generate tempId for the new item
    final nextTempId = _getNextTempId(state.createItems);
    final newItem = ItemUomConversion(
      tempId: nextTempId,
      company: event.companyId,
      validCell: true,
    );

    final updatedUiState = state.uiState.copyWith(
      createItems: [...state.createItems, newItem],
      selected: newItem,
      selected2: ItemUomConversion(company: event.companyId),
    );

    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<void> _onAddToCreateList(
    AddToCreateList event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.createItems);
    final newItem = event.item.copyWith(tempId: nextTempId);

    final updatedUiState = state.uiState.copyWith(
      createItems: [...state.createItems, newItem],
      selected1: newItem,
    );

    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<void> _onRemoveFromCreateList(
    RemoveFromCreateList event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final updatedCreateItems = state.createItems
        .where((item) => item.tempId != event.item.tempId)
        .toList();

    final updatedUiState = state.uiState.copyWith(
      createItems: updatedCreateItems,
    );

    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<void> _onSetSelectedItem(
    SetSelectedItem event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final updatedUiState = state.uiState.copyWith(selected: event.item);
    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<void> _onSetMultiSelectionItems(
    SetMultiSelectionItems event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final updatedUiState = state.uiState.copyWith(
      multiSelectionItems: event.items,
    );
    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<void> _onClearCreateList(
    ClearCreateList event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final updatedUiState = state.uiState.copyWith(
      createItems: const [],
      selected: null,
      selected1: null,
    );
    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<bool> _checkDuplication(ItemUomConversion item) async {
    try {
      final db = await databaseService.database;

      // Build WHERE clause dynamically to handle null values
      final whereParts = <String>[];
      final whereArgs = <dynamic>[];

      // Add non-null conditions
      if (item.itemNumber != null) {
        whereParts.add('item_number = ?');
        whereArgs.add(item.itemNumber);
      } else {
        whereParts.add('item_number IS NULL');
      }

      if (item.fromUom != null) {
        whereParts.add('from_uom = ?');
        whereArgs.add(item.fromUom);
      } else {
        whereParts.add('from_uom IS NULL');
      }

      if (item.toUom != null) {
        whereParts.add('to_uom = ?');
        whereArgs.add(item.toUom);
      } else {
        whereParts.add('to_uom IS NULL');
      }

      // Company should never be null when saving
      if (authBloc.state.companyId != null) {
        whereParts.add('company = ?');
        whereArgs.add(authBloc.state.companyId);
      } else {
        // If company is null, we can't check duplication properly
        return false;
      }

      // For update operations, exclude current item
      if (item.id != null) {
        whereParts.add('id != ?');
        whereArgs.add(item.id);
      }

      final whereClause = whereParts.join(' AND ');

      final existing = await db.query(
        'item_uom_conversions',
        where: whereClause,
        whereArgs: whereArgs,
      );

      return existing.isNotEmpty;
    } catch (e) {
      print('Duplication check error: $e');
      return false;
    }
  }

  Future<bool> _checkStructureValidation(ItemUomConversion item) async {
    try {
      final db = await databaseService.database;

      // 1. Check for duplicate structure level in DATABASE
      final existingStructure = await db.query(
        'item_uom_conversions',
        where:
            'item_number = ? AND uom_structure_level = ? AND company = ? AND id != ?',
        whereArgs: [
          item.itemNumber,
          item.uomStructureLevel,
          authBloc.state.companyId,
          item.id ?? 0,
        ],
      );

      // 2. Check for duplicate in create list
      final duplicateInCreateList = state.createItems.any(
        (createItem) =>
            createItem.tempId != item.tempId &&
            createItem.itemNumber == item.itemNumber &&
            createItem.uomStructureLevel == item.uomStructureLevel,
      );

      if (existingStructure.isNotEmpty || duplicateInCreateList) {
        return false;
      }

      // 3. ✅ CRITICAL: Check consecutive numbering in createItems (MISSING IN YOUR CODE)
      final createItemsWithLevels =
          state.createItems
              .where((createItem) => createItem.uomStructureLevel != null)
              .toList()
            ..sort(
              (a, b) => (a.uomStructureLevel ?? 0).compareTo(
                b.uomStructureLevel ?? 0,
              ),
            );

      // Add current item to the list for validation
      if (item.uomStructureLevel != null) {
        createItemsWithLevels.add(item);
        createItemsWithLevels.sort(
          (a, b) =>
              (a.uomStructureLevel ?? 0).compareTo(b.uomStructureLevel ?? 0),
        );
      }

      // Check if levels are consecutive starting from 1
      bool isConsecutive = true;
      for (int i = 0; i < createItemsWithLevels.length; i++) {
        if (createItemsWithLevels[i].uomStructureLevel != i + 1) {
          isConsecutive = false;
          break;
        }
      }

      return isConsecutive;
    } catch (e) {
      print('Structure validation error: $e');
      return false;
    }
  }

  Future<void> _onDeleteItem(
    DeleteItemUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.deleting));
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      await db.delete(
        'item_uom_conversions',
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      add(LoadItemUomConversions(companyId!));
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.success,
          message: 'UoM conversion deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.failure,
          message: 'Failed to delete UoM conversion: $e',
        ),
      );
    }
  }

  // Helper methods
  int _getNextTempId(List<ItemUomConversion> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  Future<void> _onCalculateUomConversion(
    CalculateUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.converting));
    try {
      final factor = await fromOtherToAnother(
        event.itemId,
        event.fromUomId,
        event.toUomId,
        event.companyId,
      );

      emit(
        state.copyWith(
          status: ItemUomConversionStatus.success,
          conversionFactor: factor,
          conversionError: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.failure,
          conversionError: 'An error occurred during conversion',
        ),
      );
    }
  }

  Future<double> fromOtherToAnother(
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    if (fromUomId == toUomId) {
      return 1.0;
    }

    try {
      final db = await databaseService.database;

      // Get item primary UoM
      final itemResult = await db.rawQuery(
        '''
        SELECT unit_of_measure FROM items_table 
        WHERE id = ? AND company = ?
      ''',
        [itemId, companyId],
      );

      if (itemResult.isEmpty) {
        // ✅ USE UNSTRUCTURED CONVERSION AS FALLBACK
        return await _unstructuredUoMConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }

      final primaryUomId = itemResult.first['unit_of_measure'] as int?;
      if (primaryUomId == null) {
        // ✅ USE UNSTRUCTURED CONVERSION WHEN NO PRIMARY UOM
        return await _unstructuredUoMConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }
      // Check if one of the UoMs is primary
      if (primaryUomId == fromUomId) {
        return await fromPrimaryToOther(itemId, toUomId, companyId);
      } else if (primaryUomId == toUomId) {
        return await fromOtherToPrimary(itemId, fromUomId, companyId);
      }

      // Get structure levels for both UoMs
      final strFrom = await _itemUoMStructureCode(
        itemId,
        fromUomId,
        'from',
        companyId,
      );
      final strTo = await _itemUoMStructureCode(
        itemId,
        toUomId,
        'to',
        companyId,
      );

      if (strFrom == null || strTo == null) {
        // ✅ USE UNSTRUCTURED CONVERSION WHEN NO STRUCTURE LEVELS FOUND
        return await _unstructuredUoMConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }
      // Get conversions between the two structure levels
      final conversions = await db.rawQuery(
        '''
        SELECT conversion_factor 
        FROM item_uom_conversions 
        WHERE item_number = ? AND company = ? 
          AND uom_structure_level BETWEEN ? AND ?
        ORDER BY uom_structure_level
      ''',
        [itemId, companyId, strFrom, strTo],
      );
      // If no structured conversions found, use unstructured
      if (conversions.isEmpty) {
        return await _unstructuredUoMConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }
      double factor = 1.0;
      for (final conversion in conversions) {
        final conversionFactor = conversion['conversion_factor'] as double?;
        if (conversionFactor != null) {
          factor *= conversionFactor;
        }
      }

      return factor;
    } catch (e) {
      // ✅ FALLBACK TO UNSTRUCTURED CONVERSION ON ERROR
      return await _unstructuredUoMConversion(
        itemId,
        fromUomId,
        toUomId,
        companyId,
      );
    }
  }

  Future<double> fromPrimaryToOther(
    int itemId,
    int toUomId,
    int companyId,
  ) async {
    final factor = await fromOtherToPrimary(itemId, toUomId, companyId);
    return factor != 1.0 ? 1.0 / factor : 1.0;
  }

  Future<double> fromOtherToPrimary(
    int itemId,
    int fromUomId,
    int companyId,
  ) async {
    try {
      final db = await databaseService.database;
      final str = await _itemUoMStructureCode(
        itemId,
        fromUomId,
        'from',
        companyId,
      );

      if (str == null) return 1.0;

      final conversions = await db.rawQuery(
        '''
        SELECT conversion_factor 
        FROM item_uom_conversions 
        WHERE item_number = ? AND company = ? 
          AND uom_structure_level >= ?
        ORDER BY uom_structure_level
      ''',
        [itemId, companyId, str],
      );

      double factor = 1.0;
      for (final conversion in conversions) {
        final conversionFactor = conversion['conversion_factor'] as double?;
        if (conversionFactor != null) {
          factor *= conversionFactor;
        }
      }

      return factor;
    } catch (e) {
      return 1.0;
    }
  }

  Future<int?> _itemUoMStructureCode(
    int itemId,
    int uomId,
    String fromTo,
    int companyId,
  ) async {
    try {
      final db = await databaseService.database;
      final column = fromTo.toLowerCase() == 'to' ? 'to_uom' : 'from_uom';

      final result = await db.rawQuery(
        '''
        SELECT uom_structure_level 
        FROM item_uom_conversions 
        WHERE item_number = ? AND $column = ? AND company = ?
      ''',
        [itemId, uomId, companyId],
      );

      if (result.isNotEmpty) {
        return result.first['uom_structure_level'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
