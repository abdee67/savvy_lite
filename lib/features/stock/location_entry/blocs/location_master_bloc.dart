// bloc/location_master_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

class LocationMasterBloc
    extends Bloc<LocationMasterEvent, LocationMasterState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  LocationMasterBloc({required this.databaseService, required this.authBloc})
    : super(const LocationMasterState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadLocationMasters(authState.companyId!));
      } else {
        //clear data when logge out
        add(const ClearLocations());
      }
    });

    on<LoadLocationMasters>(_onLoadLocations);
    on<SaveLocationMaster>(_onSaveLocation);
    on<UpdateLocationMaster>(_onUpdateLocation);
    on<DeleteLocationMaster>(_onDeleteLocation);
    on<PrepareCreateLocation>(_onPrepareCreate);
    on<PrepareEditLocation>(_onPrepareEdit);
    on<AddToCreateList>(_onAddToCreateList);
    on<RemoveFromCreateList>(_onRemoveFromCreateList);
    on<RemoveFromEditList>(_onRemoveFromEditList);
    on<SetSelectedLocation>(_onSetSelected);
    on<SetMultiSelectionLocations>(_onSetMultiSelection);
    on<ClearCreateList>(_onClearCreateList);
    on<UpdateDualListModel>(_onUpdateDualList);
    on<LoadItemsForBranch>(_onLoadItemsForBranch);
    on<LoadLocationsByBranch>(_onLoadLocationsByBranch);
    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
    on<ClearLocations>(_onClearLocations);
    on<SearchLocations>(_onSearchLocations);
  }

  Future<void> _onClearLocations(
    ClearLocations event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(const LocationMasterState()); // Reset to initial state
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadLocations(
    LoadLocationMasters event,
    Emitter<LocationMasterState> emit,
  ) async {
    // Prevent duplicate loads
    if (state.status == LocationMasterStatus.loading) return;

    print('🔄 BLoC: Loading locations for company ${event.companyId}');
    emit(state.copyWith(status: LocationMasterStatus.loading));
    try {
      final db = await databaseService.database;
      final locations = await db.rawQuery(
        '''
        SELECT
        lm.*,
        b.description as branch_name
        FROM location_master lm
        LEFT JOIN branch_table b ON lm.branch = b.id
        WHERE lm.company = ?
        ''',
        [event.companyId],
      );

      final locationList = locations
          .map((p) => LocationMaster.fromMap(p))
          .toList();

      emit(
        state.copyWith(
          status: LocationMasterStatus.loaded,
          items: locationList,
          filteredItems: locationList,
          companyId: authBloc.state.companyId,
          message: locationList.isEmpty ? 'No locations found' : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to load locations: $e',
        ),
      );
    }
  }

  Future<void> _onSaveLocation(
    SaveLocationMaster event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.creating));
    try {
      // Check if this is an update or create
      final isUpdate = event.item.id != null;

      if (isUpdate) {
        // For updates, use update logic
        await _onUpdateLocation(
          UpdateLocationMaster(event.item, event.assignedItems),
          emit,
        );
      } else {
        // For creates, use create logic with duplication check
        final isDuplication = await _checkDuplication(event.item);
        if (isDuplication) {
          emit(
            state.copyWith(
              status: LocationMasterStatus.duplication,
              message: 'Location already exists for this branch',
            ),
          );
          return;
        }

        final db = await databaseService.database;
        final itemMap = _applySettings(event.item, false).toMap();
        itemMap.remove('id');
        itemMap['created_by'] = authBloc.state.userId;
        itemMap['date_created'] = DateTime.now().toIso8601String();
        itemMap['company'] = authBloc.state.companyId;

        // Insert location
        final locationId = await db.insert('location_master', itemMap);

        // Save item locations assignments
        await _saveItemLocations(locationId, event.assignedItems);

        add(LoadLocationMasters(authBloc.state.companyId!));
        add(ClearCreateList());

        emit(
          state.copyWith(
            status: LocationMasterStatus.success,
            message: 'Location added successfully',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message:
              'Failed to ${event.item.id != null ? 'update' : 'create'} location: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocationMaster event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.updating));
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      if (companyId == null) {
        emit(
          state.copyWith(
            status: LocationMasterStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final itemMap = _applySettings(event.item, true).toMap();
      itemMap['updated_by'] = authBloc.state.userId;
      itemMap['date_updated'] = DateTime.now().toIso8601String();
      itemMap['company'] = companyId;

      await db.update(
        'location_master',
        itemMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      // Update item locations assignments
      await _updateItemLocations(event.item.id!, event.assignedItems);

      add(LoadLocationMasters(companyId));
      emit(
        state.copyWith(
          status: LocationMasterStatus.success,
          message: 'Location updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to update location: $e',
        ),
      );
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreateLocation event,
    Emitter<LocationMasterState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.createItems);
    final newLocation = LocationMaster(
      tempId: nextTempId,
      company: event.companyId,
      validCell: true,
    );

    emit(
      state.copyWith(
        createItems: [...state.createItems, newLocation],
        selected: newLocation,
        selected2: LocationMaster(company: event.companyId),
        dualListSource: const [],
        dualListTarget: const [],
      ),
    );
  }

  Future<void> _onPrepareEdit(
    PrepareEditLocation event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.loading));
    try {
      // Load items for branch and existing assignments
      if (event.item.branch != null) {
        await _loadItemAssignmentsForEdit(event.item);
      }

      emit(
        state.copyWith(
          status: LocationMasterStatus.loaded,
          editItems: [event.item],
          selected: event.item,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to prepare edit: $e',
        ),
      );
    }
  }

  Future<void> _loadItemAssignmentsForEdit(LocationMaster location) async {
    final db = await databaseService.database;

    // Get all items for the branch
    final branchItems = await db.rawQuery(
      '''
      SELECT * FROM items_in_branch 
      WHERE branch = ? AND company = ?
      ''',
      [location.branch, authBloc.state.companyId],
    );

    // Get assigned items for this location
    final assignedItems = await db.rawQuery(
      '''
      SELECT ib.* FROM item_location il
      JOIN items_in_branch ib ON il.item_number = ib.item_number AND il.branch = ib.branch
      WHERE il.location = ? AND il.company = ?
      ''',
      [location.id, authBloc.state.companyId],
    );

    final sourceItems = branchItems
        .map((e) => ItemInBranchModel.fromMap(e))
        .toList();
    final targetItems = assignedItems
        .map((e) => ItemInBranchModel.fromMap(e))
        .toList();

    // Remove assigned items from source
    sourceItems.removeWhere(
      (source) => targetItems.any((target) => target.id == source.id),
    );

    add(UpdateDualListModel(sourceItems, targetItems));
  }

  Future<void> _onLoadItemsForBranch(
    LoadItemsForBranch event,
    Emitter<LocationMasterState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final items = await db.rawQuery(
        '''
        SELECT * FROM items_in_branch 
        WHERE branch = ? AND company = ?
        ''',
        [event.branchId, authBloc.state.companyId],
      );

      final itemList = items.map((e) => ItemInBranchModel.fromMap(e)).toList();

      emit(state.copyWith(dualListSource: itemList, dualListTarget: const []));
    } catch (e) {
      emit(state.copyWith(message: 'Failed to load items for branch: $e'));
    }
  }

  Future<void> _onLoadLocationsByBranch(
    LoadLocationsByBranch event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.loading));
    try {
      final db = await databaseService.database;
      final locations = await db.rawQuery(
        '''
       SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.branch = ? AND lm.company = ?
      ORDER BY lm.location_description
        ''',
        [event.branchId, authBloc.state.companyId],
      );

      final locationList = locations
          .map((e) => LocationMaster.fromMap(e))
          .toList();
      print(
        '📍 Loaded ${locationList.length} locations for branch $event.branchId',
      ); // Debug log

      emit(
        state.copyWith(
          status: LocationMasterStatus.loaded,
          filteredItems: locationList,
          items: locationList,
          message: locationList.isEmpty
              ? 'No locations found for this branch'
              : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to load locations by branch: $e',
        ),
      );
    }
  }

  Future<void> _saveItemLocations(
    int locationId,
    List<ItemInBranchModel> assignedItems,
  ) async {
    final db = await databaseService.database;

    for (final item in assignedItems) {
      // Check if item location already exists
      final existing = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM item_location
        WHERE branch = ? AND item_number = ? AND location = ? AND company = ?
        ''',
        [item.branch, item.itemNumber, locationId, authBloc.state.companyId],
      );

      final count = (existing.first['count'] as int?) ?? 0;
      if (count == 0) {
        final itemLocation = ItemLocation(
          branch: item.branch,
          itemNumber: item.itemNumber,
          location: locationId,
          quantityOnHand: item.quantityAvailable,
          dateUpdated: DateTime.now(),
          dateCreated: DateTime.now(),
          updatedBy: authBloc.state.userId,
          createdBy: authBloc.state.userId,
          company: authBloc.state.companyId,
        );

        await db.insert('item_location', itemLocation.toMap());
      }
    }
  }

  Future<void> _updateItemLocations(
    int locationId,
    List<ItemInBranchModel> assignedItems,
  ) async {
    final db = await databaseService.database;

    // Remove all existing assignments for this location
    await db.delete(
      'item_location',
      where: 'location = ? AND company = ?',
      whereArgs: [locationId, authBloc.state.companyId],
    );

    // Add new assignments
    for (final item in assignedItems) {
      final itemLocation = ItemLocation(
        branch: item.branch,
        itemNumber: item.itemNumber,
        location: locationId,
        quantityOnHand: item.quantityAvailable,
        dateUpdated: DateTime.now(),
        dateCreated: DateTime.now(),
        updatedBy: authBloc.state.userId,
        createdBy: authBloc.state.userId,
        company: authBloc.state.companyId,
      );

      await db.insert('item_location', itemLocation.toMap());
    }
  }

  // Helper Methods
  LocationMaster _applySettings(LocationMaster item, bool isUpdate) {
    final locationDescription = _generateLocationDescription(item);

    return item.copyWith(
      locationDescription: locationDescription,
      createdBy: isUpdate ? item.createdBy : authBloc.state.userId,
      dateCreated: isUpdate ? item.dateCreated : DateTime.now(),
      updatedBy: isUpdate ? authBloc.state.userId : item.updatedBy,
      dateUpdated: isUpdate ? DateTime.now() : item.dateUpdated,
    );
  }

  String _generateLocationDescription(LocationMaster item) {
    final codes = [
      item.code01,
      item.code02,
      item.code03,
      item.code04,
      item.code05,
      item.code06,
      item.code07,
      item.code08,
      item.code09,
      item.code10,
    ];

    final nonEmptyCodes = codes
        .where((code) => code != null && code.isNotEmpty)
        .toList();
    return nonEmptyCodes.join('-');
  }

  Future<bool> _checkDuplication(LocationMaster item) async {
    try {
      final db = await databaseService.database;
      // For updates, exclude the current item ID
      // For creates, check against all items
      final idCondition = item.id != null ? 'AND id != ?' : '';
      final whereArgs = item.id != null
          ? [
              item.locationDescription,
              item.branch,
              authBloc.state.companyId,
              item.id,
            ]
          : [item.locationDescription, item.branch, authBloc.state.companyId];

      final existing = await db.rawQuery('''
        SELECT COUNT(*) as count FROM location_master 
        WHERE location_description = ? AND branch = ? AND company = ? $idCondition
        ''', whereArgs);

      final count = (existing.first['count'] as int?) ?? 0;
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // Event handlers for simple state updates
  Future<void> _onAddToCreateList(
    AddToCreateList event,
    Emitter<LocationMasterState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.createItems);
    final newItem = event.item.copyWith(tempId: nextTempId);

    emit(
      state.copyWith(
        createItems: [...state.createItems, newItem],
        selected1: newItem,
      ),
    );
  }

  Future<void> _onRemoveFromCreateList(
    RemoveFromCreateList event,
    Emitter<LocationMasterState> emit,
  ) async {
    final updatedCreateItems = state.createItems
        .where((item) => item.tempId != event.item.tempId)
        .toList();

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  Future<void> _onRemoveFromEditList(
    RemoveFromEditList event,
    Emitter<LocationMasterState> emit,
  ) async {
    final updatedEditItems = state.editItems
        .where((item) => item.tempId != event.item.tempId)
        .toList();

    emit(state.copyWith(editItems: updatedEditItems));
  }

  Future<void> _onSetSelected(
    SetSelectedLocation event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(selected: event.item));
  }

  Future<void> _onSetMultiSelection(
    SetMultiSelectionLocations event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(multiSelectionItems: event.items));
  }

  Future<void> _onClearCreateList(
    ClearCreateList event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(
      state.copyWith(createItems: const [], selected: null, selected1: null),
    );
  }

  Future<void> _onUpdateDualList(
    UpdateDualListModel event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        dualListSource: event.source,
        dualListTarget: event.target,
      ),
    );
  }

  Future<void> _onCancelCreate(
    CancelCreate event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(
      state.copyWith(selected: null, createItems: const [], items: const []),
    );
  }

  Future<void> _onCancelUpdate(
    CancelUpdate event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  Future<void> _onDeleteLocation(
    DeleteLocationMaster event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.deleting));
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // First delete related item locations
      await db.delete(
        'item_location',
        where: 'location = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      // Then delete the location
      await db.delete(
        'location_master',
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      add(LoadLocationMasters(companyId!));
      emit(
        state.copyWith(
          status: LocationMasterStatus.success,
          message: 'Location deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to delete location: $e',
        ),
      );
    }
  }

  int _getNextTempId(List<LocationMaster> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  void _onSearchLocations(
    SearchLocations event,
    Emitter<LocationMasterState> emit,
  ) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredLocations: state.locations,
          selectedLocations: [],
          searchQuery: '',
          status: LocationMasterStatus.success,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        filteredLocations: state.locations.where((location) {
          return location.locationDescription?.toLowerCase().contains(query) ==
                  true ||
              location.branchName?.toLowerCase().contains(query) == true ||
              location.code01?.toLowerCase().contains(query) == true ||
              location.code02?.toLowerCase().contains(query) == true ||
              location.code03?.toLowerCase().contains(query) == true;
        }).toList(),
        selectedLocations: [],
        searchQuery: query,
        status: LocationMasterStatus.success,
      ),
    );
  }
}
