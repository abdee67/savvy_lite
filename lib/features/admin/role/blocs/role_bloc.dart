// features/role/blocs/role_bloc.dart
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;

  RoleBloc({required this.databaseService, required this.authBloc})
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
      final db = await databaseService.database;
      final roles = await db.query(
        'role_table',
        where: 'company = ?',
        whereArgs: [event.companyId],
      );

      final roleList = await Future.wait(
        roles.map((r) async => Role.withPrivileges(r, db)),
      );

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
      final db = await databaseService.database;
      final roleId = await db.insert('role_table', ({
        'name': event.name,
        'description': event.description,
        'company': authBloc.state.companyId,
        'created_by': authBloc.state.userId?.id,
        'date_created': DateTime.now().toIso8601String(),
      }));
      developer.log(
        'Creating role for company: ${authBloc.state.companyId}, by user: ${authBloc.state.userId?.id}',
      );
      emit(
        RoleState(
          status: RoleStatus.success,
          message: 'Role created successfully: $roleId, {$event.name}',
        ),
      );
      // Assign privileges if any
      if (event.privilegeIds.isNotEmpty) {
        for (final privilegeId in event.privilegeIds) {
          await db.insert('role_privilege', ({
            'role_table_id': roleId,
            'privilege_table_id': privilegeId,
            'created_by': authBloc.state.userId?.id,
            'date_created': DateTime.now().toIso8601String(),
          }));
        }
      }

      add(LoadRoles(authBloc.state.companyId!)); // Reload the list
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
      final db = await databaseService.database;

      // Remove existing privileges
      await db.delete(
        'role_privilege',
        where: 'role_table_id = ? AND company = ?',
        whereArgs: [event.role.id, authBloc.state.companyId],
      );

      // Add new privileges
      for (final privilege in event.privilegeIds) {
        await db.insert('role_privilege', ({
          'role_table_id': event.role.id,
          'privilege_table_id': privilege,
          'company': authBloc.state.companyId,
          'created_by': authBloc.state.userId?.id,
          'date_created': DateTime.now().toIso8601String(),
        }));
      }

      add(LoadRoles(authBloc.state.companyId!)); // Reload the list
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
      final db = await databaseService.database;
      await db.update(
        'role_table',
        event.role.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [event.role.id, authBloc.state.companyId],
      );
      add(LoadRoles(authBloc.state.companyId!)); // Reload the list
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
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      int affectedUsers = 0;

      // Use transaction for atomic operations
      await db.transaction((txn) async {
        // Get count of users who have this role (for informational message)
        final userCountResult = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM user_role WHERE role_table_id = ?',
          [event.role.id],
        );
        affectedUsers = userCountResult.first['count'] as int;

        // 1. First delete from user_role table (remove role from all users)
        await txn.delete(
          'user_role',
          where: 'role_table_id = ?',
          whereArgs: [event.role.id],
        );

        // 2. Then delete from role_privilege table (remove privileges from role)
        await txn.delete(
          'role_privilege',
          where: 'role_table_id = ? AND company = ?',
          whereArgs: [event.role.id, companyId],
        );

        // 3. Finally delete from role_table (delete the role itself)
        final result = await txn.delete(
          'role_table',
          where: 'id = ? AND company = ?',
          whereArgs: [event.role.id, companyId],
        );

        if (result == 0) {
          throw Exception('Role not found or already deleted');
        }
      });

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
      add(LoadRoles(authBloc.state.companyId!)); // Reload the list
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
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      final roleIds = event.roles.map((r) => r.id).toList();
      int affectedUsers = 0;

      await db.transaction((txn) async {
        // 1. Delete from user_role table for all selected roles
        final userRolePlaceholders = List.filled(roleIds.length, '?').join(',');
        await txn.delete(
          'user_role',
          where: 'role_table_id IN ($userRolePlaceholders)',
          whereArgs: roleIds,
        );

        // 2. Delete from role_privilege table
        await txn.delete(
          'role_privilege',
          where: 'role_table_id IN ($userRolePlaceholders)',
          whereArgs: roleIds,
        );

        // 3. Delete from role_table
        await txn.delete(
          'role_table',
          where: 'id IN ($userRolePlaceholders) AND company = ?',
          whereArgs: [...roleIds, companyId],
        );
      });

      // Update state
      final updatedRoles = state.roles
          .where((r) => !roleIds.contains(r.id))
          .toList();
      final updatedFilteredRoles = state.filteredRoles
          .where((r) => !roleIds.contains(r.id))
          .toList();

      String message = '${event.roles.length} roles deleted successfully';
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
      // If all are selected, clear selection
      emit(state.copyWith(selectedRoles: []));
    } else {
      // Select all
      emit(state.copyWith(selectedRoles: List.from(event.roles)));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<RoleState> emit) {
    emit(state.copyWith(selectedRoles: []));
  }
}
