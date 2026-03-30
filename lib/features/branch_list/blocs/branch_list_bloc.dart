// features/Branch/blocs/Branch_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/licensing/services/license_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final LicenseService licenseService;
  StreamSubscription? _authSubscription;

  BranchBloc({
    required this.databaseService,
    required this.authBloc,
    required this.licenseService,
  }) : super(const BranchState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadBranchs(authState.companyId!));
      }
    });
    on<LoadBranchs>(_onLoadBranchs);
    on<CreateBranch>(_onCreateBranch);
    on<UpdateBranch>(_onUpdateBranch);
    on<DeleteBranch>(_onDeleteBranch);
    on<SearchBranchs>(_onSearchBranchs);
    on<SelectBranch>(_onSelectBranch);
    on<SelectAllBranchs>(_onSelectAllBranchs);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedBranchs>(_onDeleteSelectedBranchs);
    on<ShowBranchDetail>(_onShowBranchDetail);
    on<HideBranchDetail>(_onHideBranchDetail);
    on<ExportBranch>(_onExportBranch);
    on<ExportSingleBranch>(_onExportSingleBranch);
    on<SetBranchForm>(_onSetBranchForm);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadBranchs(
    LoadBranchs event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchState(status: BranchStatus.loading));
    try {
      final db = await databaseService.database;
      final branchs = await db.query(
        'branch_table',
        where: 'company = ?',
        whereArgs: [event.companyId],
      );

      final branchList = branchs.map((p) => Branch.fromMap(p)).toList();

      emit(
        BranchState(
          status: BranchStatus.success,
          branchs: branchList,
          filteredBranchs: branchList,
          searchQuery: '',
          detailStatus: BranchDetailStatus.hidden,
          companyId: event.companyId,
          selectedBranchs: [],
        ),
      );
    } catch (e) {
      emit(
        BranchState(
          status: BranchStatus.failure,
          message: 'Failed to load Branchs: $e',
        ),
      );
    }
  }

  Future<void> _onCreateBranch(
    CreateBranch event,
    Emitter<BranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BranchStatus.creating,
        message: 'Creating Branch...',
      ),
    );
    try {
      final db = await databaseService.database;

      // License Logic: Check Branch Limit
      final licenseResult = await licenseService.loadAndValidateLicense();
      if (!licenseResult.isValid) {
        emit(
          BranchState(
            status: BranchStatus.failure,
            message: licenseResult.errorMessage ?? 'License Invalid',
          ),
        );
        return;
      }

      final branchLimit = licenseResult.payload?.branchLimit ?? 0;
      final currentBranchCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM branch_table'),
          ) ??
          0;

      if (currentBranchCount >= branchLimit) {
        emit(
          BranchState(
            status: BranchStatus.failure,
            message:
                'Branch creation limit reached ($branchLimit branches max). Please upgrade your license.',
          ),
        );
        return;
      }

      final branchMap = event.branch.toMap();

      //remove id for new employee insrtion
      branchMap.remove('id');

      //add creation metadata
      branchMap['company'] = authBloc.state.companyId;

      await db.insert('branch_table', branchMap);
      add(LoadBranchs(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: BranchStatus.success,
          message: 'Branch created successfully',
        ),
      );
    } catch (e) {
      emit(
        BranchState(
          status: BranchStatus.failure,
          message: 'Failed to create Branch: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateBranch(
    UpdateBranch event,
    Emitter<BranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BranchStatus.updating,
        message: 'Updating Branch...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // FIX: Add null checks
      if (companyId == null) {
        emit(
          state.copyWith(
            status: BranchStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final branchMap = event.branch.toMap();

      // FIX: Ensure company field is included and not null
      branchMap['company'] = companyId; // Make sure company is set

      await db.update(
        'branch_table',
        branchMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.branch.id, companyId],
      );

      add(LoadBranchs(companyId));

      emit(
        state.copyWith(
          status: BranchStatus.success,
          message: 'Branch updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BranchStatus.failure,
          message: 'Failed to update Branch: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteBranch(
    DeleteBranch event,
    Emitter<BranchState> emit,
  ) async {
    emit(state.copyWith(status: BranchStatus.deleting, message: 'Deleting..'));
    try {
      final db = await databaseService.database;
      await db.delete(
        'branch_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.branchId, authBloc.state.companyId],
      );
      final updateBranchs = List<Branch>.from(state.branchs)
        ..removeWhere((p) => p.id == event.branchId);
      final updateFilteredBranchs = List<Branch>.from(state.filteredBranchs)
        ..removeWhere((p) => p.id == event.branchId);
      emit(
        state.copyWith(
          branchs: updateBranchs,
          filteredBranchs: updateFilteredBranchs,
          recentlyDeleted: [...state.recentlyDeleted, event.deletedBranch],
          message: 'Branch deleted successfully',
        ),
      );
      add(LoadBranchs(authBloc.state.companyId!));
    } catch (e) {
      emit(
        BranchState(
          status: BranchStatus.failure,
          message: 'Failed to delete Branch: $e',
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<BranchState> emit) {
    emit(state.copyWith(selectedBranchs: []));
  }

  void _onSearchBranchs(SearchBranchs event, Emitter<BranchState> emit) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredBranchs: state.branchs,
          selectedBranchs: [],
          searchQuery: '',
          status: BranchStatus.success,
        ),
      );
      return;
    }

    final filtered = state.branchs.where((branch) {
      return branch.description!.toLowerCase().contains(query) ||
          branch.city!.toLowerCase().contains(query) ||
          branch.addressLine!.toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredBranchs: filtered,
        searchQuery: query,
        selectedBranchs: [],
        status: BranchStatus.searching,
      ),
    );
  }

  void _onSelectBranch(SelectBranch event, Emitter<BranchState> emit) {
    final selectedBranchs = List<Branch>.from(state.selectedBranchs);
    if (event.isSelected) {
      selectedBranchs.add(event.branch);
    } else {
      selectedBranchs.removeWhere((branch) => branch.id == event.branch.id);
    }
    emit(state.copyWith(selectedBranchs: selectedBranchs));
  }

  void _onSelectAllBranchs(SelectAllBranchs event, Emitter<BranchState> emit) {
    if (state.selectedBranchs.length == event.branchs.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedBranchs: []));
    } else {
      // Select all
      emit(state.copyWith(selectedBranchs: List.from(event.branchs)));
    }
  }

  void _onSetBranchForm(SetBranchForm event, Emitter<BranchState> emit) {
    emit(state.copyWith(branchForm: event.branch));
  }

  void _onDeleteSelectedBranchs(
    DeleteSelectedBranchs event,
    Emitter<BranchState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final placeholders = List.filled(
        event.selectedBranchs.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedBranchs, authBloc.state.companyId];
      await db.delete(
        'branch_table',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
      final updatedBranchs = state.branchs
          .where((e) => !event.selectedBranchs.contains(e.id))
          .toList();
      final updatedFiltered = state.filteredBranchs
          .where((e) => !event.selectedBranchs.contains(e.id))
          .toList();

      emit(
        state.copyWith(
          branchs: updatedBranchs,
          filteredBranchs: updatedFiltered,
          selectedBranchs: [],
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedBranchs],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
          message:
              '${event.selectedBranchs.length} employees deleted successfully',
        ),
      );
      add(LoadBranchs(authBloc.state.companyId!));
    } catch (e) {
      emit(
        BranchState(
          status: BranchStatus.failure,
          message: 'Failed to delete selected Branchs: $e',
        ),
      );
    }
  }

  void _onShowBranchDetail(ShowBranchDetail event, Emitter<BranchState> emit) {
    emit(
      state.copyWith(
        branchDetail: event.branch,
        detailStatus: BranchDetailStatus.showing,
      ),
    );
  }

  void _onHideBranchDetail(HideBranchDetail event, Emitter<BranchState> emit) {
    emit(
      state.copyWith(
        detailStatus: BranchDetailStatus.hidden,
        branchDetail: null,
      ),
    );
  }

  void _onExportBranch(ExportBranch event, Emitter<BranchState> emit) {
    emit(state.copyWith(status: BranchStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: BranchStatus.success,
          isExporting: false,
          exportedBranchs: event.branchsToExport,
          message:
              'Exported ${event.branchsToExport.length} branchs successfully',
        ),
      );
    });
  }

  void _onExportSingleBranch(
    ExportSingleBranch event,
    Emitter<BranchState> emit,
  ) {
    emit(state.copyWith(status: BranchStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: BranchStatus.success,
          isExporting: false,
          exportedBranch: event.branchToExport,
          message: 'Exported ${event.branchToExport} branchs successfully',
        ),
      );
    });
  }
}
