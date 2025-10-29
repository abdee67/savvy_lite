import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';

enum UserStatus {
  initial,
  loading,
  searching,
  success,
  failure,
  creating,
  updating,
  deleting,
  exporting,
}

enum UserDetailStatus { hidden, showing, editing }

class UserState extends Equatable {
  final UserStatus status;
  final String? message;

  // SINGLE SOURCE OF TRUTH: Only maintain usersWithRole
  final List<UserWithRole> usersWithRole;

  // Derived state - computed from usersWithRole
  List<UserModel> get users => usersWithRole.map((u) => u.user).toList();

  // Filtered state
  final List<UserWithRole> filteredUsersWithRole;
  List<UserModel> get filteredUsers =>
      filteredUsersWithRole.map((u) => u.user).toList();

  final String searchQuery;
  final List<UserModel> selectedUsers;

  final UserDetailStatus detailStatus;
  final UserModel? userDetail;

  final List<UserWithRole> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final List<UserModel> exportedUsers;
  final UserModel? exportedUser;

  const UserState({
    required this.status,
    this.message,
    this.usersWithRole = const [],
    this.filteredUsersWithRole = const [],
    this.searchQuery = '',
    this.selectedUsers = const [],
    this.detailStatus = UserDetailStatus.hidden,
    this.userDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.exportedUsers = const [],
    this.exportedUser,
  });

  // --- Helper Getters ---

  bool get isLoading => status == UserStatus.loading;
  bool get isSuccess => status == UserStatus.success;
  bool get isFailure => status == UserStatus.failure;
  bool get isCreating => status == UserStatus.creating;
  bool get isUpdating => status == UserStatus.updating;
  bool get isDeleting => status == UserStatus.deleting;
  bool get isExportingData => status == UserStatus.exporting;
  bool get isDetailVisible => detailStatus != UserDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == UserDetailStatus.editing;

  bool get hasUsers => usersWithRole.isNotEmpty;
  bool get hasFilteredUsers => filteredUsersWithRole.isNotEmpty;
  bool get hasSelection => selectedUsers.isNotEmpty;
  bool get canEdit => selectedUsers.length == 1;
  bool get canDelete => selectedUsers.isNotEmpty;
  bool get canExport => filteredUsersWithRole.isNotEmpty;
  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  // Safe user lookup methods
  UserWithRole? getUserWithRole(int userId) {
    try {
      return usersWithRole.firstWhere((u) => u.user.id == userId);
    } catch (e) {
      return null;
    }
  }

  UserWithRole? getFilteredUserWithRole(int userId) {
    try {
      return filteredUsersWithRole.firstWhere((u) => u.user.id == userId);
    } catch (e) {
      return null;
    }
  }

  bool hasUser(String userName) {
    return usersWithRole.any((u) => u.user.userName == userName);
  }

  bool hasAnyUser(List<String> userNames) {
    return usersWithRole.any((u) => userNames.contains(u.user.userName));
  }

  // --- CopyWith for immutability ---
  UserState copyWith({
    UserStatus? status,
    String? message,
    List<UserWithRole>? usersWithRole,
    List<UserWithRole>? filteredUsersWithRole,
    String? searchQuery,
    List<UserModel>? selectedUsers,
    UserDetailStatus? detailStatus,
    UserModel? userDetail,
    List<UserWithRole>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    List<UserModel>? exportedUsers,
    UserModel? exportedUser,
    bool? isRoleManagementMode,
    int? employeeInRoleManagement,
  }) {
    return UserState(
      status: status ?? this.status,
      message: message ?? this.message,
      usersWithRole: usersWithRole ?? this.usersWithRole,
      filteredUsersWithRole:
          filteredUsersWithRole ?? this.filteredUsersWithRole,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUsers: selectedUsers ?? this.selectedUsers,
      detailStatus: detailStatus ?? this.detailStatus,
      userDetail: userDetail ?? this.userDetail,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      isExporting: isExporting ?? this.isExporting,
      exportedUsers: exportedUsers ?? this.exportedUsers,
      exportedUser: exportedUser ?? this.exportedUser,
    );
  }

  // Initial state factory
  factory UserState.initial() {
    return const UserState(
      status: UserStatus.initial,
      usersWithRole: [],
      filteredUsersWithRole: [],
      searchQuery: '',
      selectedUsers: [],
      detailStatus: UserDetailStatus.hidden,
      recentlyDeleted: [],
      recentlyDeletedIndexes: [],
      isExporting: false,
      exportedUsers: [],
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    usersWithRole,
    filteredUsersWithRole,
    searchQuery,
    selectedUsers,
    detailStatus,
    userDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    isExporting,
    exportedUsers,
    exportedUser,
  ];
}

// Error types
enum UserErrorType { networkError, serverError, unknown }
