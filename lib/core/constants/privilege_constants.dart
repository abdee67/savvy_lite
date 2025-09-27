// core/constants/privilege_constants.dart
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

class PrivilegeConstants {
  // Main Dashboard Privileges(type link)
  static const String adminDashboard = '/admin-dashboard';
  static const String salesDashboard = '/sales-dashboard';
  static const String stockDashboard = '/stock-dashboard';
  static const String availabilityDashboard = '/availability-dashboard';
  static const String purchaseDashboard = '/purchase-dashboard';
  static const String companyDashboard = '/company-dashboard';
  static const String branchListDashboard = '/branch-list-dashboard';

  // Admin Sub-Privileges(type link)
  static const String privilegeManagement = '/admin/privilege-management';
  static const String roleManagement = '/admin/role-management';
  static const String employeeManagement = '/admin/employee-management';
  static const String userManagement = '/admin/user-management';

  // Admin 'Privilege' privileges(type buttons)
  static const String addPrivilege =
      '/admin/privilege-management/add-privilege';
  static const String editPrivilege =
      '/admin/privilege-management/edit-privilege';
  static const String deletePrivilege =
      '/admin/privilege-management/delete-privilege';

  // Admin 'Role' privileges(type buttons)
  static const String addRole = '/admin/role-management/add-role';
  static const String editRole = '/admin/role-management/edit-role';
  static const String deleteRole = '/admin/role-management/delete-role';

  // Admin 'Employee' privileges(type buttons)
  static const String addEmployee = '/admin/employee-management/add-employee';
  static const String editEmployee = '/admin/employee-management/edit-employee';
  static const String deleteEmployee =
      '/admin/employee-management/delete-employee';

  // Admin 'User' privileges(type buttons)
  static const String addUser = '/admin/user-management/add-user';
  static const String editUser = '/admin/user-management/edit-user';
  static const String deleteUser = '/admin/user-management/delete-user';

  // Sales Privileges(type link)
  static const String salesEntry = '/sales/sales-dashboard';
  static const String customerEntry = '/sales/customer-dashboard';

  // Sales Sub-Privileges(type link)
  static const String salesCustomerInfo =
      '/sales/sales-dashboard/sales-customer-info';
  static const String salesItemEntry =
      '/sales/sales-dashboard/sales-item-entry';
  static const String paymentSummary = '/sales/sales-dashboard/payment-summary';
  static const String salesInvoice = '/sales/sales-dashboard/sales-invoice';

  // Sales 'Customer' privileges(type buttons)
  static const String addCustomer = '/sales/customer-dashboard/add-customer';
  static const String editCustomer = '/sales/customer-dashboard/edit-customer';
  static const String deleteCustomer =
      '/sales/customer-dashboard/delete-customer';

  // Stock Sub-Privileges
  static const String itemEntry = '/stock/item-entry';
  static const String uomManagement = '/stock/uom-management';
  static const String itemWorkbench = '/stock/item-workbench';
  static const String itemUomConversions = '/stock/item-uom-conversions';
  static const String locationEntry = '/stock/location-entry';
  static const String lotEntry = '/stock/lot-entry';
  static const String lotColorings = '/stock/lot-colorings';
  static const String inventoryTransaction = '/stock/inventory-transaction';
  static const String itemBranchEntry = '/stock/item-branch-entry';
  static const String barcodeFunction = '/stock/barcode-function';
  static const String exportFunction = '/stock/export-function';

  // Helper methods to check privilege hierarchies
  static bool hasDashboardAccess(
    List<Privilege> privileges,
    String dashboardUri,
  ) {
    return privileges.any((p) => p.uri == dashboardUri);
  }

  static bool hasSubPrivilege(
    List<Privilege> privileges,
    String subPrivilegeUri,
  ) {
    final privilege = privileges.firstWhere(
      (p) => p.uri == subPrivilegeUri,
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

    if (privilege.parentDashboard == null) return false;

    // Check if user has the parent dashboard access
    final parentDashboard = privilege.parentDashboard;
    return parentDashboard == null ||
        hasDashboardAccess(privileges, parentDashboard);
  }

  static List<String> getAvailableDashboards(List<Privilege> privileges) {
    return _dashboardUris
        .where((dashboard) => hasDashboardAccess(privileges, dashboard))
        .toList();
  }

  static List<Privilege> getFeaturesForDashboard(
    List<Privilege> privileges,
    String dashboardUri,
  ) {
    return privileges.where((privilege) {
      // Include features that belong to this dashboard
      final isFeature = !privilege.isDashboardPrivilege;
      final belongsToDashboard = privilege.parentDashboard == dashboardUri;

      return isFeature && belongsToDashboard;
    }).toList();
  }

  static final _dashboardUris = [
    adminDashboard,
    salesDashboard,
    stockDashboard,
    availabilityDashboard,
    purchaseDashboard,
    companyDashboard,
    branchListDashboard,
  ];
}
