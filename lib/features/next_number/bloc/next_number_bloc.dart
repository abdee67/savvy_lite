// features/stock/next_number/blocs/next_number_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_event.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_state.dart';
import 'package:savvy_stock/features/next_number/model/next_number_model.dart';

class NextNumberBloc extends Bloc<NextNumberEvent, NextNumberState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  NextNumberBloc({required this.databaseService, required this.authBloc})
    : super(const NextNumberState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadNextNumbers(authState.companyId!));
      }
    });

    on<LoadNextNumbers>(_onLoadNextNumbers);
    on<GenerateNextNumber>(_onGenerateNextNumber);
    on<SaveNextNumber>(_onSaveNextNumber);
    on<UpdateNextNumber>(_onUpdateNextNumber);
    on<DeleteNextNumber>(_onDeleteNextNumber);
    on<PrepareCreateNextNumber>(_onPrepareCreate);
    on<PrepareCopyNextNumber>(_onPrepareCopy);
    on<PrepareEditNextNumber>(_onPrepareEdit);
    on<SetSelectedNextNumber>(_onSetSelected);
    on<SetMultiSelectionNextNumbers>(_onSetMultiSelection);
    on<AddToCreateList>(_onAddToCreateList);
    on<RemoveFromCreateList>(_onRemoveFromCreateList);
    on<ClearCreateList>(_onClearCreateList);
    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadNextNumbers(
    LoadNextNumbers event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.loading));
    try {
      final db = await databaseService.database;
      final nextNumbers = await db.rawQuery(
        '''
        SELECT * FROM next_number 
        WHERE company = ? 
        ORDER BY next_number_code
      ''',
        [event.companyId],
      );

      final nextNumberList = nextNumbers
          .map((p) => NextNumberModel.fromMap(p))
          .toList();

      emit(
        state.copyWith(
          status: NextNumberStatus.loaded,
          items: nextNumberList,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to load next numbers: $e',
        ),
      );
    }
  }

  Future<void> _onGenerateNextNumber(
    GenerateNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    if (event.code.isEmpty) {
      emit(state.copyWith(message: 'Code cannot be empty'));
      return;
    }

    emit(state.copyWith(status: NextNumberStatus.generating));
    try {
      final db = await databaseService.database;

      // Find the next number record for this code and company
      final nextNumberRecords = await db.rawQuery(
        '''
        SELECT * FROM next_number 
        WHERE company = ? AND next_number_code = ?
      ''',
        [state.companyId, event.code],
      );

      int nextNumber;
      NextNumberModel? recordToUpdate;

      if (nextNumberRecords.isEmpty) {
        // No record found, start from 1
        nextNumber = 1;

        // Create a new record starting from 2
        final newRecord = NextNumberModel(
          nextNumberCode: event.code,
          nextNumberDescription: _getDescriptionForCode(event.code),
          nextNumber: 2,
          company: state.companyId,
        );

        await db.insert('next_number', newRecord.toMap());
      } else {
        // Record found, get current number and increment
        recordToUpdate = NextNumberModel.fromMap(nextNumberRecords.first);
        nextNumber = recordToUpdate.nextNumber!;
        if (recordToUpdate.nextNumber == null) {
          nextNumber = 1;
          recordToUpdate = recordToUpdate.copyWith(nextNumber: 2);
        } else {
          nextNumber = recordToUpdate.nextNumber!;
          recordToUpdate = recordToUpdate.copyWith(nextNumber: nextNumber + 1);
        }
        // Update the record with next number

        await db.update(
          'next_number',
          recordToUpdate.toMap(),
          where: 'id = ? AND company = ?',
          whereArgs: [recordToUpdate.id, state.companyId],
        );
      }

      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          generatedNumber: nextNumber,
          message: 'Generated next number: $nextNumber for code: ${event.code}',
        ),
      );

      // Reload the list to reflect changes
      add(LoadNextNumbers(state.companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to generate next number: $e',
        ),
      );
    }
  }

  String _getDescriptionForCode(String code) {
    final descriptions = {
      'LM': 'Lot Master',
      'PO': 'Purchase Order',
      'SO': 'Sales Order',
      'GR': 'Goods Receipt',
      'GI': 'Goods Issue',
      'TR': 'Transfer',
      'AD': 'Adjustment',
      // Add more codes as needed
    };

    return descriptions[code] ?? 'Next Number for $code';
  }

  Future<void> _onSaveNextNumber(
    SaveNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.creating));
    try {
      final db = await databaseService.database;
      final itemMap = event.item.toMap();
      itemMap.remove('id');

      await db.insert('next_number', itemMap);

      add(LoadNextNumbers(state.companyId));
      add(ClearCreateList());

      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: 'Next number saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to save next number: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateNextNumber(
    UpdateNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.updating));
    try {
      final db = await databaseService.database;
      final itemMap = event.item.toMap();

      await db.update(
        'next_number',
        itemMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, state.companyId],
      );

      add(LoadNextNumbers(state.companyId));
      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: 'Next number updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to update next number: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteNextNumber(
    DeleteNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.deleting));
    try {
      final db = await databaseService.database;

      await db.delete(
        'next_number',
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, state.companyId],
      );

      add(LoadNextNumbers(state.companyId));
      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: 'Next number deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to delete next number: $e',
        ),
      );
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreateNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.createItems);
    final newNextNumber = NextNumberModel(
      tempId: nextTempId,
      nextNumberCode: '',
      nextNumberDescription: '',
      nextNumber: 1,
      company: event.companyId,
    );

    emit(
      state.copyWith(
        createItems: [...state.createItems, newNextNumber],
        selected: newNextNumber,
        selected2: NextNumberModel(
          nextNumberCode: '',
          nextNumberDescription: '',
          nextNumber: 1,
          company: event.companyId,
        ),
      ),
    );
  }

  Future<void> _onPrepareCopy(
    PrepareCopyNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.createItems);
    final copiedNextNumber = event.item.copyWith(tempId: nextTempId, id: null);

    emit(
      state.copyWith(
        createItems: [...state.createItems, copiedNextNumber],
        selected: copiedNextNumber,
      ),
    );
  }

  Future<void> _onPrepareEdit(
    PrepareEditNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.loading));
    try {
      final db = await databaseService.database;

      // Load default next numbers (company IS NULL)
      final defaultNextNumbers = await db.rawQuery('''
        SELECT * FROM next_number 
        WHERE company IS NULL
      ''');

      final defaultList = defaultNextNumbers
          .map((p) => NextNumberModel.fromMap(p))
          .toList();

      // Create copies with null IDs for editing
      final editList = defaultList
          .map((item) => item.copyWith(id: null))
          .toList();

      emit(
        state.copyWith(status: NextNumberStatus.loaded, editItems: editList),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to prepare edit: $e',
        ),
      );
    }
  }

  // Simple state update handlers
  Future<void> _onSetSelected(
    SetSelectedNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(selected: event.item));
  }

  Future<void> _onSetMultiSelection(
    SetMultiSelectionNextNumbers event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(multiSelectionItems: event.items));
  }

  Future<void> _onAddToCreateList(
    AddToCreateList event,
    Emitter<NextNumberState> emit,
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
    Emitter<NextNumberState> emit,
  ) async {
    final updatedCreateItems = state.createItems
        .where((item) => item.tempId != event.item.tempId)
        .toList();

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  Future<void> _onClearCreateList(
    ClearCreateList event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(
      state.copyWith(createItems: const [], selected: null, selected1: null),
    );
  }

  Future<void> _onCancelCreate(
    CancelCreate event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(
      state.copyWith(selected: null, createItems: const [], items: const []),
    );
  }

  Future<void> _onCancelUpdate(
    CancelUpdate event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  int _getNextTempId(List<NextNumberModel> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  // Public method to generate formatted numbers (like "LM000001")
  Future<String> generateFormattedNumber(String code) async {
    final number = await _generateNumber(code);
    return number.toString();
  }

  Future<int> _generateNumber(String code) async {
    final db = await databaseService.database;

    final nextNumberRecords = await db.rawQuery(
      '''
      SELECT * FROM next_number 
      WHERE company = ? AND next_number_code = ?
    ''',
      [state.companyId, code],
    );

    if (nextNumberRecords.isEmpty) {
      // Create new record starting from 2, return 1
      final newRecord = NextNumberModel(
        nextNumberCode: code,
        nextNumberDescription: _getDescriptionForCode(code),
        nextNumber: 2,
        company: state.companyId,
      );

      await db.insert('next_number', newRecord.toMap());
      return 1;
    } else {
      final record = NextNumberModel.fromMap(nextNumberRecords.first);
      final currentNumber = record.nextNumber;

      // Update record
      await db.update(
        'next_number',
        record.copyWith(nextNumber: currentNumber! + 1).toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [record.id, state.companyId],
      );

      return currentNumber;
    }
  }
}
