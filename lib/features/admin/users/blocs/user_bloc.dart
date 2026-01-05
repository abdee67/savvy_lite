// features/user/blocs/user_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:sqflite/sqflite.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

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

    _authSubscription = authBloc.stream.listen((state) {
      if (state.companyId != null) {
        add(LoadUsers(state.companyId!));
      }
    });
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserState(status: UserStatus.loading));
    try {
      final db = await databaseService.database;
      final users = await db.query('user_table');

      final usersWithRole = await Future.wait(
        users.map((u) async => await _getUserWithRoles(u, db)),
      );

      emit(
        UserState(
          status: UserStatus.success,
          usersWithRole: usersWithRole,
          filteredUsersWithRole: usersWithRole, // Initially, filtered = all
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
      final companyId = authBloc.state.companyId;
      final createdBy = authBloc.state.userId!.id;
      final password = await UserModel.generateArgon2Hash(event.user.password!);

      final userMap = event.user
          .copyWith(
            company: companyId,
            createdBy: createdBy,
            dateCreated: DateTime.now(),
            password: password,
          )
          .toMap();
      userMap.remove('id');

      // Create user
      final userId = await db.insert('user_table', userMap);

      // Assign roles if any
      if (event.roles.isNotEmpty) {
        for (final role in event.roles) {
          await db.insert('user_role', {
            'user_id': userId,
            'role_table_id': role.id,
            'created_by': createdBy,
            'date_created': DateTime.now().toIso8601String(),
          });
        }
      }
      add(LoadUsers(authBloc.state.companyId!)); // Reload the list

      emit(
        state.copyWith(
          status: UserStatus.success,
          message: 'User created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
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
      for (final roleId in event.roles) {
        await db.insert('user_role', {
          'user_id': event.userId,
          'role_table_id': roleId.id,
          'created_by': event.createdBy,
          'date_created': DateTime.now().toIso8601String(),
        });
      }
      add(LoadUsers(event.companyId)); // Reload the list
      emit(
        state.copyWith(
          status: UserStatus.success,
          message: 'Roles assigned successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          message: 'Failed to assign roles: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    // 1. Check if user has update privilege
    if (!authBloc.state.hasPrivilege(AppRoutes.userEdit)) {
      emit(
        state.copyWith(
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
      final updatedBy = authBloc.state.userId!.id;
      // Check if password is being updated (new password provided)
      String? finalPassword;
      if (event.newPassword != null && event.newPassword!.isNotEmpty) {
        // Hash the new password
        finalPassword = await UserModel.generateArgon2Hash(event.newPassword);
      }
      // Prepare updated user data
      UserModel updatedUser = event.user.copyWith(
        updatedBy: updatedBy,
        dateUpdated: DateTime.now(),
      );
      if (finalPassword != null) {
        updatedUser = updatedUser.copyWith(
          password: finalPassword,
          passwordLastUpdated: DateTime.now(),
        );
      }

      // 2. Verify user exists and belongs to current company
      final existingUsers = await db.query(
        'user_table',
        where: 'id = ? AND company = ?',
        whereArgs: [updatedUser.id, companyId],
      );

      if (existingUsers.isEmpty) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'User not found or access denied',
          ),
        );
        return;
      }
      // 3. Update user in database - only update password if it was changed
      final userMap = updatedUser.toMap();
      if (finalPassword == null || finalPassword.isEmpty) {
        // Don't update password if it wasn't changed
        userMap.remove('password');
        userMap.remove('password_last_updated');
      }

      // 3. Update user in database
      final updateResult = await db.update(
        'user_table',
        userMap,
        where: 'id = ? AND company = ?',
        whereArgs: [updatedUser.id, companyId],
      );

      if (updateResult == 0) {
        throw Exception('Failed to update user - no rows affected');
      }

      // 4. Update user roles if provided
      if (event.roles.isNotEmpty) {
        // First remove existing roles
        await db.delete(
          'user_role',
          where: 'user_id = ?',
          whereArgs: [updatedUser.id],
        );

        // Then add new roles
        for (final role in event.roles) {
          await db.insert('user_role', {
            'user_id': updatedUser.id,
            'role_table_id': role.id,
            'created_by': updatedBy,
            'date_created': DateTime.now().toIso8601String(),
          });
        }
      }
      // 5. Reload users to get fresh data
      add(LoadUsers(companyId!));

      emit(
        state.copyWith(
          status: UserStatus.success,
          message:
              'User updated successfully${finalPassword != null ? ' with new password' : ''}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          message: 'Failed to update user: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    // Add null checks for critical authentication values
    final currentUserId = authBloc.state.userId;
    final companyId = authBloc.state.companyId;

    if (currentUserId == null || companyId == null) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          message: 'Authentication error: User not properly authenticated',
        ),
      );
      return;
    }

    // 1. Check if user has delete privilege
    if (!authBloc.state.hasPrivilege(AppRoutes.userDelete)) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          message: 'Insufficient privileges to delete users',
        ),
      );
      return;
    }

    // 2. Prevent self-deletion
    if (event.userId == currentUserId.id) {
      final currentUser = authBloc.state.username;
      emit(
        state.copyWith(
          status: UserStatus.failure,
          message: 'Cannot delete your own account $currentUser',
        ),
      );
      return;
    }

    emit(UserState(status: UserStatus.deleting));

    try {
      final db = await databaseService.database;

      // 4. Verify user exists and belongs to current company
      final existingUsers = await db.query(
        'user_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.userId, companyId],
      );

      if (existingUsers.isEmpty) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'User not found or access denied',
          ),
        );
        return;
      }

      // 5. Store user data for potential undo (optional)
      final userToDelete = UserModel.fromMap(existingUsers.first);

      // 6. Prevent deleting super admin or essential accounts
      if (userToDelete.userName == 'admin') {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'Cannot delete system administrator accounts',
          ),
        );
        return;
      }

      // 7. Delete user roles first (foreign key constraint)
      await db.delete(
        'user_role',
        where: 'user_id = ?',
        whereArgs: [event.userId],
      );

      // 8. Delete user
      final userDeleted = await db.delete(
        'user_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.userId, companyId],
      );

      if (userDeleted == 0) {
        throw Exception('Failed to delete user - no rows affected');
      }

      // 9. Reload users list
      add(LoadUsers(companyId));

      emit(
        state.copyWith(
          status: UserStatus.success,
          message: 'User "${userToDelete.userName}" deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
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
          filteredUsersWithRole: state.usersWithRole,
          selectedUsers: [],
          searchQuery: '',
          status: UserStatus.success,
        ),
      );
      return;
    }

    final filtered = state.usersWithRole.where((user) {
      return user.user.userName!.toLowerCase().contains(query) ||
          user.user.userEmail!.toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredUsersWithRole: filtered,
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
        'user_table',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
      emit(
        state.copyWith(
          status: UserStatus.success,
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
      final updatedUsers = List<UserModel>.from(state.users);
      final updatedUsersRole = List<UserWithRole>.from(state.usersWithRole);

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
            usersWithRole: updatedUsersRole,
            filteredUsersWithRole: updatedUsersRole,
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
