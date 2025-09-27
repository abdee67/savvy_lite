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
    on<AssignPrivilegesToRole>(_onAssignPrivilegesToRole);
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

      emit(RoleState(status: RoleStatus.success, roles: roleList));
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
      final roleId = await db.insert('role_table', {
        'name': event.name,
        'description': event.description,
        'company': authBloc.state.companyId,
        'created_by': authBloc.state.userId,
        'date_created': DateTime.now().toIso8601String(),
      });
      developer.log(
        'Creating role for company: ${authBloc.state.companyId}, by user: ${authBloc.state.userId}',
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
          await db.insert('role_privilege', {
            'role_table_id': roleId,
            'privilege_table_id': privilegeId,
            'created_by': authBloc.state.userId,
            'date_created': DateTime.now().toIso8601String(),
          });
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
        await db.insert('role_privilege', {
          'role_table_id': event.role.id,
          'privilege_table_id': privilege,
          'company': authBloc.state.companyId,
          'created_by': authBloc.state.userId,
          'date_created': DateTime.now().toIso8601String(),
        });
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

  // ... similar implementations for update and delete
  Future<void> _onUpdateRole(UpdateRole event, Emitter<RoleState> emit) async {
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
    try {
      final db = await databaseService.database;
      await db.delete(
        'role_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.role.id, authBloc.state.companyId],
      );
      add(LoadRoles(authBloc.state.companyId!)); // Reload the list
    } catch (e) {
      emit(
        RoleState(
          status: RoleStatus.failure,
          message: 'Failed to delete role: $e',
        ),
      );
    }
  }
}
