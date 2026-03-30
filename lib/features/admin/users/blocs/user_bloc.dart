// features/user/blocs/user_bloc.dart

import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/repo/user_repo.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/licensing/services/license_service.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;
  final AuthBloc authBloc;
  final LicenseService licenseService;
  StreamSubscription? _authSubscription;

  UserBloc({
    required this.repository,
    required this.authBloc,
    required this.licenseService,
  }) : super(UserState(status: UserStatus.initial)) {
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

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserState(status: UserStatus.loading));
    try {
      final usersWithRole = await repository.loadUsersWithRoles();

      emit(
        UserState(
          status: UserStatus.success,
          usersWithRole: usersWithRole,
          filteredUsersWithRole: usersWithRole,
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

  Future<void> _onCreateUser(CreateUser event, Emitter<UserState> emit) async {
    emit(
      state.copyWith(status: UserStatus.creating, message: 'Creating User...'),
    );
    try {
      final companyId = authBloc.state.companyId;
      final createdBy = authBloc.state.userId!.id;

      // Check if username is already taken
      final isTaken = await repository.isUsernameTaken(event.user.userName!);
      if (isTaken) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'User name already exists',
          ),
        );
        return;
      }

      // License Logic: Check User Limit
      final licenseResult = await licenseService.loadAndValidateLicense();
      if (!licenseResult.isValid) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: licenseResult.errorMessage ?? 'License Invalid',
          ),
        );
        return;
      }

      final userLimit = licenseResult.payload?.userLimit ?? 0;
      final currentUsersCount = await repository.getUserCount();

      if (currentUsersCount >= userLimit) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message:
                'User creation limit reached ($userLimit users max). Please upgrade your license.',
          ),
        );
        return;
      }

      await repository.insertUser(
        event.user,
        companyId!,
        createdBy!,
        roles: event.roles,
      );

      add(LoadUsers(companyId));

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
          message: 'Failed to create user',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to create user: $e');
      }
    }
  }

  Future<void> _onAssignRolesToUser(
    AssignRolesToUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.assignRolesToUser(
        event.userId,
        event.roles,
        event.createdBy,
      );

      add(LoadUsers(event.companyId));

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
      final companyId = authBloc.state.companyId!;
      final updatedBy = authBloc.state.userId!.id;

      // Verify user exists and belongs to current company
      final existingUser = await repository.findUser(event.user.id!, companyId);
      if (existingUser == null) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'User not found or access denied',
          ),
        );
        return;
      }

      await repository.updateUser(
        event.user,
        companyId,
        updatedBy,
        newPassword: event.newPassword,
        roles: event.roles,
      );

      add(LoadUsers(companyId));

      emit(
        state.copyWith(
          status: UserStatus.success,
          message:
              'User updated successfully${event.newPassword != null && event.newPassword!.isNotEmpty ? ' with new password' : ''}',
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
    final currentUserId = authBloc.state.userId?.id;
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
    if (event.userId == currentUserId) {
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
      // 3. Verify user exists and belongs to current company
      final existingUser = await repository.findUser(event.userId, companyId);
      if (existingUser == null) {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'User not found or access denied',
          ),
        );
        return;
      }

      // 4. Prevent deleting super admin or essential accounts
      if (existingUser.userName == 'admin') {
        emit(
          state.copyWith(
            status: UserStatus.failure,
            message: 'Cannot delete system administrator accounts',
          ),
        );
        return;
      }

      // 5. Delete user (roles are cleaned up inside the repo)
      await repository.deleteUser(event.userId, companyId);

      // 6. Reload users list
      add(LoadUsers(companyId));

      emit(
        state.copyWith(
          status: UserStatus.success,
          message: 'User "${existingUser.userName}" deleted successfully',
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
      emit(state.copyWith(selectedUsers: []));
    } else {
      emit(state.copyWith(selectedUsers: List.from(event.users)));
    }
  }

  void _onDeleteSelectedUsers(
    DeleteSelectedUsers event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.deleteMultipleUsers(
        event.selectedUsers,
        authBloc.state.companyId!,
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
      await repository.batchInsertUsers(event.deletedItems);

      // Reload from DB to get consistent state
      add(LoadUsers(authBloc.state.companyId!));

      emit(
        state.copyWith(
          recentlyDeleted: [],
          recentlyDeletedIndexes: [],
          message:
              '${event.deletedItems.length} users restored successfully',
        ),
      );
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
