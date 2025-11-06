import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
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

  // Helpers to build scope-based where clauses for queries (company + level-specific scope)
  String _scopeWhereClause(LotExpirationColor color) {
    switch (color.lotExpLevel) {
      case '1':
        return 'company = ? AND branch IS NULL AND item_number IS NULL';
      case '2':
        return 'company = ? AND branch = ? AND item_number IS NULL';
      case '3':
        return 'company = ? AND branch IS NULL AND item_number = ?';
      case '4':
        return 'company = ? AND branch = ? AND item_number = ?';
      default:
        return 'company = ?';
    }
  }

  List<dynamic> _scopeWhereArgs(LotExpirationColor color, int? companyId) {
    final args = <dynamic>[companyId];
    switch (color.lotExpLevel) {
      case '2':
        args.add(color.branch);
        break;
      case '3':
        args.add(color.itemNumber);
        break;
      case '4':
        args.add(color.branch);
        args.add(color.itemNumber);
        break;
      default:
        break;
    }
    return args;
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

      // Additional adjacency validation against existing DB ranges for the same level/scope
      final existingForScope = await db.query(
        'lot_expiration_colors',
        where: _scopeWhereClause(event.color),
        whereArgs: _scopeWhereArgs(event.color, authBloc.state.companyId),
      );

      final existingColors = existingForScope
          .map((m) => LotExpirationColor.fromMap(m))
          .toList();
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

      // Additional adjacency validation against existing DB ranges for the same level/scope (exclude current record)
      final existingForScope = await db.query(
        'lot_expiration_colors',
        where: '${_scopeWhereClause(event.color)} AND id != ?',
        whereArgs: [
          ..._scopeWhereArgs(event.color, authBloc.state.companyId),
          event.color.id,
        ],
      );

      final existingColors = existingForScope
          .map((m) => LotExpirationColor.fromMap(m))
          .toList();
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
      print('❌ Item ID is null in color calculation');
      return null;
    }

    final db = await databaseService.database;

    // Get system constant for lot type
    final systemConstant = systemConstantBloc.state.selected;
    // If Apply Lot Management is disabled, skip color calculation
    if (systemConstant?.applyLotMgmBoolean != true) {
      print(
        '⚠️ Apply Lot Management is disabled in system constants - skipping color calculation',
      );
      return null;
    }
    final lotTypeUdcDetail = await _getLotTypeUdcDetail(
      systemConstant?.lotType,
    );
    final lotType = lotTypeUdcDetail?.detailCode.toUpperCase();

    final daysDifference = calculateDaysDifference(
      expirationDate,
      effectiveDate,
      receivedDate,
      lotType,
    );

    print('''
🎨 COLOR CALCULATION:
  Branch: $branchId, Item: $itemId
  Lot Type: $lotType
  Days Difference: $daysDifference
  Expiration: $expirationDate
  Effective: $effectiveDate
  Received: $receivedDate
''');

    List<Map<String, dynamic>> results = [];

    // Try different levels in order of specificity
    // At this point itemId is already guaranteed non-null (we returned earlier if it was null),
    // so only check branchId here for level 4.
    if (branchId != null) {
      // Level 4: Item Store Level
      print(
        '  ▶ Query Level 4 (Item Store) with args: company=${authBloc.state.companyId}, item=$itemId, branch=$branchId, days=$daysDifference',
      );
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
      print('  ℹ Level 4 returned: ${results.length} rows');
      if (results.isNotEmpty) {
        print('  ✅ Found Level 4 configuration -> ${results.first}');
      }
    }

    if (results.isEmpty) {
      // Level 3: Item Level
      print(
        '  ▶ Query Level 3 (Item) with args: company=${authBloc.state.companyId}, item=$itemId, days=$daysDifference',
      );
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
      print('  ℹ Level 3 returned: ${results.length} rows');
      if (results.isNotEmpty) {
        print('  ✅ Found Level 3 configuration -> ${results.first}');
      }
    }

    if (results.isEmpty && branchId != null) {
      // Level 2: Store Level
      print(
        '  ▶ Query Level 2 (Store) with args: company=${authBloc.state.companyId}, branch=$branchId, days=$daysDifference',
      );
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
      print('  ℹ Level 2 returned: ${results.length} rows');
      if (results.isNotEmpty) {
        print('  ✅ Found Level 2 configuration -> ${results.first}');
      }
    }

    if (results.isEmpty) {
      // Level 1: Company Level
      print(
        '  ▶ Query Level 1 (Company) with args: company=${authBloc.state.companyId}, days=$daysDifference',
      );
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
      print('  ℹ Level 1 returned: ${results.length} rows');
      if (results.isNotEmpty) {
        print('  ✅ Found Level 1 configuration -> ${results.first}');
      }
    }

    if (results.isEmpty) {
      print('  ❌ No color configuration found for any level');
      print(
        '  🔎 Search params -> company: ${authBloc.state.companyId}, branch: $branchId, item: $itemId, lotType: $lotType, daysDifference: $daysDifference',
      );
      return null;
    }

    final color = LotExpirationColor.fromMap(results.first);
    print('  🎯 Final Color: ${color.colorTypeName} (${color.colorTypeCode})');
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

  Future<UdcDetails?> _getLotTypeUdcDetail(int? lotTypeId) async {
    if (lotTypeId == null) {
      print('❌ Lot type ID is null');
      return null;
    }

    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT * FROM udc_details 
      WHERE id = ? AND record_header = (SELECT id FROM udc_header WHERE header_code = 'LT')
      ''',
        [lotTypeId],
      );

      if (result.isNotEmpty) {
        final udc = UdcDetails.fromJson(result.first);
        print('✅ Found UDC detail: ${udc.detailCode} - ${udc.description1}');
        return udc;
      } else {
        print('❌ No UDC detail found for ID: $lotTypeId with header LT');
        // Try without header constraint as fallback
        final fallbackResult = await db.rawQuery(
          'SELECT * FROM udc_details WHERE id = ?',
          [lotTypeId],
        );
        if (fallbackResult.isNotEmpty) {
          final udc = UdcDetails.fromJson(fallbackResult.first);
          print(
            '✅ Found UDC detail (fallback): ${udc.detailCode} - ${udc.description1}',
          );
          return udc;
        }
        return null;
      }
    } catch (e) {
      print('❌ Error getting lot type UDC: $e');
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
