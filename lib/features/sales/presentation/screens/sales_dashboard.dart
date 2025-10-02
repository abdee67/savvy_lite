// features/sales/screens/sales_dashboard.dart import 'package:flutter/material.dart';
/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import '../../../auth/blocs/auth_bloc.dart';
import '../../../../core/constants/privilege_constants.dart';

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  void _handleFeatureNavigation(
    BuildContext context,
    String privilegeUri,
    AuthState authState,
  ) {
    if (authState.hasPrivilege(privilegeUri)) {
      context.push(privilegeUri);
    } else if (privilegeUri.isNotEmpty) {
      // Fallback: Show feature dialog for unimplemented features
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Feature Coming Soon'),
          content: Text('The $privilegeUri feature is under development.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        backgroundColor: Colors.amber,
      ),
      body: _buildSalesDashboard(context, authState),
    );
  }

  Widget _buildSalesDashboard(BuildContext context, AuthState authState) {
    final hasSalesEntry = authState.hasPrivilege(PrivilegeConstants.salesEntry);
    final hasCustomerManagement = authState.hasPrivilege(
      PrivilegeConstants.customerEntry,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Operations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (hasSalesEntry) _buildSalesEntrySection(context, authState),

          if (!hasSalesEntry && !hasCustomerManagement)
            _buildNoAccessSection('Sales operations'),
        ],
      ),
    );
  }

  Widget _buildSalesEntrySection(BuildContext context, AuthState authState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Entry Process',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (authState.hasPrivilege(
                  PrivilegeConstants.salesCustomerInfo,
                ))
                  _FeatureButton(
                    label: 'Customer Info',
                    icon: Icons.person_add,
                    onPressed: () =>
                        context.push(PrivilegeConstants.salesCustomerInfo),
                  ),

                if (authState.hasPrivilege(PrivilegeConstants.salesItemEntry))
                  _FeatureButton(
                    label: 'Sales Item Entry',
                    icon: Icons.inventory,
                    onPressed: () =>
                        context.push(PrivilegeConstants.salesItemEntry),
                  ),

                if (authState.hasPrivilege(PrivilegeConstants.paymentSummary))
                  _FeatureButton(
                    label: 'Payment Summary',
                    icon: Icons.payment,
                    onPressed: () =>
                        context.push(PrivilegeConstants.paymentSummary),
                  ),

                if (authState.hasPrivilege(PrivilegeConstants.salesInvoice))
                  _FeatureButton(
                    label: 'Invoice',
                    icon: Icons.receipt,
                    onPressed: () =>
                        context.push(PrivilegeConstants.salesInvoice),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startItemEntry(BuildContext context, AuthState authState) {
    // Start item entry process
    context.push('/sales/item-entry');

    // Store the next step based on user privileges
    final nextStep = authState.hasPrivilege(PrivilegeConstants.paymentSummary)
        ? '/sales/payment-summary'
        : '/sales-dashboard';

    // You can store this in a sales bloc or pass as parameter
  }

  Widget _buildNoAccessSection(String sectionName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.block, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No access to $sectionName features',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _FeatureButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
*/
