import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final UserStatus status;
  final String? message;

  final List<UserWithRole> users;

  final UserErrorType? errorType;
  final DateTime? occuredAt;

  const UserState({
    required this.status,
    this.message,
    this.users = const [],
    this.errorType,
    this.occuredAt,
  });

  // --- Helper Getters ---

  bool get isLoading => status == UserStatus.loading;

  bool get isSuccess => status == UserStatus.success;

  bool get isFailure => status == UserStatus.failure;

  bool hasUser(String userName) {
    return users.any((u) => u.user.userName == userName);
  }

  bool hasAnyUser(List<String> userNames) {
    return users.any((u) => userNames.contains(u.user.userName));
  }

  // --- CopyWith for immutability ---
  UserState copyWith({
    UserStatus? status,
    String? message,
    List<UserWithRole>? users,
    UserErrorType? errorType,
    DateTime? occuredAt,
  }) {
    return UserState(
      status: status ?? this.status,
      message: message ?? this.message,
      users: users ?? this.users,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
    );
  }

  @override
  List<Object?> get props => [status, message, users, errorType, occuredAt];
}

// Optional enum for error types
enum UserErrorType { networkError, serverError, unknown }
