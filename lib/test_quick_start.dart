import 'dart:developer' as developer;

import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';

void testQuickStart() {
  final authBloc = getIt<AuthBloc>();

  developer.log('=== QUICK START TEST ===');
  developer.log('User: ${authBloc.currentUser?.userName}');
  developer.log('User ID: ${authBloc.currentUser?.id}');
  developer.log('Company: ${authBloc.currentCompany?.companyName}');
  developer.log('Company ID: ${authBloc.currentCompany?.id}');
  developer.log(
    'Authenticated: ${authBloc.state.status == AuthStatus.authenticated}',
  );
  developer.log('========================');

  // Now you can directly access any screen without login
}
