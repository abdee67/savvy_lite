import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_state.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_event.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_state.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class LotExpirationColorsBloc
    extends Bloc<LotExpirationColorsEvent, LotExpirationColorsState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  LotExpirationColorsBloc({
    required this.databaseService,
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
      final db = await databaseService.database;
      final colors = await db.rawQuery(
        '''
        SELECT lec.*,
               b.description as branch_name,
               it.item_description,
               it.item_description as item_description,
               ud.detail_code as color_type_code,
               ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN branch_table b ON lec.branch = b.id
        LEFT JOIN items_table it ON lec.item_number = it.id
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ?
        ORDER BY 
          CASE 
            WHEN lec.lot_exp_level = '1' THEN 1
            WHEN lec.lot_exp_level = '2' THEN 2  
            WHEN lec.lot_exp_level = '3' THEN 3
            WHEN lec.lot_exp_level = '4' THEN 4
            ELSE 5
          END,
          lec.days_minimum
      ''',
        [event.companyId],
      );

      final colorList = colors
          .map((p) => LotExpirationColor.fromMap(p))
          .toList();

      emit(
        state.copyWith(
          status: LotExpirationColorsStatus.loaded,
          items: colorList,
          filteredItems: colorList,
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
      final db = await databaseService.database;

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

      final colorMap = event.color.toMap();
      colorMap.remove('id');

      await db.insert('lot_expiration_colors', colorMap);

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
          message: 'Failed to save lot expiration color: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateColor(
    UpdateLotExpirationColors event,
    Emitter<LotExpirationColorsState> emit,
  ) async {
    emit(state.copyWith(status: LotExpirationColorsStatus.saving));
    try {
      final db = await databaseService.database;

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

      await db.update(
        'lot_expiration_colors',
        event.color.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [event.color.id, authBloc.state.companyId],
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
      final db = await databaseService.database;

      await db.delete(
        'lot_expiration_colors',
        where: 'id = ? AND company = ?',
        whereArgs: [event.color.id, authBloc.state.companyId],
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
      final db = await databaseService.database;
      final batch = db.batch();

      for (final color in event.colors) {
        batch.delete(
          'lot_expiration_colors',
          where: 'id = ? AND company = ?',
          whereArgs: [color.id, authBloc.state.companyId],
        );
      }

      await batch.commit();
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
    final isDuplicate = await _checkForDuplicate(color);
    if (isDuplicate) {
      return ValidationResult(
        false,
        'Duplicate lot expiration color configuration found',
      );
    }

    return ValidationResult(true, '');
  }

  Future<bool> _checkForDuplicate(LotExpirationColor color) async {
    final db = await databaseService.database;

    var whereClause = 'company = ? AND color_type = ?';
    final whereArgs = <dynamic>[authBloc.state.companyId, color.colorType];

    switch (color.lotExpLevel) {
      case '1': // Company level
        whereClause += ' AND branch IS NULL AND item_number IS NULL';
        break;
      case '2': // Store level
        whereClause += ' AND branch = ? AND item_number IS NULL';
        whereArgs.add(color.branch);
        break;
      case '3': // Item level
        whereClause += ' AND branch IS NULL AND item_number = ?';
        whereArgs.add(color.itemNumber);
        break;
      case '4': // Item store level
        whereClause += ' AND branch = ? AND item_number = ?';
        whereArgs.addAll([color.branch, color.itemNumber]);
        break;
    }

    // Exclude current record when updating
    if (color.id != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(color.id);
    }

    final result = await db.query(
      'lot_expiration_colors',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
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

    // Check for range overlaps
    for (int i = 0; i < sortedByMax.length - 1; i++) {
      final currentMax = sortedByMax[i].daysMaximum;
      final nextMin = sortedByMin[i + 1].daysMinimum;

      if (currentMax != null && nextMin != null && currentMax >= nextMin) {
        return false;
      }
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
    if (itemId == null) return null;

    final db = await databaseService.database;
    // Get system constant for lot type
    final systemConstant = systemConstantBloc.state.selected;
    final lotTypeUdcDetail = await _getLotTypeUdcDetail(
      systemConstant?.lotType,
    );
    final lotType = lotTypeUdcDetail?.detailCode.toUpperCase();

    final daysDifference = _calculateDaysDifference(
      expirationDate,
      effectiveDate,
      receivedDate,
      lotType,
    );

    if (daysDifference == null) return null;

    List<Map<String, dynamic>> results = [];

    // Try different levels in order of specificity
    if (branchId != null && itemId != null) {
      // Level 4: Item Store Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.item_number = ? 
        AND lec.branch = ?
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
      ''',
        [authBloc.state.companyId, itemId, branchId, daysDifference],
      );
    }

    if (results.isEmpty && itemId != null) {
      // Level 3: Item Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.item_number = ? 
        AND lec.branch IS NULL
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
      ''',
        [authBloc.state.companyId, itemId, daysDifference],
      );
    }

    if (results.isEmpty && branchId != null) {
      // Level 2: Store Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.branch = ?
        AND lec.item_number IS NULL
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
      ''',
        [authBloc.state.companyId, branchId, daysDifference],
      );
    }

    if (results.isEmpty) {
      // Level 1: Company Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.branch IS NULL
        AND lec.item_number IS NULL
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
      ''',
        [authBloc.state.companyId, daysDifference],
      );
    }

    if (results.isNotEmpty) {
      return LotExpirationColor.fromMap(results.first);
    }

    // Fallback: if no configuration found, derive a default color by days
    // Business default:
    // - For Expiration/Effective (X/F):
    //   days<=0 => RED (expired)
    //   days<=7 => YEL (near expiry)
    //   else    => GRN (ok)
    // - For Received (R):
    //   days (abs) <=7 => YEL else GRN
    if (lotType == 'R') {
      final absDays = daysDifference.abs();
      if (absDays <= 7) {
        return LotExpirationColor(
          colorTypeCode: 'YEL',
          colorTypeName: 'Yellow',
        );
      }
      return LotExpirationColor(colorTypeCode: 'GRN', colorTypeName: 'Green');
    } else {
      if (daysDifference <= 0) {
        return LotExpirationColor(colorTypeCode: 'RED', colorTypeName: 'Red');
      } else if (daysDifference <= 7) {
        return LotExpirationColor(
          colorTypeCode: 'YEL',
          colorTypeName: 'Yellow',
        );
      } else {
        return LotExpirationColor(colorTypeCode: 'GRN', colorTypeName: 'Green');
      }
    }
  }

  int _calculateDaysDifference(
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

  Future<UdcDetails?> _getLotTypeUdcDetail(int? lotTypeId) async {
    if (lotTypeId == null) return null;
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
        SELECT * FROM udc_details WHERE id = ?
      ''',
        [lotTypeId],
      );
      return result.isNotEmpty ? UdcDetails.fromJson(result.first) : null;
    } catch (e) {
      print('Error getting lot type UDC: $e');
      return null;
    }
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
