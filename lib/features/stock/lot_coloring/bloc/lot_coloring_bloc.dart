import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_event.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_state.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';

class LotExpirationColorsBloc
    extends Bloc<LotExpirationColorsEvent, LotExpirationColorsState> {
  final LotExpirationColorsRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  LotExpirationColorsBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
  }) : super(const LotExpirationColorsState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadLotExpirationColors(authState.companyId!));
      }
    });

    _systemConstantSubscription = systemConstantBloc.stream.listen((state) {
      if (state.systemConstants.isNotEmpty) {
        add(RecalculateAllColor());
      }
    });

    on<LoadLotExpirationColors>(_onLoadColors);
    on<SaveLotExpirationColors>(_onSaveColor);
    on<UpdateLotExpirationColors>(_onUpdateColor);
    on<DeleteLotExpirationColors>(_onDeleteColor);
    on<DeleteMultipleLotExpirationColors>(_onDeleteMultipleColors);
    on<FilterLotExpirationColors>(_onFilterColors);
    on<ValidateLotExpirationRanges>(_onValidateRanges);
    on<CalculateLotExpirationColor>(_onCalculateColor);
    on<SelectLotExpirationColor>(_onSelectColor);
    on<SelectMultipleLotExpirationColors>(_onSelectMultipleColors);
    on<SearchLotExpirationColors>(_onSearchColors);
    on<ClearSelection>(_onClearSelection);
    on<RecalculateAllColor>(_onRecalculateAllColor);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _systemConstantSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadColors(
    LoadLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(status: LotExpirationColorsStatus.loading));
    try {
      final colors = await repository.loadLotExpirationColors(event.companyId);
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.loaded,
          items: colors,
          filteredItems: colors,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.failure,
          message: 'Failed to load lot expiration colors: $e',
        ),
      );
    }
  }

  Future<void> _onSaveColor(
    SaveLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(status: LotExpirationColorsStatus.saving));
    try {
      // Validate before saving
      final validationResult = await _validateColor(event.color);
      if (!validationResult.isValid) {
        emit(
          state.copyWith(
            status: LotExpirationColorsStatus.failure,
            message: validationResult.errorMessage,
          ),
        );
        return;
      }

      // Additional adjacency validation against existing DB ranges for the same level/scope
      final existingColors = await repository.getColorsForScope(
        event.color,
        authBloc.state.companyId!,
      );

      final combined = <LotExpirationColor>[...existingColors, event.color];
      final rangesValid = await _validateRanges(combined);
      if (!rangesValid) {
        emit(
          state.copyWith(
            status: LotExpirationColorsStatus.failure,
            message:
                'Ranges must be consecutive and non-overlapping for the selected level/scope',
          ),
        );
        return;
      }

      await repository.insertLotExpirationColor(
        event.color,
        authBloc.state.companyId!,
      );

      add(LoadLotExpirationColors(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.success,
          message: 'Lot expiration color saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.failure,
          //message: 'Failed to save lot expiration color: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save lot expiration color: $e');
      }
    }
  }

  Future<void> _onUpdateColor(
    UpdateLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(status: LotExpirationColorsStatus.saving));
    try {
      // Validate before updating
      final validationResult = await _validateColor(event.color);
      if (!validationResult.isValid) {
        emit(
          state.copyWith(
            status: LotExpirationColorsStatus.failure,
            message: validationResult.errorMessage,
          ),
        );
        return;
      }

      // Additional adjacency validation against existing DB ranges for the same level/scope (exclude current record)
      final existingColors = await repository.getColorsForScope(
        event.color,
        authBloc.state.companyId!,
      );

      // Filter out the current record being updated
      final otherColors = existingColors
          .where((c) => c.id != event.color.id)
          .toList();
      final combined = <LotExpirationColor>[...otherColors, event.color];
      final rangesValid = await _validateRanges(combined);
      if (!rangesValid) {
        emit(
          state.copyWith(
            status: LotExpirationColorsStatus.failure,
            message:
                'Ranges must be consecutive and non-overlapping for the selected level/scope',
          ),
        );
        return;
      }

      await repository.updateLotExpirationColor(
        event.color,
        authBloc.state.companyId!,
      );

      add(LoadLotExpirationColors(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.success,
          message: 'Lot expiration color updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.failure,
          message: 'Failed to update lot expiration color: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteColor(
    DeleteLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(status: LotExpirationColorsStatus.deleting));
    try {
      await repository.deleteLotExpirationColor(
        event.color.id!,
        authBloc.state.companyId!,
      );

      add(LoadLotExpirationColors(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.success,
          message: 'Lot expiration color deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.failure,
          message: 'Failed to delete lot expiration color: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleColors(
    DeleteMultipleLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(status: LotExpirationColorsStatus.deleting));
    try {
      await repository.deleteMultipleLotExpirationColors(
        event.colors,
        authBloc.state.companyId!,
      );

      add(LoadLotExpirationColors(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.success,
          message:
              '${event.colors.length} lot expiration colors deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.failure,
          message: 'Failed to delete lot expiration colors: $e',
        ),
      );
    }
  }

  Future<void> _onFilterColors(
    FilterLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    try {
      List<LotExpirationColor> filtered = state.items;

      if (event.level != null) {
        filtered = filtered
            .where((color) => color.lotExpLevel == event.level)
            .toList();
      }

      if (event.branchId != null) {
        filtered = filtered
            .where((color) => color.branch == event.branchId)
            .toList();
      }

      if (event.itemId != null) {
        filtered = filtered
            .where((color) => color.itemNumber == event.itemId)
            .toList();
      }

      emit(state.copyWith(filteredItems: filtered));
    } catch (e) {
      emit(state.copyWith(message: 'Failed to filter colors: $e'));
    }
  }

  Future<void> _onValidateRanges(
    ValidateLotExpirationRanges event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    try {
      final isValid = await _validateRanges(event.colors);
      emit(state.copyWith(areRangesValid: isValid));
    } catch (e) {
      emit(state.copyWith(message: 'Failed to validate ranges: $e'));
    }
  }

  Future<void> _onCalculateColor(
    CalculateLotExpirationColor event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    try {
      final color = await _getLotExpirationColorByDetails(
        event.branch,
        event.item,
        event.expirationDate,
        event.effectiveDate,
        event.receivedDate,
      );

      emit(state.copyWith(calculatedColor: color));
    } catch (e) {
      emit(state.copyWith(message: 'Failed to calculate color: $e'));
    }
  }

  Future<void> _onSelectColor(
    SelectLotExpirationColor event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    final selectedItems = List<LotExpirationColor>.from(state.selectedItems);
    if (event.selected) {
      selectedItems.add(event.color);
    } else {
      selectedItems.removeWhere((item) => event.color.id == item.id);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  Future<void> _onSelectMultipleColors(
    SelectMultipleLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    if (state.selectedItems.length == event.colors.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedItems: []));
    } else {
      // Select all
      emit(state.copyWith(selectedItems: List.from(event.colors)));
    }
  }

  Future<void> _onSearchColors(
    SearchLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredItems: state.items, searchQuery: ''));
    } else {
      final filtered = state.items.where((item) {
        return item.lotExpLevel?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            item.itemNumber?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            item.daysMinimum?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            item.daysMaximum?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            item.colorType?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            item.branch?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true;
      }).toList();

      emit(state.copyWith(filteredItems: filtered, searchQuery: event.query));
    }
  }

  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(selectedItems: []));
  }

  Future<void> _onRecalculateAllColor(
    RecalculateAllColor event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    try {
      // This would typically be called from LotMasterBloc when system constants change
      // Recalculate colors for all lots based on new system constants
      emit(state.copyWith(status: LotExpirationColorsStatus.recalculating));

      // You can add logic here to recalculate colors if needed
      // For now, just reload to ensure fresh data
      add(LoadLotExpirationColors(authBloc.state.companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.failure,
          message: 'Failed to recalculate colors: $e',
        ),
      );
    }
  }

  // Core validation methods
  Future<ValidationResult> _validateColor(LotExpirationColor color) async {
    // Check required fields
    if (color.lotExpLevel == null) {
      return ValidationResult(false, 'Lot expiration level is required');
    }

    if (color.daysMinimum == null || color.daysMaximum == null) {
      return ValidationResult(false, 'Days minimum and maximum are required');
    }

    if (color.daysMaximum! <= color.daysMinimum!) {
      return ValidationResult(
        false,
        'Days maximum must be greater than days minimum',
      );
    }

    if (color.colorType == null) {
      return ValidationResult(false, 'Color type is required');
    }

    // Level-specific validations
    switch (color.lotExpLevel) {
      case '2': // Store level
        if (color.branch == null) {
          return ValidationResult(false, 'Branch is required for store level');
        }
        break;
      case '3': // Item level
        if (color.itemNumber == null) {
          return ValidationResult(
            false,
            'Item number is required for item level',
          );
        }
        break;
      case '4': // Item store level
        if (color.branch == null || color.itemNumber == null) {
          return ValidationResult(
            false,
            'Branch and item number are required for item store level',
          );
        }
        break;
    }

    // Check for duplicates
    final isDuplicate = await repository.checkForDuplicate(
      color,
      authBloc.state.companyId!,
    );
    if (isDuplicate) {
      return ValidationResult(
        false,
        'Duplicate lot expiration color configuration found',
      );
    }

    return ValidationResult(true, '');
  }

  Future<bool> _validateRanges(List<LotExpirationColor> colors) async {
    if (colors.length <= 1) return true;

    // Sort by minimum days
    final sortedByMin = List<LotExpirationColor>.from(colors)
      ..sort((a, b) => (a.daysMinimum ?? 0).compareTo(b.daysMinimum ?? 0));

    final sortedByMax = List<LotExpirationColor>.from(colors)
      ..sort((a, b) => (a.daysMaximum ?? 0).compareTo(b.daysMaximum ?? 0));

    // Check if sorted lists match (no overlapping temp IDs)
    for (int i = 0; i < sortedByMin.length; i++) {
      if (sortedByMin[i].tempId != sortedByMax[i].tempId) {
        return false;
      }
    }

    // Check for range overlaps and enforce adjacency (consecutive boundaries) for the provided set.
    // We require that when the ranges are sorted by daysMaximum descending, the next range's
    // daysMaximum must equal the previous range's daysMinimum - 1 (no gaps, no overlaps).
    // Example: existing range A(min=30,max=179) then B must have max == 29.

    // Build a list sorted by daysMaximum descending
    final sortedByMaxDesc = List<LotExpirationColor>.from(colors)
      ..sort((a, b) => (b.daysMaximum ?? 0).compareTo(a.daysMaximum ?? 0));

    for (int i = 0; i < sortedByMaxDesc.length - 1; i++) {
      final prev = sortedByMaxDesc[i];
      final next = sortedByMaxDesc[i + 1];

      final prevMin = prev.daysMinimum;
      final nextMax = next.daysMaximum;

      // Both ends must be present to validate adjacency
      if (prevMin == null || nextMax == null) return false;

      // Enforce consecutive boundary: nextMax == prevMin - 1
      if (nextMax != prevMin - 1) return false;
    }

    return true;
  }

  Future<LotExpirationColor?> _getLotExpirationColorByDetails(
    int? branchId,
    int? itemId,
    DateTime? expirationDate,
    DateTime? effectiveDate,
    DateTime? receivedDate,
  ) async {
    if (itemId == null) {
      return null;
    }

    // Get system constant for lot type
    final systemConstant = systemConstantBloc.state.selected;
    // If Apply Lot Management is disabled, skip color calculation
    if (systemConstant?.applyLotMgmBoolean != true) {
      return null;
    }

    final lotTypeUdcDetail = await repository.getLotTypeUdcDetail(
      systemConstant?.lotType,
    );
    final lotType = lotTypeUdcDetail?.detailCode.toUpperCase();

    final daysDifference = calculateDaysDifference(
      expirationDate,
      effectiveDate,
      receivedDate,
      lotType,
    );
    final color = await repository.getLotExpirationColorByDetails(
      companyId: authBloc.state.companyId!,
      branchId: branchId,
      itemId: itemId,
      daysDifference: daysDifference,
    );

    return color;
  }

  int calculateDaysDifference(
    DateTime? expirationDate,
    DateTime? effectiveDate,
    DateTime? receivedDate,
    String? lotType,
  ) {
    DateTime? targetDate;

    // Determine target date based on lot type (EXACT JAVA LOGIC)
    if (lotType?.toUpperCase() == 'X') {
      targetDate = expirationDate;
    } else if (lotType?.toUpperCase() == 'F') {
      targetDate = effectiveDate;
    } else if (lotType?.toUpperCase() == 'R') {
      targetDate = receivedDate;
    }

    if (targetDate == null) {
      return 0;
    }
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    // For Received type, use absolute value (same as Java logic)
    return lotType?.toUpperCase() == 'R' ? difference.abs() : difference;
  }

  // Public method for other blocs to use
  Future<LotExpirationColor?> getLotColorType(
    int? branchId,
    int? itemId,
    DateTime? expirationDate,
    DateTime? effectiveDate,
    DateTime? receivedDate,
  ) async {
    final color = await _getLotExpirationColorByDetails(
      branchId,
      itemId,
      expirationDate,
      effectiveDate,
      receivedDate,
    );
    return color;
  }
}

class ValidationResult {
  final bool isValid;
  final String errorMessage;

  ValidationResult(this.isValid, this.errorMessage);
}
