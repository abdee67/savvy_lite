import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedDashboard;

  // Dashboard configuration - Updated to use AppRoutes
  final Map<String, _DashboardConfig> _dashboardConfigs = {
    AppRoutes.adminDashboard: _DashboardConfig(
      title: 'Admin',
      icon: Iconsax.user,
      description: 'Manage system administration and user management',
      color: Colors.red,
    ),
    AppRoutes.salesDashboard: _DashboardConfig(
      title: 'Sales',
      icon: Iconsax.shopping_cart,
      description:
          'Sales operations,Customer info, Payment summary and customer management',
      color: Colors.blue,
    ),
    AppRoutes.stockDashboard: _DashboardConfig(
      title: 'Stock',
      icon: Iconsax.shapes,
      description:
          'Item entry,UoM Management and stock management with Location Entry',
      color: Colors.green,
    ),
    AppRoutes.availabilityDashboard: _DashboardConfig(
      title: 'Availability',
      icon: Iconsax.calendar,
      description: 'Stock availability,Item avaialability and planning',
      color: Colors.orange,
    ),
    AppRoutes.purchaseDashboard: _DashboardConfig(
      title: 'Purchase',
      icon: Iconsax.buy_crypto,
      description: 'Purchase assignment and procurement management',
      color: Colors.purple,
    ),
    AppRoutes.companyDashboard: _DashboardConfig(
      title: 'Company',
      icon: Iconsax.building,
      description: 'Company information,branch infromation and settings',
      color: Colors.teal,
    ),
    AppRoutes.branchListDashboard: _DashboardConfig(
      title: 'Branches',
      icon: Iconsax.location,
      description: 'Branch management,controll, information and  and locations',
      color: Colors.indigo,
    ),
    AppRoutes.reportDashboard: _DashboardConfig(
      title: 'Reports',
      icon: Iconsax.chart,
      description: 'Reports and analytics',
      color: Colors.amber,
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

        // Use the new hierarchy-based method
        final availableDashboards = authState.getAvailableDashboards();

        if (availableDashboards.isEmpty) {
          return _buildNoPrivilegesScreen();
        }

        // Auto-select first available dashboard if none selected
        if (_selectedDashboard == null && availableDashboards.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return; // prevent setState after dispose
            setState(() {
              _selectedDashboard = availableDashboards.first;
            });
          });
        }

        // Listen to SystemConstantBloc so UI rebuilds when system constants change
        return BlocBuilder<SystemConstantBloc, SystemConstantState>(
          builder: (context, scState) {
            return Scaffold(
              body: SafeArea(
                bottom: false,
                top: false,
                child: LiquidPullToRefresh(
                  color: Color(0xFF155888),
                  backgroundColor: Colors.amber,
                  showChildOpacityTransition: false,
                  onRefresh: () async {
                    // Trigger reload of system constants and other global data so changes appear instantly
                    final companyId = context.read<AuthBloc>().state.companyId;
                    if (companyId != null) {
                      context.read<SystemConstantBloc>().add(
                        LoadSystemConstants(companyId),
                      );
                    }
                    // Small delay to allow blocs to process and UI to reflect changes
                    await Future.delayed(const Duration(milliseconds: 600));
                    // Optionally show a quick feedback
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Refreshed')),
                      );
                    }
                  },
                  // The child must be scrollable for RefreshIndicator to work
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Stack(
                          children: [
                            // Background with radial gradient
                            Container(
                              margin: const EdgeInsets.only(bottom: 50),
                              width: double.infinity,
                              height: 167,
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(0.5, -0.5),
                                  radius: 2.5,
                                  colors: [
                                    Color(0xFF383838),
                                    Color(0xFF565555),
                                  ],
                                  stops: [0.46, 1.0],
                                ),
                              ),
                            ),

                            // Main content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderSection(context, authState),
                                Column(
                                  children: [
                                    _buildDashboardSelector(
                                      context,
                                      availableDashboards,
                                      authState,
                                    ),
                                    _buildFeaturesSection(context, authState),
                                    const SizedBox(
                                      height: 40,
                                    ), // Added space for footer visibility
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottomSheet: _buildFooter(),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, AuthState authState) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
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
                clipBehavior: Clip.antiAlias,
                child:
                    authState.companyLogo != null &&
                        authState.companyLogo!.isNotEmpty
                    ? (authState.companyLogo!.startsWith('assets/')
                          ? Image.asset(
                              authState.companyLogo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : Image.file(
                              File(authState.companyLogo!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business,
                                  color: Colors.grey,
                                );
                              },
                            ))
                    : const Icon(Icons.business, color: Colors.grey),
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
                    context.push(AppRoutes.systemConstants);
                  } else if (value == 'Logout') {
                    context.read<AuthBloc>().add(LogoutRequested(context));
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
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard selector buttons
          // Enhanced Dashboard selector with smooth scrolling
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF383838),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                // Scrollable dashboard buttons
                SizedBox(
                  height: 70, // Slightly taller to accommodate the scrollbar
                  child: Scrollbar(
                    thumbVisibility:
                        false, // Always show scrollbar when scrollable
                    thickness: 2,
                    radius: const Radius.circular(2),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      children: availableDashboards.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final dashboardUri = entry.value;
                        final config = _dashboardConfigs[dashboardUri];
                        final isSelected = _selectedDashboard == dashboardUri;
                        final isFirst = index == 0;
                        final isLast = index == availableDashboards.length - 1;

                        return Container(
                          margin: EdgeInsets.only(
                            left: isFirst ? 0 : 4,
                            right: isLast ? 0 : 4,
                          ),
                          child: Tooltip(
                            message:
                                config?.title ??
                                _formatDashboardName(dashboardUri),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDashboard = dashboardUri;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? config?.color ?? Colors.amber
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color:
                                                    (config?.color ??
                                                            Colors.amber)
                                                        .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isSelected) ...[
                                          Icon(
                                            config?.icon ?? Iconsax.user,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          isSelected
                                              ? config?.title ??
                                                    _formatDashboardName(
                                                      dashboardUri,
                                                    )
                                              : config?.title ??
                                                    _formatDashboardName(
                                                      dashboardUri,
                                                    ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSelected ? 14 : 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Optional: Add indicators for scroll hint
                if (availableDashboards.length > 4) ...[
                  Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(availableDashboards.length, (
                        index,
                      ) {
                        final isActive =
                            _selectedDashboard == availableDashboards[index];
                        return Container(
                          width: 8,
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
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
                    _dashboardConfigs[_selectedDashboard]?.description ??
                        'Manage ${_formatDashboardName(_selectedDashboard!)} operations',
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

    // Get features using the new hierarchy system
    final availableFeatures = authState.getFeaturesForDashboard(
      _selectedDashboard!,
    );

    // Check system constant: if Apply Lot Management is disabled, hide lot-related features
    final systemConstant = context.read<SystemConstantBloc>().state.selected;
    List<Privilege> filteredFeatures = availableFeatures;
    if ((systemConstant?.applyLotMgmBoolean != true) &&
        _selectedDashboard == AppRoutes.stockDashboard) {
      filteredFeatures = availableFeatures.where((p) {
        // Exclude Lot Entry and Lot Colorings routes and their subroutes
        if (p.uri.startsWith(AppRoutes.lotEntry)) return false;
        if (p.uri.startsWith(AppRoutes.lotColorings)) return false;
        return true;
      }).toList();
    }

    if (filteredFeatures.isEmpty) {
      final config = _dashboardConfigs[_selectedDashboard!];

      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Access to ${config?.title ?? _formatDashboardName(_selectedDashboard!)} Features',
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

    final config = _dashboardConfigs[_selectedDashboard!];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${config?.title ?? _formatDashboardName(_selectedDashboard!)} Features',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredFeatures.length,
                  itemBuilder: (context, index) {
                    final privilege = filteredFeatures[index];
                    return _FeatureButton(
                      privilege: privilege,
                      color: config?.color ?? Colors.grey,
                      onPressed: () =>
                          _handleFeatureNavigation(context, privilege),
                    );
                  },
                );
              }
              return Column(
                children: filteredFeatures
                    .map(
                      (privilege) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeatureButton(
                          privilege: privilege,
                          color: config?.color ?? Colors.grey,
                          onPressed: () =>
                              _handleFeatureNavigation(context, privilege),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
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
            onPressed: () =>
                context.read<AuthBloc>().add(LogoutRequested(context)),
            child: const Text('Return to Login'),
          ),
        ],
      ),
    );
  }

  void _handleFeatureNavigation(BuildContext context, Privilege privilege) {
    // Check if user has access to this specific feature using hierarchy
    if (context.read<AuthBloc>().state.hasAccessToPrivilege(privilege.uri)) {
      context.push(privilege.uri);
    } else {
      // Show access denied or feature not available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Access Denied'),
          content: Text(
            'You do not have permission to access ${privilege.name}.',
          ),
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

  String _formatDashboardName(String dashboardUri) {
    // Convert URI to readable name (e.g., "/admin/dashboard" -> "Admin")
    final name = dashboardUri.split('/').where((part) => part.isNotEmpty).first;
    return name[0].toUpperCase() + name.substring(1);
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
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'POWERED BY ',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: 'TECH EQUATIONS',
              style: TextStyle(
                color: Color(0xFF155888),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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

  const _DashboardConfig({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
  });
}

class _FeatureButton extends StatelessWidget {
  final Privilege privilege;
  final Color color;
  final VoidCallback onPressed;

  const _FeatureButton({
    required this.privilege,
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
          child: Icon(_getFeatureIcon(privilege.type), color: color, size: 20),
        ),
        title: Text(
          privilege.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          privilege.description,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  IconData _getFeatureIcon(String type) {
    switch (type) {
      case 'button':
        return Icons.play_arrow;
      case 'link':
      default:
        return Icons.arrow_forward;
    }
  }
}
