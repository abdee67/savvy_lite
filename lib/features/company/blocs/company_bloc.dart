// features/Company/blocs/Company_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/company/blocs/company_event.dart';
import 'package:savvy_stock/features/company/blocs/company_state.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  CompanyBloc({required this.databaseService, required this.authBloc})
    : super(const CompanyState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadCompanys(authState.companyId!));
      }
    });
    on<LoadCompanys>(_onLoadCompanys);
    on<CreateCompany>(_onCreateCompany);
    on<UpdateCompany>(_onUpdateCompany);
    on<DeleteCompany>(_onDeleteCompany);
    on<SearchCompanys>(_onSearchCompanys);
    on<SelectCompany>(_onSelectCompany);
    on<SelectAllCompanys>(_onSelectAllCompanys);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedCompanys>(_onDeleteSelectedCompanys);
    on<ShowCompanyDetail>(_onShowCompanyDetail);
    on<HideCompanyDetail>(_onHideCompanyDetail);
    on<ExportCompany>(_onExportCompany);
    on<ExportSingleCompany>(_onExportSingleCompany);
    on<SetCompanyForm>(_onSetCompanyForm);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCompanys(
    LoadCompanys event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyState(status: CompanyStatus.loading));
    try {
      final db = await databaseService.database;
      final companys = await db.query(
        'company_table',
        where: 'id = ?',
        whereArgs: [event.companyId],
      );

      final companyList = companys.map((p) => Company.fromMap(p)).toList();

      emit(
        CompanyState(
          status: CompanyStatus.success,
          companys: companyList,
          filteredCompanys: companyList,
          searchQuery: '',
          detailStatus: CompanyDetailStatus.hidden,
          companyId: event.companyId,
          selectedCompanys: [],
        ),
      );
    } catch (e) {
      emit(
        CompanyState(
          status: CompanyStatus.failure,
          message: 'Failed to load Companys: $e',
        ),
      );
    }
  }

  Future<void> _onCreateCompany(
    CreateCompany event,
    Emitter<CompanyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CompanyStatus.creating,
        message: 'Creating Company...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyMap = event.company.toMap();

      //remove id for new company insertion
      companyMap.remove('id');

      await db.insert('company_table', (companyMap));
      add(LoadCompanys(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: CompanyStatus.success,
          message: 'Company created successfully',
        ),
      );
    } catch (e) {
      emit(
        CompanyState(
          status: CompanyStatus.failure,
          message: 'Failed to create Company: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateCompany(
    UpdateCompany event,
    Emitter<CompanyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CompanyStatus.updating,
        message: 'Updating Company...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // FIX: Add null checks
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CompanyStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      // Authorization check: Ensure user can only update their own company
      if (event.company.id != companyId) {
        emit(
          state.copyWith(
            status: CompanyStatus.failure,
            message: 'Unauthorized: You can only update your own company',
          ),
        );
        return;
      }

      final companyMap = event.company.toMap();

      await db.update(
        'company_table',
        companyMap,
        where: 'id = ?',
        whereArgs: [event.company.id],
      );

      add(LoadCompanys(companyId));

      emit(
        state.copyWith(
          status: CompanyStatus.success,
          message: 'Company updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CompanyStatus.failure,
          message: 'Failed to update Company: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteCompany(
    DeleteCompany event,
    Emitter<CompanyState> emit,
  ) async {
    emit(state.copyWith(status: CompanyStatus.deleting, message: 'Deleting..'));
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // Authorization check: Ensure user can only delete their own company
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CompanyStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      if (event.companyId != companyId) {
        emit(
          state.copyWith(
            status: CompanyStatus.failure,
            message: 'Unauthorized: You can only delete your own company',
          ),
        );
        return;
      }

      await db.delete(
        'company_table',
        where: 'id = ?',
        whereArgs: [event.companyId],
      );
      final updateCompanys = List<Company>.from(state.companys)
        ..removeWhere((p) => p.id == event.companyId);
      final updateFilteredCompanys = List<Company>.from(state.filteredCompanys)
        ..removeWhere((p) => p.id == event.companyId);
      emit(
        state.copyWith(
          companys: updateCompanys,
          filteredCompanys: updateFilteredCompanys,
          recentlyDeleted: [...state.recentlyDeleted, event.deletedCompany],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            event.deletedIndex,
          ],
          message: 'Company deleted successfully',
        ),
      );
      add(LoadCompanys(authBloc.state.companyId!));
    } catch (e) {
      emit(
        CompanyState(
          status: CompanyStatus.failure,
          message: 'Failed to delete Company: $e',
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<CompanyState> emit) {
    emit(state.copyWith(selectedCompanys: []));
  }

  void _onSearchCompanys(SearchCompanys event, Emitter<CompanyState> emit) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredCompanys: state.companys,
          selectedCompanys: [],
          searchQuery: '',
          status: CompanyStatus.success,
        ),
      );
      return;
    }

    final filtered = state.companys.where((company) {
      return company.companyName.toLowerCase().contains(query) ||
          company.city!.toLowerCase().contains(query) ||
          company.addressLine!.toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredCompanys: filtered,
        searchQuery: query,
        selectedCompanys: [],
        status: CompanyStatus.searching,
      ),
    );
  }

  void _onSelectCompany(SelectCompany event, Emitter<CompanyState> emit) {
    final selectedCompanys = List<Company>.from(state.selectedCompanys);
    if (event.isSelected) {
      selectedCompanys.add(event.company);
    } else {
      selectedCompanys.removeWhere((company) => company.id == event.company.id);
    }
    emit(state.copyWith(selectedCompanys: selectedCompanys));
  }

  void _onSelectAllCompanys(
    SelectAllCompanys event,
    Emitter<CompanyState> emit,
  ) {
    if (state.selectedCompanys.length == event.companys.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedCompanys: []));
    } else {
      // Select all
      emit(state.copyWith(selectedCompanys: List.from(event.companys)));
    }
  }

  void _onSetCompanyForm(SetCompanyForm event, Emitter<CompanyState> emit) {
    emit(state.copyWith(companyForm: event.company));
  }

  void _onDeleteSelectedCompanys(
    DeleteSelectedCompanys event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // Authorization check: Ensure user can only delete their own company
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CompanyStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      // Verify all selected companies belong to the user
      for (final selectedId in event.selectedCompanys) {
        if (selectedId != companyId) {
          emit(
            state.copyWith(
              status: CompanyStatus.failure,
              message: 'Unauthorized: You can only delete your own company',
            ),
          );
          return;
        }
      }

      final placeholders = List.filled(
        event.selectedCompanys.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedCompanys];
      await db.delete(
        'company_table',
        where: 'id IN ($placeholders)',
        whereArgs: whereArgs,
      );
      final updatedCompanys = state.companys
          .where((e) => !event.selectedCompanys.contains(e.id))
          .toList();
      final updatedFiltered = state.filteredCompanys
          .where((e) => !event.selectedCompanys.contains(e.id))
          .toList();

      emit(
        state.copyWith(
          companys: updatedCompanys,
          filteredCompanys: updatedFiltered,
          selectedCompanys: [],
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedCompanys],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
          message:
              '${event.selectedCompanys.length} employees deleted successfully',
        ),
      );
      add(LoadCompanys(authBloc.state.companyId!));
    } catch (e) {
      emit(
        CompanyState(
          status: CompanyStatus.failure,
          message: 'Failed to delete selected Companys: $e',
        ),
      );
    }
  }

  void _onShowCompanyDetail(
    ShowCompanyDetail event,
    Emitter<CompanyState> emit,
  ) {
    emit(
      state.copyWith(
        companyDetail: event.company,
        detailStatus: CompanyDetailStatus.showing,
      ),
    );
  }

  void _onHideCompanyDetail(
    HideCompanyDetail event,
    Emitter<CompanyState> emit,
  ) {
    emit(
      state.copyWith(
        detailStatus: CompanyDetailStatus.hidden,
        companyDetail: null,
      ),
    );
  }

  void _onExportCompany(ExportCompany event, Emitter<CompanyState> emit) {
    emit(state.copyWith(status: CompanyStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: CompanyStatus.success,
          isExporting: false,
          exportedCompanys: event.companysToExport,
          message:
              'Exported ${event.companysToExport.length} companys successfully',
        ),
      );
    });
  }

  void _onExportSingleCompany(
    ExportSingleCompany event,
    Emitter<CompanyState> emit,
  ) {
    emit(state.copyWith(status: CompanyStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: CompanyStatus.success,
          isExporting: false,
          exportedCompany: event.companyToExport,
          message: 'Exported ${event.companyToExport} companys successfully',
        ),
      );
    });
  }
}
