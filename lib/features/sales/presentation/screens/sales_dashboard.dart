// features/sales/screens/sales_dashboard.dart
/* import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import '../../../auth/blocs/auth_bloc.dart';
import '../../../../core/constants/privilege_constants.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _buildSalesDashboard(context, authState),
    );
  }

  Widget _buildSalesDashboard(BuildContext context, AuthState authState) {
    final hasSalesEntry = authState.hasPrivilege(PrivilegeConstants.salesEntry);
    final hasCustomerManagement = authState.hasPrivilege(PrivilegeConstants.customerEntry);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales Operations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          if (hasSalesEntry) _buildSalesEntrySection(context, authState),
          if (hasCustomerManagement) _buildCustomerManagementSection(context, authState),
          
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
            const Text('Sales Entry Process', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (authState.hasPrivilege(PrivilegeConstants.customerEntry))
                  _FeatureButton(
                    label: 'Customer Entry',
                    icon: Icons.person_add,
                    onPressed: () => context.go('/sales/customer-entry'),
                  ),
                
                if (authState.hasPrivilege(PrivilegeConstants.itemEntry))
                  _FeatureButton(
                    label: 'Item Entry',
                    icon: Icons.inventory,
                    onPressed: () => _startItemEntry(context, authState),
                  ),
                
                if (authState.hasPrivilege(PrivilegeConstants.paymentSummary))
                  _FeatureButton(
                    label: 'Payment Summary',
                    icon: Icons.payment,
                    onPressed: () => context.go('/sales/payment-summary'),
                  ),
                
                if (authState.hasPrivilege(PrivilegeConstants.salesInvoice))
                  _FeatureButton(
                    label: 'Invoice',
                    icon: Icons.receipt,
                    onPressed: () => context.go('/sales/sales-dashboard/sales-invoice'),
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
    context.go('/sales/item-entry');
    
    // Store the next step based on user privileges
    final nextStep = authState.hasPrivilege(PrivilegeConstants.paymentSummary) 
        ? '/sales/payment-summary'
        : '/sales-dashboard';
        
    // You can store this in a sales bloc or pass as parameter
  }

  Widget _buildCustomerManagementSection(BuildContext context, AuthState authState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (authState.hasPrivilege(PrivilegeConstants.viewCustomerList))
                  _FeatureButton(
                    label: 'View Customers',
                    icon: Icons.list,
                    onPressed: () => context.go('/sales/customer-list'),
                  ),
                
                if (authState.hasPrivilege(PrivilegeConstants.addCustomer))
                  _FeatureButton(
                    label: 'Add Customer',
                    icon: Icons.add,
                    onPressed: () => context.go('/sales/add-customer'),
                  ),
                
                if (authState.hasPrivilege(PrivilegeConstants.editCustomer))
                  _FeatureButton(
                    label: 'Edit Customer',
                    icon: Icons.edit,
                    onPressed: () => context.go('/sales/edit-customer'),
                  ),
                
                if (authState.hasPrivilege(PrivilegeConstants.deleteCustomer))
                  _FeatureButton(
                    label: 'Delete Customer',
                    icon: Icons.delete,
                    onPressed: () => context.go('/sales/delete-customer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccessSection(String sectionName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.block, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No access to $sectionName features', style: const TextStyle(color: Colors.grey)),
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
}*/
