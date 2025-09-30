import 'package:savvy_stock/core/constants/app_routes.dart';

class PrivilegeHierarchy {
  // Explicit parent-child relationships that match your database seeding
  static const Map<String, String?> hierarchy = {
    // ==================== MAIN DASHBOARDS (TOP LEVEL) ====================
    AppRoutes.adminDashboard: null,
    AppRoutes.salesDashboard: null,
    AppRoutes.stockDashboard: null,
    AppRoutes.availabilityDashboard: null,
    AppRoutes.purchaseDashboard: null,
    AppRoutes.companyDashboard: null,
    AppRoutes.branchListDashboard: null,

    // ==================== ADMIN MANAGEMENT ====================
    // Privilege Management (child of Admin Dashboard)
    AppRoutes.privilegeManagement: AppRoutes.adminDashboard,
    '/admin/privilege-management/add-privilege': AppRoutes.privilegeManagement,
    '/admin/privilege-management/edit-privilege': AppRoutes.privilegeManagement,
    '/admin/privilege-management/delete-privilege':
        AppRoutes.privilegeManagement,

    // Role Management (child of Admin Dashboard)
    AppRoutes.roleManagement: AppRoutes.adminDashboard,
    '/admin/role-management/add-role': AppRoutes.roleManagement,
    '/admin/role-management/edit-role': AppRoutes.roleManagement,
    '/admin/role-management/delete-role': AppRoutes.roleManagement,

    // Employee Management (child of Admin Dashboard)
    AppRoutes.employeeManagement: AppRoutes.adminDashboard,
    AppRoutes.employeeCreation: AppRoutes.employeeManagement,
    AppRoutes.employeeConversionToUser: AppRoutes.employeeManagement,
    AppRoutes.employeeEdit: AppRoutes.employeeManagement,
    AppRoutes.employeeDelete: AppRoutes.employeeManagement,

    // User Management (child of Admin Dashboard)
    AppRoutes.userManagement: AppRoutes.adminDashboard,
    AppRoutes.userCreation: AppRoutes.userManagement,
    AppRoutes.userEdit: AppRoutes.userManagement,
    AppRoutes.userDelete: AppRoutes.userManagement,

    // ==================== SALES MODULE ====================
    // Sales Entry (child of Sales Dashboard)
    AppRoutes.salesCustomerInfo: AppRoutes.salesDashboard,
    AppRoutes.salesItemEntry: AppRoutes.salesCustomerInfo,
    AppRoutes.paymentSummary: AppRoutes.salesCustomerInfo,
    AppRoutes.salesInvoice: AppRoutes.salesCustomerInfo,

    // Customer Entry (child of Sales Dashboard)
    AppRoutes.customerEntry: AppRoutes.salesDashboard,
    '/sales/customer-dashboard/add-customer': AppRoutes.customerEntry,
    '/sales/customer-dashboard/edit-customer': AppRoutes.customerEntry,
    '/sales/customer-dashboard/delete-customer': AppRoutes.customerEntry,

    // ==================== STOCK MODULE ====================
    AppRoutes.itemEntry: AppRoutes.stockDashboard,
    AppRoutes.uomManagement: AppRoutes.stockDashboard,
    AppRoutes.itemWorkbench: AppRoutes.stockDashboard,
    AppRoutes.itemUomConversions: AppRoutes.stockDashboard,
    AppRoutes.locationEntry: AppRoutes.stockDashboard,
    AppRoutes.lotEntry: AppRoutes.stockDashboard,
    AppRoutes.lotColorings: AppRoutes.stockDashboard,
    AppRoutes.inventoryTransaction: AppRoutes.stockDashboard,
    AppRoutes.itemBranchEntry: AppRoutes.stockDashboard,
    AppRoutes.barcodeFunction: AppRoutes.stockDashboard,
    AppRoutes.exportFunction: AppRoutes.stockDashboard,
  };

  /// Get the parent privilege for a given privilege URI
  static String? getParentPrivilege(String privilegeUri) {
    return hierarchy[privilegeUri];
  }

  /// Check if a privilege is a top-level dashboard
  static bool isDashboardPrivilege(String privilegeUri) {
    return hierarchy[privilegeUri] == null;
  }

  /// Get the complete hierarchy required to access a privilege
  static List<String> getRequiredPrivilegeHierarchy(String targetPrivilege) {
    final hierarchyList = <String>[];
    String? current = targetPrivilege;

    while (current != null) {
      hierarchyList.insert(0, current);
      current = getParentPrivilege(current);
    }

    return hierarchyList;
  }

  /// Check if a user has access to a privilege by verifying the entire hierarchy
  static bool hasAccessToPrivilege(
    List<String> userPrivileges,
    String targetPrivilege,
  ) {
    final requiredHierarchy = getRequiredPrivilegeHierarchy(targetPrivilege);

    for (final privilege in requiredHierarchy) {
      if (!userPrivileges.contains(privilege)) {
        return false;
      }
    }

    return true;
  }

  /// Get all child privileges for a parent privilege
  static List<String> getChildPrivileges(String parentPrivilege) {
    return hierarchy.entries
        .where((entry) => entry.value == parentPrivilege)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all dashboard privileges (top-level privileges)
  static List<String> getDashboardPrivileges() {
    return hierarchy.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get features/children for a specific dashboard
  static List<String> getFeaturesForDashboard(
    String dashboardUri,
    List<String> allPrivileges,
  ) {
    final features = <String>[];

    for (final privilege in allPrivileges) {
      final parent = getParentPrivilege(privilege);
      if (parent == dashboardUri) {
        features.add(privilege);
      }
    }

    return features;
  }
}
