import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';

class StockItemLocationBloc
    extends Bloc<ItemLocationsEvent, ItemLocationsState> {
  final ItemLocationsRepository repository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  StockItemLocationBloc({required this.repository, required this.authBloc})
    : super(const ItemLocationsState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItemLocations(authState.companyId!));
      }
    });

    on<LoadItemLocations>(_onLoadItemLocations);
    on<LoadItemLocationsByBranchAndItem>(_onLoadItemLocationsByBranchAndItem);
    on<CreateItemLocation>(_onCreateItemLocation);
    on<UpdateItemLocation>(_onUpdateItemLocation);
    on<DeleteItemLocation>(_onDeleteItemLocation);
    on<SearchItemLocations>(_onSearchItemLocations);
    on<SelectItemLocation>(_onSelectItemLocation);
    on<SelectAllItemLocations>(_onSelectAllItemLocations);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedItemLocations>(_onDeleteSelectedItemLocations);
    on<SaveItemLocationRow>(_onSaveItemLocationRow);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadItemLocations(
    LoadItemLocations event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(state.copyWith(status: ItemLocationsStatus.loading));
    try {
      final items = await repository.getItemLocations(event.companyId);
      emit(
        state.copyWith(
          status: ItemLocationsStatus.success,
          items: items,
          filteredItems: items,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to load item locations: $e',
        ),
      );
    }
  }

  Future<void> _onLoadItemLocationsByBranchAndItem(
    LoadItemLocationsByBranchAndItem event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(state.copyWith(status: ItemLocationsStatus.loading));
    try {
      final items = await repository.getItemLocationsByBranchAndItem(
        companyId: event.companyId,
        branchId: event.branchId,
        itemId: event.itemId,
      );
      emit(
        state.copyWith(
          status: ItemLocationsStatus.success,
          items: items,
          filteredItems: items,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to load item locations: $e',
        ),
      );
    }
  }

  Future<void> _onCreateItemLocation(
    CreateItemLocation event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(state.copyWith(status: ItemLocationsStatus.creating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Set company ID for the new item
      final itemToCreate = event.item.copyWith(company: companyId);
      await repository.createItemLocation(itemToCreate);

      // Reload the list
      add(LoadItemLocations(companyId));

      emit(
        state.copyWith(
          status: ItemLocationsStatus.success,
          message: 'Item location created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to create item location: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateItemLocation(
    UpdateItemLocation event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(state.copyWith(status: ItemLocationsStatus.updating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.updateItemLocation(event.item);
      add(LoadItemLocations(companyId));

      emit(
        state.copyWith(
          status: ItemLocationsStatus.success,
          message: 'Item location updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to update item location: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteItemLocation(
    DeleteItemLocation event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(state.copyWith(status: ItemLocationsStatus.deleting));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.deleteItemLocation(event.itemId, companyId);

      // Update local state immediately
      final updatedItems = List<ItemLocation>.from(state.items)
        ..removeWhere((p) => p.id == event.itemId);
      final updatedFilteredItems = List<ItemLocation>.from(state.filteredItems)
        ..removeWhere((p) => p.id == event.itemId);

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
          status: ItemLocationsStatus.success,
          message: 'Item location deleted successfully',
          recentlyDeleted: event.deletedItem != null
              ? [...state.recentlyDeleted, event.deletedItem!]
              : state.recentlyDeleted,
          recentlyDeletedIndexes: event.deletedIndex != null
              ? [...state.recentlyDeletedIndexes, event.deletedIndex!]
              : state.recentlyDeletedIndexes,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to delete item location: $e',
        ),
      );
    }
  }

  Future<void> _onSaveItemLocationRow(
    SaveItemLocationRow event,
    Emitter<ItemLocationsState> emit,
  ) async {
    try {
      if (event.item.id != null) {
        add(UpdateItemLocation(event.item));
      } else {
        add(CreateItemLocation(event.item));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to save item location: $e',
        ),
      );
    }
  }

  void _onSearchItemLocations(
    SearchItemLocations event,
    Emitter<ItemLocationsState> emit,
  ) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredItems: state.items,
          searchQuery: '',
          status: ItemLocationsStatus.success,
        ),
      );
      return;
    }

    final filtered = state.items.where((item) {
      return item.location.toString().toLowerCase().contains(query) ||
          item.itemNumber.toString().toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredItems: filtered,
        searchQuery: query,
        status: ItemLocationsStatus.searching,
      ),
    );
  }

  void _onSelectItemLocation(
    SelectItemLocation event,
    Emitter<ItemLocationsState> emit,
  ) {
    final selectedItems = List<ItemLocation>.from(state.selectedItems);
    if (event.isSelected) {
      selectedItems.add(event.item);
    } else {
      selectedItems.removeWhere((item) => item.id == event.item.id);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void _onSelectAllItemLocations(
    SelectAllItemLocations event,
    Emitter<ItemLocationsState> emit,
  ) {
    if (state.selectedItems.length == event.items.length) {
      emit(state.copyWith(selectedItems: []));
    } else {
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<ItemLocationsState> emit,
  ) {
    emit(state.copyWith(selectedItems: []));
  }

  Future<void> _onDeleteSelectedItemLocations(
    DeleteSelectedItemLocations event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(state.copyWith(status: ItemLocationsStatus.deleting));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.deleteItemLocations(event.selectedItems, companyId);

      // Update local state
      final updatedItems = state.items
          .where((e) => !event.selectedItems.contains(e.id))
          .toList();
      final updatedFiltered = state.filteredItems
          .where((e) => !event.selectedItems.contains(e.id))
          .toList();

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFiltered,
          selectedItems: [],
          status: ItemLocationsStatus.success,
          message:
              '${event.selectedItems.length} item locations deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedItems],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to delete selected item locations: $e',
        ),
      );
    }
  }
}
