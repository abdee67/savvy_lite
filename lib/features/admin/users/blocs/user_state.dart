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

  final List<UserWithRole> usersRole;
  final List<UserModel> user;

  final UserErrorType? errorType;
  final DateTime? occuredAt;
  final int? employeeId;
  final int? companyId;
  final List<UserModel> filteredUsers;
  final String searchQuery;
  final List<UserModel> selectedUsers;

  final UserDetailStatus detailStatus;
  final UserModel? userDetail;

  final List<UserModel> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final List<UserModel> exportedUsers; //export multiple employees
  final UserModel? exportedUser; //export single employee

  // Role management state
  final bool isRoleManagementMode;
  final int? employeeInRoleManagement;

  const UserState({
    required this.status,
    this.message,
    this.usersRole = const [],
    this.user = const [],
    this.errorType,
    this.occuredAt,
    this.employeeId,
    this.companyId,
    this.filteredUsers = const [],
    this.searchQuery = '',
    this.selectedUsers = const [],
    this.detailStatus = UserDetailStatus.hidden,
    this.userDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.exportedUsers = const [],
    this.exportedUser,
    this.isRoleManagementMode = false,
    this.employeeInRoleManagement,
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

  bool get hasUsers => usersRole.isNotEmpty;

  bool get hasFilteredUsers => filteredUsers.isNotEmpty;

  bool get hasSelection => selectedUsers.isNotEmpty;

  bool get canEdit => selectedUsers.length == 1;

  bool get canDelete => selectedUsers.isNotEmpty;

  bool get canExport => filteredUsers.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  bool hasUser(String userName) {
    return usersRole.any((u) => u.user.userName == userName);
  }

  bool hasAnyUser(List<String> userNames) {
    return usersRole.any((u) => userNames.contains(u.user.userName));
  }

  // --- CopyWith for immutability ---
  UserState copyWith({
    UserStatus? status,
    String? message,
    List<UserWithRole>? usersRole,
    UserErrorType? errorType,
    DateTime? occuredAt,
    int? employeeId,
    int? companyId,
    List<UserModel>? filteredUsers,
    String? searchQuery,
    List<UserModel>? selectedUsers,
    UserDetailStatus? detailStatus,
    UserModel? userDetail,
    List<UserModel>? user,
    List<UserModel>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    int? currentPage,
    bool? isExporting,
    List<UserModel>? exportedUsers,
    UserModel? exportedUser,
    bool? isRoleManagementMode,
    String? roleSearchQuery,
    int? employeeInRoleManagement,
  }) {
    return UserState(
      status: status ?? this.status,
      message: message ?? this.message,
      usersRole: usersRole ?? this.usersRole,
      user: user ?? this.user,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      filteredUsers: filteredUsers ?? this.filteredUsers,
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
      isRoleManagementMode: isRoleManagementMode ?? this.isRoleManagementMode,
      employeeInRoleManagement:
          employeeInRoleManagement ?? this.employeeInRoleManagement,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    usersRole,
    user,
    errorType,
    occuredAt,
    employeeId,
    companyId,
    filteredUsers,
    searchQuery,
    selectedUsers,
    detailStatus,
    userDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    isExporting,
    exportedUsers,
    exportedUser,
    isRoleManagementMode,
    employeeInRoleManagement,
  ];
}

// Optional enum for error types
enum UserErrorType { networkError, serverError, unknown }
