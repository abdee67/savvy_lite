// features/next_number/blocs/next_number_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_event.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_state.dart';
import 'package:savvy_stock/features/next_number/model/next_number_model.dart';
import 'package:savvy_stock/features/next_number/repo/next_number_repo.dart';

class NextNumberBloc extends Bloc<NextNumberEvent, NextNumberState> {
  final NextNumberRepository repository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  NextNumberBloc({required this.repository, required this.authBloc})
    : super(const NextNumberState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadNextNumbers(authState.companyId!));
      }
    });

    on<LoadNextNumbers>(_onLoadNextNumbers);
    on<GenerateNextNumber>(_onGenerateNextNumber);
    on<GenerateFormattedNumber>(_onGenerateFormattedNumber);
    on<SaveNextNumber>(_onSaveNextNumber);
    on<UpdateNextNumber>(_onUpdateNextNumber);
    on<DeleteNextNumber>(_onDeleteNextNumber);
    on<BatchSaveNextNumbers>(_onBatchSaveNextNumbers);
    on<BatchUpdateNextNumbers>(_onBatchUpdateNextNumbers);
    on<BatchDeleteNextNumbers>(_onBatchDeleteNextNumbers);
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
    on<ResetNextNumber>(_onResetNextNumber);
    on<CheckCodeExists>(_onCheckCodeExists);
    on<CopyDefaultNextNumbers>(_onCopyDefaultNextNumbers);
    on<GetNextNumberSummary>(_onGetNextNumberSummary);
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
      final items = await repository.getNextNumbers(event.companyId);

      emit(
        state.copyWith(
          status: NextNumberStatus.loaded,
          items: items,
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
      final nextNumber = await repository.generateNextNumber(
        event.code,
        state.companyId,
      );

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

  Future<void> _onGenerateFormattedNumber(
    GenerateFormattedNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    if (event.code.isEmpty) {
      emit(state.copyWith(message: 'Code cannot be empty'));
      return;
    }

    emit(state.copyWith(status: NextNumberStatus.generating));
    try {
      final formattedNumber = await repository.generateFormattedNumber(
        event.code,
        state.companyId,
      );

      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          generatedFormattedNumber: formattedNumber,
          message: 'Generated formatted number: $formattedNumber',
        ),
      );

      // Reload the list to reflect changes
      add(LoadNextNumbers(state.companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to generate formatted number: $e',
        ),
      );
    }
  }

  Future<void> _onSaveNextNumber(
    SaveNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.creating));
    try {
      // Check for code duplication
      final codeExists = await repository.checkCodeExists(
        event.item.nextNumberCode,
        state.companyId,
      );

      if (codeExists) {
        emit(
          state.copyWith(
            status: NextNumberStatus.duplicationFound,
            message: 'Next number code already exists',
          ),
        );
        return;
      }

      final itemToSave = event.item.copyWith(company: state.companyId);
      await repository.createNextNumber(itemToSave);

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
      // Check for code duplication (excluding current item)
      final codeExists = await repository.checkCodeExists(
        event.item.nextNumberCode,
        state.companyId,
        excludeId: event.item.id,
      );

      if (codeExists) {
        emit(
          state.copyWith(
            status: NextNumberStatus.duplicationFound,
            message: 'Next number code already exists',
          ),
        );
        return;
      }

      await repository.updateNextNumber(event.item);

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
      await repository.deleteNextNumber(event.item.id!, state.companyId);

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

  Future<void> _onBatchSaveNextNumbers(
    BatchSaveNextNumbers event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.creating));
    try {
      final itemsWithCompany = event.items
          .map((item) => item.copyWith(company: state.companyId))
          .toList();

      await repository.batchInsertNextNumbers(itemsWithCompany);

      add(LoadNextNumbers(state.companyId));
      add(ClearCreateList());

      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: '${event.items.length} next numbers saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to save next numbers: $e',
        ),
      );
    }
  }

  Future<void> _onBatchUpdateNextNumbers(
    BatchUpdateNextNumbers event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.updating));
    try {
      await repository.batchUpdateNextNumbers(event.items);

      add(LoadNextNumbers(state.companyId));
      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: '${event.items.length} next numbers updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to update next numbers: $e',
        ),
      );
    }
  }

  Future<void> _onBatchDeleteNextNumbers(
    BatchDeleteNextNumbers event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.deleting));
    try {
      final ids = event.items.map((item) => item.id!).toList();
      await repository.batchDeleteNextNumbers(ids, state.companyId);

      add(LoadNextNumbers(state.companyId));
      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: '${event.items.length} next numbers deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to delete next numbers: $e',
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
      final defaultNextNumbers = await repository.getDefaultNextNumbers();

      // Create copies with null IDs for editing
      final editList = defaultNextNumbers
          .map((item) => item.copyWith(id: null, company: state.companyId))
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

  Future<void> _onResetNextNumber(
    ResetNextNumber event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.updating));
    try {
      await repository.resetNextNumber(
        event.code,
        event.startFrom,
        state.companyId,
      );

      add(LoadNextNumbers(state.companyId));
      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: 'Next number for ${event.code} reset to ${event.startFrom}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to reset next number: $e',
        ),
      );
    }
  }

  Future<void> _onCheckCodeExists(
    CheckCodeExists event,
    Emitter<NextNumberState> emit,
  ) async {
    try {
      final codeExists = await repository.checkCodeExists(
        event.code,
        state.companyId,
        excludeId: event.excludeId,
      );

      emit(
        state.copyWith(
          hasDuplication: codeExists,
          message: codeExists ? 'Code already exists' : 'Code is available',
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Error checking code existence: $e'));
    }
  }

  Future<void> _onCopyDefaultNextNumbers(
    CopyDefaultNextNumbers event,
    Emitter<NextNumberState> emit,
  ) async {
    emit(state.copyWith(status: NextNumberStatus.creating));
    try {
      await repository.copyDefaultNextNumbersToCompany(state.companyId);

      add(LoadNextNumbers(state.companyId));
      emit(
        state.copyWith(
          status: NextNumberStatus.success,
          message: 'Default next numbers copied successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NextNumberStatus.failure,
          message: 'Failed to copy default next numbers: $e',
        ),
      );
    }
  }

  Future<void> _onGetNextNumberSummary(
    GetNextNumberSummary event,
    Emitter<NextNumberState> emit,
  ) async {
    try {
      final summary = await repository.getNextNumberSummary(state.companyId);
      emit(state.copyWith(nextNumberSummary: summary));
    } catch (e) {
      emit(state.copyWith(message: 'Failed to get next number summary: $e'));
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

  // Helper methods
  int _getNextTempId(List<NextNumberModel> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  // Public methods
  Future<int> generateFormattedNumber(String code) async {
    final number = await repository.generateNextNumber(code, state.companyId);
    return number;
  }

  Future<String> generateFormattedNumberString(String code) async {
    return await repository.generateFormattedNumber(code, state.companyId);
  }

  // Get description for code
  String getDescriptionForCode(String code) {
    final descriptions = {
      'LM': 'Lot Master',
      'PO': 'Purchase Order',
      'SO': 'Sales Order',
      'GR': 'Goods Receipt',
      'GI': 'Goods Issue',
      'TR': 'Transfer',
      'AD': 'Adjustment',
      'TN': 'Transaction Number',
      'IN': 'Invoice Number',
      'CN': 'Credit Note',
      'DN': 'Debit Note',
      'RN': 'Return Note',
      'SR': 'Sales Return',
      'PR': 'Purchase Return',
      'WO': 'Work Order',
      'MO': 'Manufacturing Order',
      'QC': 'Quality Control',
      'ST': 'Stock Transfer',
      'RT': 'Return',
      'JV': 'Journal Voucher',
    };

    return descriptions[code] ?? 'Next Number for $code';
  }
}
