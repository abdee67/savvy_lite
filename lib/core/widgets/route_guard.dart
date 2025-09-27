// core/widgets/route_guard.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/privilege_constants.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';

// core/widgets/route_guard.dart
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
        if (state.status == AuthStatus.authenticated) {
          final hasAccess = _checkAccess(state);

          if (hasAccess) {
            return child;
          } else {
            return _buildAccessDeniedScreen(
              context,
              requiredPrivilege,
              parentPrivilege,
            );
          }
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  bool _checkAccess(AuthState state) {
    // Check if user has the required privilege
    final hasRequired = state.hasPrivilege(requiredPrivilege);
    if (!hasRequired) return false;

    // If parent privilege is specified, check it
    if (parentPrivilege != null) {
      return state.hasPrivilege(parentPrivilege!);
    }

    // Auto-detect parent dashboard from URI structure
    final privilege = state.privileges.firstWhere(
      (p) => p.uri == requiredPrivilege,
      orElse: () => Privilege(
        id: 0,
        name: '',
        description: '',
        createdBy: 0,
        dateCreated: DateTime.now(),
        type: '',
        uri: '',
        linkLabel: '',
        buttonLabel: '',
        vendorOnly: false,
        dateUpdated: null,
        updatedBy: null,
      ),
    );

    if (privilege.parentDashboard != null) {
      return state.hasPrivilege(privilege.parentDashboard!);
    }

    return true;
  }

  Widget _buildAccessDeniedScreen(
    BuildContext context,
    String requiredPrivilege,
    String? parentPrivilege,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Insufficient Privileges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Required: $requiredPrivilege'),
            if (parentPrivilege != null)
              Text('Parent Dashboard: $parentPrivilege'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/homePage'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
