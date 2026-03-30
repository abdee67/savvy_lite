// features/reports/sales_report/widgets/sidebar_menu.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';

class SidebarMenu extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final bool isDesktop;

  const SidebarMenu({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.isDesktop,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  String _selectedMenuItem = 'dashboard';
  bool _reportsExpanded = true;

  final List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(
      id: 'reports',
      title: 'Sales Reports',
      icon: Iconsax.folder,
      hasSubmenu: true,
      route: null,
    ),
    SidebarMenuItem(
      id: 'sales_transaction',
      title: 'Sales Transaction Report',
      icon: Iconsax.calendar_tick,
      parentId: 'reports',
      route: AppRoutes.salesTransactionReport,
    ),
    SidebarMenuItem(
      id: 'credit_received',
      title: 'Credit Received Report',
      icon: Iconsax.calendar_1,
      parentId: 'reports',
      route: AppRoutes.creditRecievedReport,
    ),
    SidebarMenuItem(
      id: 'aged_credit',
      title: 'Aged Credit Report',
      icon: Iconsax.calendar_1,
      parentId: 'reports',
      route: AppRoutes.agedCreditSalesReport,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Logo Section
          _buildLogoSection(),

          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: _buildMenuItems()),
            ),
          ),

          // User Profile & Settings
          if (widget.isExpanded || widget.isDesktop) _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.isExpanded || widget.isDesktop) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155888).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.box,
                    color: Color(0xFF155888),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF155888),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Analytics Suite',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ] else if (widget.isDesktop) ...[
            // Collapsed desktop mode - just icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF155888).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.box,
                color: Color(0xFF155888),
                size: 24,
              ),
            ),
          ],
          if (widget.isDesktop && widget.isExpanded)
            IconButton(
              icon: const Icon(Iconsax.arrow_left_2, size: 20),
              onPressed: widget.onToggleExpanded,
              tooltip: 'Collapse menu',
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final mainItems = _menuItems
        .where((item) => item.parentId == null)
        .toList();
    final List<Widget> widgets = [];

    for (var item in mainItems) {
      if (item.hasSubmenu) {
        widgets.add(_buildSubmenuSection(item));
      } else {
        widgets.add(_buildMenuItem(item));
      }
    }

    return widgets;
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final isSelected = _selectedMenuItem == item.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMenuItem = item.id;
            });
            if (item.route != null) {
              context.push(item.route!);
            }
            if (!widget.isDesktop) {
              widget.onToggleExpanded();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (widget.isExpanded || widget.isDesktop) ? 16 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF155888).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFF155888).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: (widget.isExpanded || widget.isDesktop)
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? const Color(0xFF155888)
                      : Colors.grey.shade600,
                  size: 20,
                ),
                if (widget.isExpanded || widget.isDesktop) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF155888)
                            : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF155888),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenuSection(SidebarMenuItem parentItem) {
    final subItems = _menuItems
        .where((item) => item.parentId == parentItem.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent Item
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _reportsExpanded = !_reportsExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (widget.isExpanded || widget.isDesktop) ? 16 : 12,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: (widget.isExpanded || widget.isDesktop)
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      parentItem.icon,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    if (widget.isExpanded || widget.isDesktop) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          parentItem.title,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        _reportsExpanded
                            ? Iconsax.arrow_up_2
                            : Iconsax.arrow_down_2,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Submenu Items
        if (_reportsExpanded && (widget.isExpanded || widget.isDesktop))
          ...subItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _buildMenuItem(item),
            ),
          ),
      ],
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: (widget.isExpanded || widget.isDesktop)
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF155888).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.profile_circle,
                    color: Color(0xFF155888),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin User',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Super Admin',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Iconsax.logout,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {},
                ),
              ],
            )
          : IconButton(icon: const Icon(Iconsax.logout), onPressed: () {}),
    );
  }
}

class SidebarMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isActive;
  final bool hasSubmenu;
  final String? parentId;
  final String? route;

  SidebarMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isActive = false,
    this.hasSubmenu = false,
    this.parentId,
    required this.route,
  });
}
