import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final requiredPrivilege =
        extra?['requiredPrivilege'] as String? ?? 'Unknown';
    final missingPrivileges =
        extra?['missingPrivileges'] as List<String>? ?? [];
    final hierarchy = extra?['hierarchy'] as List<String>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.orange[700]),
            const SizedBox(height: 24),
            const Text(
              'Permission Required',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'You need additional permissions to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),

            // Required Privilege Hierarchy
            if (hierarchy.isNotEmpty) ...[
              _buildHierarchySection(hierarchy, missingPrivileges),
              const SizedBox(height: 24),
            ],

            // Missing Privileges
            if (missingPrivileges.isNotEmpty) ...[
              _buildMissingPrivilegesSection(missingPrivileges),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchySection(
    List<String> hierarchy,
    List<String> missingPrivileges,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Access Path:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...hierarchy.asMap().entries.map((entry) {
            final index = entry.key;
            final privilege = entry.value;
            final isMissing = missingPrivileges.contains(privilege);

            return Padding(
              padding: EdgeInsets.only(left: (index * 20).toDouble()),
              child: Row(
                children: [
                  Icon(
                    isMissing ? Icons.close : Icons.check,
                    color: isMissing ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatPrivilegeName(privilege),
                      style: TextStyle(
                        color: isMissing ? Colors.red : Colors.green,
                        fontWeight: isMissing
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMissingPrivilegesSection(List<String> missingPrivileges) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Missing Permissions:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...missingPrivileges.map(
            (privilege) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${_formatPrivilegeName(privilege)}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.homePage),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Go to Dashboard',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  String _formatPrivilegeName(String privilegeUri) {
    // Convert URI to readable name
    final name = privilegeUri.split('/').last.replaceAll('-', ' ');
    return name
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
