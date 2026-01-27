import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/constants/privilege_heirarchy.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';

class PrivilegeRouteGuard extends StatelessWidget {
  final Widget child;
  final String requiredPrivilege;
  final String? parentPrivilege;

  const PrivilegeRouteGuard({
    required this.child,
    required this.requiredPrivilege,
    this.parentPrivilege,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.loading:
            return _buildLoadingScreen('Checking authentication...');

          case AuthStatus.unauthenticated:
            return _buildLoadingScreen('Redirecting to login...');

          case AuthStatus.authenticated:
            final accessResult = _checkAccess(state);

            if (accessResult.hasAccess) {
              return child;
            } else {
              return _buildUnauthorizedScreen(context, accessResult);
            }

          case AuthStatus.failure:
            return _buildErrorScreen(context, state.message);

          default:
            return _buildErrorScreen(context, 'something went wrong');
        }
      },
    );
  }

  AccessCheckResult _checkAccess(AuthState state) {
    final missingPrivileges = <String>[];

    // Use explicit parent if provided, otherwise use hierarchy config
    final effectiveParent =
        parentPrivilege ??
        PrivilegeHierarchy.getParentPrivilege(requiredPrivilege);

    // Get complete hierarchy required for access
    final requiredHierarchy = effectiveParent != null
        ? PrivilegeHierarchy.getRequiredPrivilegeHierarchy(requiredPrivilege)
        : [requiredPrivilege];

    // Check each privilege in the hierarchy
    for (final privilege in requiredHierarchy) {
      if (!state.hasPrivilege(privilege)) {
        missingPrivileges.add(privilege);
      }
    }

    return AccessCheckResult(
      hasAccess: missingPrivileges.isEmpty,
      missingPrivileges: missingPrivileges,
      requiredPrivilege: requiredPrivilege,
      parentPrivilege: effectiveParent,
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthorizedScreen(
    BuildContext context,
    AccessCheckResult result,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.orange[700],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You do not have permission to access this page.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (result.missingPrivileges.isNotEmpty)
                  Text(
                    'Missing: ${result.missingPrivileges.join(', ')}',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/homePage'),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String? errorMessage) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Authentication Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(errorMessage, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Return to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class AccessCheckResult {
  final bool hasAccess;
  final List<String> missingPrivileges;
  final String requiredPrivilege;
  final String? parentPrivilege;

  AccessCheckResult({
    required this.hasAccess,
    required this.missingPrivileges,
    required this.requiredPrivilege,
    required this.parentPrivilege,
  });
}
