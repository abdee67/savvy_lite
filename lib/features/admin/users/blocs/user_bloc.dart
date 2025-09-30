// features/user/blocs/user_bloc.dart
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:argon2/argon2.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;

  UserBloc({required this.databaseService, required this.authBloc})
    : super(UserState(status: UserStatus.initial)) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<AssignRolesToUser>(_onAssignRolesToUser);
    on<DeleteUser>(_onDeleteUser);
    on<SelectUser>(_onSelectUser);
    on<SelectAllUsers>(_onSelectAllUsers);
    on<DeleteSelectedUsers>(_onDeleteSelectedUsers);
    on<UndoDelete>(_onUndoDelete);
    on<ShowUserDetail>(_onShowUserDetail);
    on<HideUserDetail>(_onHideUserDetail);
    on<ExportUser>(_onExportUser);
    on<ExportSingleUser>(_onExportSingleUser);
    on<SearchUsers>(_onSearchUsers);
    on<ClearSelection>(_onClearSelection);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserState(status: UserStatus.loading));
    try {
      final db = await databaseService.database;
      final users = await db.query('user_table');
      final userList = await Future.wait(
        users.map((u) async => await _getUserWithRoles(u, db)),
      );

      emit(
        UserState(
          status: UserStatus.success,
          user: users.map((u) => UserModel.fromMap(u)).toList(),
          usersRole: userList,
          companyId: event.companyId,
          filteredUsers: users.map((u) => UserModel.fromMap(u)).toList(),
          searchQuery: '',
          selectedUsers: [],
        ),
      );
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to load users: $e',
        ),
      );
    }
  }

  Future<UserWithRole> _getUserWithRoles(
    Map<String, dynamic> userData,
    Database db,
  ) async {
    final user = UserModel.fromMap(userData);

    // Get user roles
    final roleResults = await db.rawQuery(
      '''
      SELECT r.* FROM role_table r
      INNER JOIN user_role ur ON ur.role_table_id = r.id
      WHERE ur.user_id = ?
    ''',
      [user.id],
    );

    final roles = roleResults.map((r) => Role.fromMap(r)).toList();

    return UserWithRole(user: user, roles: roles);
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UserState> emit) async {
    emit(
      state.copyWith(status: UserStatus.creating, message: 'Creating User...'),
    );
    try {
      final db = await databaseService.database;

      final userMap = event.user.toMap();

      // Create user
      final user = await db.insert(
        'user_table',
        userMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Assign roles if any
      if (event.roleIds.isNotEmpty) {
        for (final roleId in event.roleIds) {
          await db.insert('user_role', {
            'user_id': user,
            'role_table_id': roleId,
            'created_by': authBloc.state.userId,
            'date_created': DateTime.now().toIso8601String(),
          });
        }
      }

      add(LoadUsers(authBloc.state.companyId!)); // Reload the list
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to create user: $e',
        ),
      );
    }
  }

  Future<void> _onAssignRolesToUser(
    AssignRolesToUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      final db = await databaseService.database;

      // Remove existing roles
      await db.delete(
        'user_role',
        where: 'user_id = ?',
        whereArgs: [event.userId],
      );

      // Add new roles
      for (final roleId in event.roleIds) {
        await db.insert('user_role', {
          'user_id': event.userId,
          'role_table_id': roleId,
          'created_by': event.createdBy,
          'date_created': DateTime.now().toIso8601String(),
        });
      }

      add(LoadUsers(event.companyId)); // Reload the list
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to assign roles: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    // 1. Check if user has update privilege
    if (!authBloc.state.hasPrivilege('/admin/user-management/edit-user')) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Insufficient privileges to update users',
        ),
      );
      return;
    }

    emit(UserState(status: UserStatus.updating));

    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // 2. Verify user exists and belongs to current company
      final existingUsers = await db.query(
        'user_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.user.id, companyId],
      );

      if (existingUsers.isEmpty) {
        emit(
          UserState(
            status: UserStatus.failure,
            message: 'User not found or access denied',
          ),
        );
        return;
      }

      // 3. Update user in database
      final updateResult = await db.update(
        'user_table',
        event.user.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [event.user.id, companyId],
      );

      if (updateResult == 0) {
        throw Exception('Failed to update user - no rows affected');
      }

      // 4. Update user roles
      // First remove existing roles
      await db.delete(
        'user_role',
        where: 'user_id = ?',
        whereArgs: [event.user.id],
      );

      // Then add new roles
      for (final role in event.roles) {
        await db.insert('user_role', {
          'user_id': event.user.id,
          'role_table_id': role.id,
          'created_by': authBloc.state.userId, // Current admin user
          'date_created': DateTime.now().toIso8601String(),
        });
      }

      // 5. Reload users to get fresh data
      add(LoadUsers(companyId!));

      emit(
        UserState(
          status: UserStatus.success,
          message: 'User updated successfully',
        ),
      );
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to update user: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    // 1. Check if user has delete privilege
    if (!authBloc.state.hasPrivilege('/admin/user-management/delete-user')) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Insufficient privileges to delete users',
        ),
      );
      return;
    }

    // 2. Prevent self-deletion
    if (event.userId == authBloc.state.userId) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Cannot delete your own account',
        ),
      );
      return;
    }

    emit(UserState(status: UserStatus.deleting));

    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // 3. Verify user exists and belongs to current company
      final existingUsers = await db.query(
        'user_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.userId, companyId],
      );

      if (existingUsers.isEmpty) {
        emit(
          UserState(
            status: UserStatus.failure,
            message: 'User not found or access denied',
          ),
        );
        return;
      }

      // 4. Store user data for potential undo (optional)
      final userToDelete = UserModel.fromMap(existingUsers.first);

      // 5. Delete user roles first (foreign key constraint)
      final rolesDeleted = await db.delete(
        'user_role',
        where: 'user_id = ?',
        whereArgs: [event.userId],
      );

      // 6. Delete user
      final userDeleted = await db.delete(
        'user_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.userId, companyId],
      );

      if (userDeleted == 0) {
        throw Exception('Failed to delete user - no rows affected');
      }

      // 7. Reload users list
      add(LoadUsers(companyId!));

      emit(
        UserState(
          status: UserStatus.success,
          message: 'User deleted successfully',
          // Optional: Store for undo functionality
          recentlyDeleted: [...state.recentlyDeleted, userToDelete],
        ),
      );
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to delete user: ${e.toString()}',
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<UserState> emit) {
    emit(state.copyWith(selectedUsers: []));
  }

  void _onSearchUsers(SearchUsers event, Emitter<UserState> emit) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredUsers: state.user,
          selectedUsers: [],
          searchQuery: '',
          status: UserStatus.success,
        ),
      );
      return;
    }

    final filtered = state.user.where((user) {
      return user.userName!.toLowerCase().contains(query) ||
          user.userEmail!.toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredUsers: filtered,
        searchQuery: query,
        selectedUsers: [],
        status: UserStatus.searching,
      ),
    );
  }

  void _onSelectUser(SelectUser event, Emitter<UserState> emit) {
    final selectedUsers = List<UserModel>.from(state.selectedUsers);
    if (event.isSelected) {
      selectedUsers.add(event.user);
    } else {
      selectedUsers.removeWhere((user) => user.id == event.user.id);
    }
    emit(state.copyWith(selectedUsers: selectedUsers));
  }

  void _onSelectAllUsers(SelectAllUsers event, Emitter<UserState> emit) {
    if (state.selectedUsers.length == event.users.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedUsers: []));
    } else {
      // Select all
      emit(state.copyWith(selectedUsers: List.from(event.users)));
    }
  }

  void _onDeleteSelectedUsers(
    DeleteSelectedUsers event,
    Emitter<UserState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final placeholders = List.filled(
        event.selectedUsers.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedUsers, authBloc.state.companyId];
      await db.delete(
        'Users',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
      final updatedUsers = state.user
          .where((e) => !event.selectedUsers.contains(e.id))
          .toList();
      final updatedUsersRole = state.usersRole
          .where((e) => !event.selectedUsers.contains(e.user.id))
          .toList();
      final updatedFiltered = state.filteredUsers
          .where((e) => !event.selectedUsers.contains(e.id))
          .toList();

      emit(
        state.copyWith(
          user: updatedUsers,
          usersRole: updatedUsersRole,
          filteredUsers: updatedFiltered,
          selectedUsers: [],
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedUsers],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
          message: '${event.selectedUsers.length} Users deleted successfully',
        ),
      );
      add(LoadUsers(authBloc.state.companyId!));
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to delete selected Users: $e',
        ),
      );
    }
  }

  Future<void> _onUndoDelete(UndoDelete event, Emitter<UserState> emit) async {
    try {
      final db = await databaseService.database;

      // Reinsert at original positions in memory
      final updatedUsers = List<UserModel>.from(state.user);
      final updatedUsersRole = List<UserWithRole>.from(state.usersRole);

      // Restore items at their original positions
      for (int i = 0; i < event.deletedItems.length; i++) {
        final item = event.deletedItems[i];
        final index = event.deletedIndexes[i];

        if (index >= 0 && index <= updatedUsers.length) {
          updatedUsers.insert(index, item);
        } else {
          updatedUsers.add(item); // fallback if index is invalid
        }

        // Also restore to DB
        await db.insert(
          'user_table',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        emit(
          state.copyWith(
            user: updatedUsers,
            usersRole: updatedUsersRole,
            filteredUsers: updatedUsers,
            recentlyDeleted: [],
            recentlyDeletedIndexes: [],
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          message: 'Failed to undo delete: $e',
        ),
      );
    }
  }

  void _onShowUserDetail(ShowUserDetail event, Emitter<UserState> emit) {
    emit(
      state.copyWith(
        userDetail: event.user,
        detailStatus: UserDetailStatus.showing,
      ),
    );
  }

  void _onHideUserDetail(HideUserDetail event, Emitter<UserState> emit) {
    emit(
      state.copyWith(detailStatus: UserDetailStatus.hidden, userDetail: null),
    );
  }

  void _onExportUser(ExportUser event, Emitter<UserState> emit) {
    emit(state.copyWith(status: UserStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: UserStatus.success,
          isExporting: false,
          exportedUsers: event.usersToExport,
          message: 'Exported ${event.usersToExport.length} Users successfully',
        ),
      );
    });
  }

  void _onExportSingleUser(ExportSingleUser event, Emitter<UserState> emit) {
    emit(state.copyWith(status: UserStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: UserStatus.success,
          isExporting: false,
          exportedUser: event.userToExport,
          message: 'Exported ${event.userToExport} Users successfully',
        ),
      );
    });
  }
}
