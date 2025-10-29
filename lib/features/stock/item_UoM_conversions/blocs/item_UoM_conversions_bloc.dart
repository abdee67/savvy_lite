// features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_state.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';

class ItemUomConversionBloc extends Bloc<ItemUomConversionEvent, ItemUomConversionState> {
  final ItemUomConversionsRepository repository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  ItemUomConversionBloc({
    required this.repository,
    required this.authBloc,
  }) : super(const ItemUomConversionState()) {
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
    on<ValidateStructure>(_onValidateStructure);
    on<CheckDuplication>(_onCheckDuplication);
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
      final items = await repository.getItemUomConversions(event.companyId);
      emit(
        state.copyWith(
          status: ItemUomConversionStatus.loaded,
          items: items,
          filteredItems: items,
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
      final hasDuplication = await repository.checkDuplication(event.item);
      if (hasDuplication) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.duplication,
            message: 'UoM conversion already exists for this item',
            hasDuplication: true,
          ),
        );
        return;
      }

      // Check for structure validation
      final isStructureValid = await repository.checkStructureValidation(event.item);
      if (!isStructureValid) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.structureInvalid,
            message: 'UoM structure level already exists for this item',
            structureValid: false,
          ),
        );
        return;
      }

      // Validate consecutive structure levels in create list
      final createItemsWithCurrent = [...state.createItems, event.item];
      final isConsecutive = _validateConsecutiveStructureLevels(createItemsWithCurrent);
      if (!isConsecutive) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.structureInvalid,
            message: 'The UoM structure levels must be consecutive (1, 2, 3...). Please correct the level.',
            structureValid: false,
          ),
        );
        return;
      }

      // Set validCell to true like Java does for successful validation
      final validItem = event.item.copyWith(
        validCell: true,
        createdBy: authBloc.state.userId,
        dateCreated: DateTime.now(),
        company: authBloc.state.companyId,
      );

      await repository.createItemUomConversion(validItem);
      add(LoadItemUomConversions(authBloc.state.companyId!));
      add(ClearCreateList());

      emit(
        state.copyWith(
          status: ItemUomConversionStatus.success,
          message: 'UoM conversion added successfully',
          hasDuplication: false,
          structureValid: true,
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
      final hasDuplication = await repository.checkDuplication(event.item);
      if (hasDuplication) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.duplication,
            message: 'UoM conversion already exists for this item',
            hasDuplication: true,
          ),
        );
        return;
      }

      // Check for structure validation
      final isStructureValid = await repository.checkStructureValidation(event.item);
      if (!isStructureValid) {
        emit(
          state.copyWith(
            status: ItemUomConversionStatus.structureInvalid,
            message: 'UoM structure level already exists for this item',
            structureValid: false,
          ),
        );
        return;
      }

      final updatedItem = event.item.copyWith(
        updatedBy: authBloc.state.userId,
        dateUpdated: DateTime.now(),
      );

      await repository.updateItemUomConversion(updatedItem);
      add(LoadItemUomConversions(authBloc.state.companyId!));

      emit(
        state.copyWith(
          status: ItemUomConversionStatus.success,
          message: 'UoM conversion updated successfully',
          hasDuplication: false,
          structureValid: true,
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

  Future<void> _onDeleteItem(
    DeleteItemUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.deleting));
    try {
      await repository.deleteItemUomConversion(event.item.id!, event.item.company!);
      add(LoadItemUomConversions(authBloc.state.companyId!));
      
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

  Future<void> _onCalculateUomConversion(
    CalculateUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    emit(state.copyWith(status: ItemUomConversionStatus.converting));
    try {
      final factor = await repository.fromOtherToAnother(
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
          conversionError: 'An error occurred during conversion: $e',
        ),
      );
    }
  }



  // UI State Management Methods
  Future<void> _onPrepareCreate(
    PrepareCreateUomConversion event,
    Emitter<ItemUomConversionState> emit,
  ) async {
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

  void _onSetSelectedItem(
    SetSelectedItem event,
    Emitter<ItemUomConversionState> emit,
  ) {
    final updatedUiState = state.uiState.copyWith(selected: event.item);
    emit(state.copyWith(uiState: updatedUiState));
  }

  void _onSetMultiSelectionItems(
    SetMultiSelectionItems event,
    Emitter<ItemUomConversionState> emit,
  ) {
    final updatedUiState = state.uiState.copyWith(
      multiSelectionItems: event.items,
    );
    emit(state.copyWith(uiState: updatedUiState));
  }

  void _onClearCreateList(
    ClearCreateList event,
    Emitter<ItemUomConversionState> emit,
  ) {
    final updatedUiState = state.uiState.copyWith(
      createItems: const [],
      selected: null,
      selected1: null,
    );
    emit(state.copyWith(uiState: updatedUiState));
  }

  Future<void> _onValidateStructure(
    ValidateStructure event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final isConsecutive = _validateConsecutiveStructureLevels(
      event.currentItem != null ? [...event.createItems, event.currentItem!] : event.createItems,
    );

    emit(
      state.copyWith(
        structureValid: isConsecutive,
        message: isConsecutive 
            ? 'Structure levels are valid'
            : 'Structure levels must be consecutive (1, 2, 3...)',
      ),
    );
  }

  Future<void> _onCheckDuplication(
    CheckDuplication event,
    Emitter<ItemUomConversionState> emit,
  ) async {
    final hasDuplication = await repository.checkDuplication(event.item);
    emit(
      state.copyWith(
        hasDuplication: hasDuplication,
        message: hasDuplication 
            ? 'UoM conversion already exists'
            : 'No duplication found',
      ),
    );
  }

  // Helper Methods
  int _getNextTempId(List<ItemUomConversion> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  bool _validateConsecutiveStructureLevels(List<ItemUomConversion> items) {
    final itemsWithLevels = items
        .where((item) => item.uomStructureLevel != null)
        .toList()
      ..sort((a, b) => (a.uomStructureLevel ?? 0).compareTo(b.uomStructureLevel ?? 0));

    if (itemsWithLevels.isEmpty) return true;

    for (int i = 0; i < itemsWithLevels.length; i++) {
      if (itemsWithLevels[i].uomStructureLevel != i + 1) {
        return false;
      }
    }

    return true;
  }
}