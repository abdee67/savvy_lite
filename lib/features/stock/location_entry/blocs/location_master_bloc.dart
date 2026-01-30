// bloc/location_master_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/stock/location_entry/repo/location_master_repository.dart';

class LocationMasterBloc
    extends Bloc<LocationMasterEvent, LocationMasterState> {
  final LocationMasterRepository locationMasterRepository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  LocationMasterBloc({
    required this.locationMasterRepository,
    required this.authBloc,
  }) : super(const LocationMasterState()) {
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
    on<SaveInRow>(_onSaveInRow);
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
    on<FilterLocationsByBranch>(_onFilterLocationsByBranch);
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

    if (kDebugMode) {
      developer.log(
        '🔄 BLoC: Loading locations for company ${event.companyId}',
      );
    }
    emit(state.copyWith(status: LocationMasterStatus.loading));
    try {
      final location = await locationMasterRepository.getLocationMasters(
        event.companyId,
      );

      emit(
        state.copyWith(
          status: LocationMasterStatus.loaded,
          items: location,
          locations: location,
          filteredLocations: location,
          companyId: authBloc.state.companyId,
          message: location.isEmpty ? 'No locations found' : null,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to load locations: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to load locations',
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
      final companyId = authBloc.state.companyId!;
      final userId = authBloc.state.userId!;

      // Check for duplication
      final isDuplication = await locationMasterRepository
          .checkDuplicateLocation(event.item, companyId);
      if (isDuplication) {
        emit(
          state.copyWith(
            status: LocationMasterStatus.duplication,
            message: 'Location already exists for this branch',
          ),
        );
        return;
      }

      // Validate location
      final errors = locationMasterRepository.validateLocation(event.item);
      if (errors.isNotEmpty) {
        emit(
          state.copyWith(
            status: LocationMasterStatus.failure,
            message: errors.join(', '),
          ),
        );
        return;
      }

      // Create location
      final locationId = await locationMasterRepository.createLocationMaster(
        event.item,
        userId.id,
        companyId,
      );

      // Save item locations assignments
      if (event.assignedItems.isNotEmpty) {
        await locationMasterRepository.saveItemLocations(
          locationId,
          event.assignedItems,
          userId.id,
          companyId,
        );
      }

      add(LoadLocationMasters(companyId));
      add(ClearCreateList());

      emit(
        state.copyWith(
          status: LocationMasterStatus.success,
          message: 'Location added successfully',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to create location: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to create location',
        ),
      );
    }
  }

  Future<void> _onLoadItemsForBranch(
    LoadItemsForBranch event,
    Emitter<LocationMasterState> emit,
  ) async {
    try {
      final items = await locationMasterRepository.getItemsForBranch(
        event.branchId,
        authBloc.state.companyId!,
      );
      emit(state.copyWith(dualListSource: items, dualListTarget: const []));
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to load items for branch: $e');
      }
      emit(state.copyWith(message: 'Failed to load items for branch'));
    }
  }

  Future<void> _onSaveInRow(
    SaveInRow event,
    Emitter<LocationMasterState> emit,
  ) async {
    // Reuse the existing save logic
    if (event.item.id != null) {
      await _onUpdateLocation(
        UpdateLocationMaster(event.item, event.assignedItems!),
        emit,
      );
    } else {
      await _onSaveLocation(
        SaveLocationMaster(event.item, event.assignedItems!),
        emit,
      );
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocationMaster event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.updating));
    try {
      final companyId = authBloc.state.companyId;
      final userId = authBloc.state.userId;

      if (companyId == null) {
        emit(
          state.copyWith(
            status: LocationMasterStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      // Check for duplication
      final isDuplication = await locationMasterRepository
          .checkDuplicateLocation(event.item, companyId);
      if (isDuplication) {
        emit(
          state.copyWith(
            status: LocationMasterStatus.duplication,
            message: 'Location already exists for this branch',
          ),
        );
        return;
      }

      await locationMasterRepository.updateLocationMaster(
        event.item,
        userId!.id,
        companyId,
      );

      // Update item locations assignments
      await locationMasterRepository.updateItemLocations(
        event.item.id!,
        event.assignedItems,
        userId.id,
        companyId,
      );

      add(LoadLocationMasters(companyId));
      emit(
        state.copyWith(
          status: LocationMasterStatus.success,
          message: 'Location updated successfully',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to update location: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to update location',
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
      if (kDebugMode) {
        developer.log('Failed to prepare edit: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to prepare edit',
        ),
      );
    }
  }

  Future<void> _loadItemAssignmentsForEdit(LocationMaster location) async {
    // Get all items for the branch
    final branchItems = await locationMasterRepository.getItemsForBranch(
      location.branch!,
      authBloc.state.companyId!,
    );

    // Get assigned items for this location
    final assignedItems = await locationMasterRepository
        .getAssignedItemsForLocation(location.id!, authBloc.state.companyId!);

    // Remove assigned items from source
    branchItems.removeWhere(
      (source) => assignedItems.any((target) => target.id == source.id),
    );

    add(UpdateDualListModel(branchItems, assignedItems));
  }

  Future<void> _onLoadLocationsByBranch(
    LoadLocationsByBranch event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.loading));
    try {
      final locations = await locationMasterRepository.getLocationsByBranch(
        event.locationDescription,
        event.branchId,
        authBloc.state.companyId!,
      );

      emit(
        state.copyWith(
          status: LocationMasterStatus.loaded,
          locations: locations,
          items: locations,
          message: locations.isEmpty
              ? 'No locations found for this branch'
              : null,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to load locations by branch: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to load locations by branch',
        ),
      );
    }
  }

  Future<void> _onFilterLocationsByBranch(
    FilterLocationsByBranch event,
    Emitter<LocationMasterState> emit,
  ) async {
    emit(state.copyWith(status: LocationMasterStatus.loading));
    try {
      final locations = await locationMasterRepository.filterLocationsByBranch(
        event.branchId,
        authBloc.state.companyId!,
      );

      emit(
        state.copyWith(
          status: LocationMasterStatus.loaded,
          locations: locations,
          items: locations,
          message: locations.isEmpty
              ? 'No locations found for this branch'
              : null,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to filter locations by branch: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to filter locations by branch',
        ),
      );
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
      final companyId = authBloc.state.companyId;

      await locationMasterRepository.deleteLocationMaster(
        event.item.id!,
        companyId!,
      );

      emit(
        state.copyWith(
          status: LocationMasterStatus.success,
          message: 'Location deleted successfully',
        ),
      );

      add(LoadLocationMasters(companyId));
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to delete location: $e');
      }
      emit(
        state.copyWith(
          status: LocationMasterStatus.failure,
          message: 'Failed to delete location',
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

  Future<void> _onSearchLocations(
    SearchLocations event,
    Emitter<LocationMasterState> emit,
  ) async {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredLocations: state.locations,
          searchQuery: event.query,
          status: LocationMasterStatus.success,
        ),
      );
      return;
    }

    final filtered = state.locations.where((location) {
      final description = (location.locationDescription ?? '').toLowerCase();
      final branch = (location.branchName ?? '').toLowerCase();
      final code01 = (location.code01 ?? '').toLowerCase();
      final code02 = (location.code02 ?? '').toLowerCase();
      final code03 = (location.code03 ?? '').toLowerCase();

      return description.contains(query) ||
          branch.contains(query) ||
          code01.contains(query) ||
          code02.contains(query) ||
          code03.contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredLocations: filtered,
        searchQuery: event.query,
        status: LocationMasterStatus.success,
      ),
    );
  }
}
