import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/core/models/company.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

/// Event to check if user is already authenticated (on app start)
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {
  final BuildContext? context;
  const LogoutRequested(this.context);

  @override
  List<Object?> get props => [context];
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String password;
  final int companyId;

  const RegisterRequested({
    required this.username,
    required this.password,
    required this.companyId,
  });

  @override
  List<Object?> get props => [username, password, companyId];
}

class ForgotPasswordRequested extends AuthEvent {
  final String username;

  const ForgotPasswordRequested({required this.username});

  @override
  List<Object?> get props => [username];
}

/// Event when authentication fails and we need to clear data
class AuthFailureEvent extends AuthEvent {
  final String errorMessage;

  const AuthFailureEvent(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

/// Event when company context changes
class CompanyContextChanged extends AuthEvent {
  final int companyId;

  const CompanyContextChanged(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();

  @override
  List<Object?> get props => [];
}

class CompanySelectionRequired extends AuthEvent {
  final List<Company> availableCompanies;
  final String username;

  const CompanySelectionRequired({
    required this.availableCompanies,
    required this.username,
  });

  @override
  List<Object?> get props => [availableCompanies, username];
}
