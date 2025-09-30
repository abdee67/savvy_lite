class AppRoutes {
  // Auth & Core
  static const String welcome = '/welcome';
  static const String authCheck = '/auth-check';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String homePage = '/homePage';
  static const String unauthorized = '/unauthorized';
  static const String systemConstants = '/system-constants';

  // Dashboard Base Paths
  static const String admin = '/admin';
  static const String sales = '/sales';
  static const String stock = '/stock';
  static const String availability = '/availability';
  static const String purchase = '/purchase';
  static const String company = '/company';
  static const String branch = '/branch';

  // Main Dashboards
  static const String adminDashboard = '$admin/dashboard';
  static const String salesDashboard = '$sales/dashboard';
  static const String stockDashboard = '$stock/dashboard';
  static const String availabilityDashboard = '$availability/dashboard';
  static const String purchaseDashboard = '$purchase/dashboard';
  static const String companyDashboard = '$company/dashboard';
  static const String branchListDashboard = '$branch/list-dashboard';

  // Admin Sub-Routes
  static const String privilegeManagement = '$admin/privilege-management';
  static const String roleManagement = '$admin/role-management';
  static const String employeeManagement = '$admin/employee-management';
  static const String userManagement = '$admin/user-management';

  // Employee Sub-Routes
  static const String employeeCreation =
      '/admin/employee-management/add-employee';
  static const String employeeConversionToUser =
      '/admin/employee-management/employee-conversion-to-user';
  static const String employeeEdit = '/admin/employee-management/employee-edit';
  static const String employeeDelete =
      '/admin/employee-management/employee-delete';

  // User Sub-Routes
  static const String userCreation = '/admin/user-management/add-user';
  static const String userEdit = '/admin/user-management/edit-user';
  static const String userDelete = '/admin/user-management/delete-user';

  // Sales Sub-Routes
  static const String customerEntry = '$sales/customer-dashboard';

  static const String salesCustomerInfo = '$salesDashboard/sales-customer-info';
  static const String salesItemEntry = '$salesCustomerInfo/sales-item-entry';
  static const String paymentSummary = '$salesCustomerInfo/payment-summary';
  static const String salesInvoice = '$salesCustomerInfo/sales-invoice';

  // Stock Sub-Routes
  static const String itemEntry = '$stock/item-entry';
  static const String uomManagement = '$stock/uom-management';
  static const String itemWorkbench = '$stock/item-workbench';
  static const String itemUomConversions = '$stock/item-uom-conversions';
  static const String locationEntry = '$stock/location-entry';
  static const String lotEntry = '$stock/lot-entry';
  static const String lotColorings = '$stock/lot-colorings';
  static const String inventoryTransaction = '$stock/inventory-transaction';
  static const String itemBranchEntry = '$stock/item-branch-entry';
  static const String barcodeFunction = '$stock/barcode-function';
  static const String exportFunction = '$stock/export-function';

  // Helper method to get all dashboard routes
  static List<String> get dashboardRoutes => [
    adminDashboard,
    salesDashboard,
    stockDashboard,
    availabilityDashboard,
    purchaseDashboard,
    companyDashboard,
    branchListDashboard,
  ];
}
