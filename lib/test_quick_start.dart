import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/services/auth/auth_service.dart';

void testQuickStart() {
  final authService = getIt<AuthService>();

  print('=== QUICK START TEST ===');
  print('User: ${authService.currentUser?.userName}');
  print('User ID: ${authService.currentUser?.id}');
  print('Company: ${authService.currentCompany?.companyName}');
  print('Company ID: ${authService.currentCompany?.id}');
  print('Authenticated: ${authService.isAuthenticated}');
  print('========================');

  // Now you can directly access any screen without login
}
