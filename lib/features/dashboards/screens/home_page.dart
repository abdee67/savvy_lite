import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/privilege_constants.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedDashboard;

  // Dashboard configuration
  final Map<String, _DashboardConfig> _dashboardConfigs = {
    PrivilegeConstants.adminDashboard: _DashboardConfig(
      title: 'Admin',
      icon: Iconsax.user,
      description: 'Manage system administration and user management',
      color: Colors.red,
      features: {
        PrivilegeConstants.privilegeManagement: 'Privilege Management',
        PrivilegeConstants.roleManagement: 'Role Management',
        PrivilegeConstants.employeeManagement: 'Employee Management',
        PrivilegeConstants.userManagement: 'User Management',
      },
    ),
    PrivilegeConstants.salesDashboard: _DashboardConfig(
      title: 'Sales',
      icon: Iconsax.shopping_cart,
      description: 'Sales operations and customer management',
      color: Colors.blue,
      features: {
        PrivilegeConstants.salesItemEntry: 'Sales Item Entry',
        PrivilegeConstants.customerEntry: 'Customer Entry',
      },
    ),
    PrivilegeConstants.stockDashboard: _DashboardConfig(
      title: 'Stock',
      icon: Iconsax.shapes,
      description: 'Inventory and stock management',
      color: Colors.green,
      features: {
        PrivilegeConstants.itemEntry: 'Item Entry',
        PrivilegeConstants.uomManagement: 'UoM Management',
        PrivilegeConstants.itemWorkbench: 'Item Entry Workbench',
        PrivilegeConstants.itemUomConversions: 'Item UoM Conversions',
        PrivilegeConstants.locationEntry: 'Location Entry',
        PrivilegeConstants.lotEntry: 'Lot Entry',
        PrivilegeConstants.lotColorings: 'Lot Colorings',
        PrivilegeConstants.inventoryTransaction: 'Inventory Transaction Entry',
        PrivilegeConstants.itemBranchEntry: 'Item Branch Entry',
      },
    ),
    PrivilegeConstants.availabilityDashboard: _DashboardConfig(
      title: 'Availability',
      icon: Iconsax.calendar,
      description: 'Stock availability and planning',
      color: Colors.orange,
      features: {
        // Add availability-specific features here
        '/availability/order-entry': 'Order Entry',
        '/availability/order-history': 'Order History',
      },
    ),
    PrivilegeConstants.purchaseDashboard: _DashboardConfig(
      title: 'Purchase',
      icon: Iconsax.buy_crypto,
      description: 'Purchase and procurement management',
      color: Colors.purple,
      features: {
        // Add purchase-specific features here
        '/purchase/purchase-entry': 'Purchase Entry',
        '/purchase/credit-purchase': 'Credit Purchase',
        '/purchase/supplier': 'Supplier Management',
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final availableDashboards = PrivilegeConstants.getAvailableDashboards(
          authState.privileges,
        );

        if (availableDashboards.isEmpty) {
          return _buildNoPrivilegesScreen();
        }

        // Auto-select first available dashboard if none selected
        if (_selectedDashboard == null && availableDashboards.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedDashboard = availableDashboards.first;
            });
          });
        }

        return Scaffold(
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: Stack(
                  children: [
                    // Background with radial gradient
                    Container(
                      width: double.infinity,
                      height: 167,
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.5, -0.5),
                          radius: 2.5,
                          colors: [Color(0xFF383838), Color(0xFF565555)],
                          stops: [0.46, 1.0],
                        ),
                      ),
                    ),

                    // Main content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(context, authState),
                        if (availableDashboards.isEmpty)
                          _buildNoPrivilegesScreen()
                        else
                          Column(
                            children: [
                              _buildDashboardSelector(
                                context,
                                availableDashboards,
                                authState,
                              ),
                              _buildFeaturesSection(context, authState),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomSheet: _buildFooter(),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, AuthState authState) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.username?.toUpperCase() ?? 'USER',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Roles: ${authState.roles.map((r) => r.name).join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'System Constants') {
                    context.push('/system_constant');
                  } else if (value == 'Logout') {
                    context.read<AuthBloc>().add(LogoutRequested());
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'System Constants',
                    child: Text('System Constants'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 45),
        ],
      ),
    );
  }

  Widget _buildDashboardSelector(
    BuildContext context,
    List<String> availableDashboards,
    AuthState authState,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard selector buttons
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF383838),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: availableDashboards.map((dashboardUri) {
                final config = _dashboardConfigs[dashboardUri];
                final isSelected = _selectedDashboard == dashboardUri;

                return Tooltip(
                  message: config?.title ?? dashboardUri,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDashboard = dashboardUri;
                      });
                    },
                    child: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: config?.color ?? Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              config?.title ?? dashboardUri,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : Icon(
                            config?.icon ?? Iconsax.user,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Description section
          Container(
            decoration: BoxDecoration(
              color: _selectedDashboard != null
                  ? _dashboardConfigs[_selectedDashboard]?.color ??
                        const Color(0xFF155888)
                  : const Color(0xFF155888),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: _selectedDashboard != null
                ? Text(
                    _dashboardConfigs[_selectedDashboard]?.description ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  )
                : const Text(
                    'Select a dashboard to view features',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, AuthState authState) {
    if (_selectedDashboard == null) {
      return const SizedBox.shrink();
    }

    final config = _dashboardConfigs[_selectedDashboard!];
    if (config == null) return const SizedBox.shrink();

    // Get features that user has access to
    final availableFeatures = config.features.entries
        .where((feature) => authState.hasPrivilege(feature.key))
        .toList();

    if (availableFeatures.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Access to ${config.title} Features',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have dashboard access but no specific feature privileges.\nContact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${config.title} Features',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...availableFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeatureButton(
                featureName: feature.value,
                privilegeUri: feature.key,
                color: config.color,
                onPressed: () =>
                    _handleFeatureNavigation(context, feature.key, authState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPrivilegesScreen() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Dashboard Access',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You do not have access to any dashboard privileges.\nPlease contact your administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            child: const Text('Return to Login'),
          ),
        ],
      ),
    );
  }

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
}

Widget _buildFooter() {
  return Container(
    height: 60,
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Colors.grey[300]!)),
    ),
    child: const Center(
      child: Text(
        'POWERED BY TECH EQUATIONS',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w300,
        ),
      ),
    ),
  );
}

class _DashboardConfig {
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final Map<String, String> features; // privilege_uri -> display_name

  const _DashboardConfig({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.features,
  });
}

class _FeatureButton extends StatelessWidget {
  final String featureName;
  final String privilegeUri;
  final Color color;
  final VoidCallback onPressed;

  const _FeatureButton({
    required this.featureName,
    required this.privilegeUri,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward, color: color, size: 20),
        ),
        title: Text(
          featureName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          privilegeUri,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
