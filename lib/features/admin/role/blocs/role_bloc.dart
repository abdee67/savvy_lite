// features/role/blocs/role_bloc.dart
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/role/repo/role_repo.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final RoleRepository repository;
  final AuthBloc authBloc;

  RoleBloc({required this.repository, required this.authBloc})
    : super(RoleState(status: RoleStatus.initial)) {
    on<LoadRoles>(_onLoadRoles);
    on<CreateRole>(_onCreateRole);
    on<UpdateRole>(_onUpdateRole);
    on<DeleteRole>(_onDeleteRole);
    on<DeleteMultipleRoles>(_onDeleteMultipleRoles);
    on<AssignPrivilegesToRole>(_onAssignPrivilegesToRole);
    on<SearchRoles>(_onSearchRoles);
    on<SelectRole>(_onSelectRole);
    on<SelectAllRoles>(_onSelectAllRoles);
    on<ClearSelection>(_onClearSelection);
  }

  Future<void> _onLoadRoles(LoadRoles event, Emitter<RoleState> emit) async {
    emit(RoleState(status: RoleStatus.loading));
    try {
      final roleList = await repository.loadRoles(event.companyId);

      emit(
        RoleState(
          status: RoleStatus.success,
          roles: roleList,
          filteredRoles: roleList,
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(
        RoleState(
          status: RoleStatus.failure,
          message: 'Failed to load roles: $e',
        ),
      );
    }
  }

  Future<void> _onCreateRole(CreateRole event, Emitter<RoleState> emit) async {
    try {
      final companyId = authBloc.state.companyId!;
      final createdBy = authBloc.state.userId!.id!;

      final roleId = await repository.insertRole(
        name: event.name,
        description: event.description,
        companyId: companyId,
        createdBy: createdBy,
        privilegeIds: event.privilegeIds,
      );

      developer.log(
        'Creating role for company: $companyId, by user: $createdBy',
      );

      emit(
        RoleState(
          status: RoleStatus.success,
          message: 'Role created successfully: $roleId, {${event.name}}',
        ),
      );

      add(LoadRoles(companyId));
    } catch (e) {
      emit(
        RoleState(
          status: RoleStatus.failure,
          message: 'Failed to create role: $e',
        ),
      );
    }
  }

  Future<void> _onAssignPrivilegesToRole(
    AssignPrivilegesToRole event,
    Emitter<RoleState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId!;

      await repository.assignPrivilegesToRole(
        roleId: event.role.id!,
        privilegeIds: event.privilegeIds,
        companyId: companyId,
        createdBy: authBloc.state.userId!.id!,
      );

      add(LoadRoles(companyId));
    } catch (e) {
      emit(
        RoleState(
          status: RoleStatus.failure,
          message: 'Failed to assign privileges: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateRole(UpdateRole event, Emitter<RoleState> emit) async {
    emit(state.copyWith(status: RoleStatus.updating));
    try {
      final companyId = authBloc.state.companyId!;

      await repository.updateRole(event.role, companyId);

      add(LoadRoles(companyId));
    } catch (e) {
      emit(
        RoleState(
          status: RoleStatus.failure,
          message: 'Failed to update role: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteRole(DeleteRole event, Emitter<RoleState> emit) async {
    emit(state.copyWith(status: RoleStatus.deleting));

    try {
      final companyId = authBloc.state.companyId!;

      final affectedUsers = await repository.deleteRole(event.role, companyId);

      // Remove from state immediately for better UX
      final updatedRoles = state.roles
          .where((r) => r.id != event.role.id)
          .toList();
      final updatedFilteredRoles = state.filteredRoles
          .where((r) => r.id != event.role.id)
          .toList();

      String message = 'Role "${event.role.name}" deleted successfully';
      if (affectedUsers > 0) {
        message +=
            ' and removed from all users ($affectedUsers users affected)';
      }

      emit(
        state.copyWith(
          status: RoleStatus.success,
          roles: updatedRoles,
          filteredRoles: updatedFilteredRoles,
          message: message,
        ),
      );
      add(LoadRoles(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: RoleStatus.failure,
          message: 'Failed to delete role: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleRoles(
    DeleteMultipleRoles event,
    Emitter<RoleState> emit,
  ) async {
    emit(state.copyWith(status: RoleStatus.deleting));

    try {
      final companyId = authBloc.state.companyId!;
      final roleIds = event.roles.map((r) => r.id).toList();

      await repository.deleteMultipleRoles(event.roles, companyId);

      // Update state
      final updatedRoles = state.roles
          .where((r) => !roleIds.contains(r.id))
          .toList();
      final updatedFilteredRoles = state.filteredRoles
          .where((r) => !roleIds.contains(r.id))
          .toList();

      emit(
        state.copyWith(
          status: RoleStatus.success,
          roles: updatedRoles,
          filteredRoles: updatedFilteredRoles,
          message: '${event.roles.length} roles deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RoleStatus.failure,
          message: 'Failed to delete roles: ${e.toString()}',
        ),
      );
    }
  }

  void _onSearchRoles(SearchRoles event, Emitter<RoleState> emit) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredRoles: state.roles,
          searchQuery: '',
          status: RoleStatus.success,
        ),
      );
      return;
    }

    final filtered = state.roles.where((role) {
      return role.name.toLowerCase().contains(query) ||
          role.description.toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredRoles: filtered,
        searchQuery: query,
        status: RoleStatus.searching,
      ),
    );
  }

  void _onSelectRole(SelectRole event, Emitter<RoleState> emit) {
    final selectedRoles = List<Role>.from(state.selectedRoles);
    if (event.isSelected) {
      selectedRoles.add(event.role);
    } else {
      selectedRoles.removeWhere((role) => role.id == event.role.id);
    }
    emit(state.copyWith(selectedRoles: selectedRoles));
  }

  void _onSelectAllRoles(SelectAllRoles event, Emitter<RoleState> emit) {
    if (state.selectedRoles.length == event.roles.length) {
      emit(state.copyWith(selectedRoles: []));
    } else {
      emit(state.copyWith(selectedRoles: List.from(event.roles)));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<RoleState> emit) {
    emit(state.copyWith(selectedRoles: []));
  }
}
