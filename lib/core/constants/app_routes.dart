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
  static const String branchListDashboard = '$branch/dashboard';

  // Admin Sub-Routes
  static const String privilegeManagement = '$admin/privilege-management';
  static const String roleManagement = '$admin/role-management';
  static const String employeeManagement = '$admin/employee-management';
  static const String userManagement = '$admin/user-management';

  static const String createPrivilege = '$privilegeManagement/create-privilege';
  static const String deletePrivilege = '$privilegeManagement/delete-privilege';
  static const String editPrivilege = '$privilegeManagement/edit-privilege';

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
  static const String customerCreate = '$customerEntry/customer-create';
  static const String customerEdit = '$customerEntry/customer-edit';
  static const String customerDelete = '$customerEntry/customer-delete';

  static const String salesCustomerInfo = '$salesDashboard/sales-customer-info';
  static const String salesItemEntry = '$salesCustomerInfo/sales-item-entry';
  static const String paymentSummary = '$salesCustomerInfo/payment-summary';
  static const String salesInvoice = '$salesCustomerInfo/sales-invoice';

  static const String salesReport = '$salesDashboard/sales-report';
  static const String salesCreditReceiptReview =
      '$salesDashboard/sales-credit-receipt-review';

  static const String salesReturn = '$salesDashboard/sales-return';

  static const String quotationOrder = '$salesDashboard/quotation-order';
  static const String quotationItemEntry =
      '$quotationOrder/quotation-item-entry';
  static const String quotationOrderPayment = '$quotationOrder/payment-summary';
  static const String quotationInvoiceReview =
      '$quotationOrder/quotation-invoice-review';

  static const String quotationOrderReview = '$salesDashboard/quotation-report';

  //Role sub-routes
  static const String roleCreation = '$roleManagement/add-role';
  static const String roleEdit = '$roleManagement/edit-role';
  static const String roleDelete = '$roleManagement/delete-role';

  //////////STOCK ROUTES///////////////
  static const String itemEntry = '$stock/item-entry';
  static const String itemCreation = '$itemEntry/add-item';
  static const String itemEdit = '$itemEntry/edit-item';
  static const String itemDelete = '$itemEntry/delete-item';
  static const String itemExport = '$itemEntry/export-item';
  static const String itemImport = '$itemEntry/import-item';

  static const String itemInBranch = '$stock/item-in-branch';
  static const String addItemToBranch = '$itemInBranch/add-item';
  static const String editItemInBranch = '$itemInBranch/edit-item';
  static const String deleteItemInBranch = '$itemInBranch/delete-item';
  static const String exportItemInBranch = '$itemInBranch/export-item';
  static const String importItemInBranch = '$itemInBranch/import-item';

  static const String uomManagement = '$stock/uom-management';

  //item workbench
  static const String itemWorkbench = '$stock/item-workbench';
  static const String itemWorkbenchSingleCreate =
      '$itemWorkbench/create-item-workbench';
  static const String itemWorkbenchBatchUpload =
      '$itemWorkbench/batch-upload-item-workbench';
  static const String itemWorkbenchDelete =
      '$itemWorkbench/delete-item-workbench';

  static const String itemUomConversions = '$stock/item-uom-conversions';
  static const String itemUomConversionsCreate =
      '$itemUomConversions/create-item-uom-conversion';
  static const String itemUomConversionsEdit =
      '$itemUomConversions/edit-item-uom-conversion';
  static const String itemUomConversionsDelete =
      '$itemUomConversions/delete-item-uom-conversion';

  static const String locationEntry = '$stock/location-entry';
  static const String locationMasterCreate =
      '$locationEntry/location-master-create';
  static const String locationMasterEdit =
      '$locationEntry/location-master-edit';
  static const String locationMasterDelete =
      '$locationEntry/location-master-delete';

  static const String lotEntry = '$stock/lot-entry';
  static const String lotCreation = '$lotEntry/lot-creation';
  static const String lotEdit = '$lotEntry/lot-edit';
  static const String lotDelete = '$lotEntry/lot-delete';

  static const String lotColorings = '$stock/lot-colorings';
  static const String lotColoringCreate = '$lotColorings/lot-coloring-create';
  static const String lotColoringEdit = '$lotColorings/lot-coloring-edit';
  static const String lotColoringDelete = '$lotColorings/lot-coloring-delete';

  //item Transactions Sub-Routes
  static const String inventoryTransaction = '$stock/inventory-transaction';
  static const String inventoryTransactionCreate =
      '$inventoryTransaction/inventory-transaction-create';
  static const String inventoryTransactionEdit =
      '$inventoryTransaction/inventory-transaction-edit';
  static const String inventoryTransactionDelete =
      '$inventoryTransaction/inventory-transaction-delete';

  static const String itemBranchEntry = '$stock/item-branch-entry';
  static const String barcodeFunction = '$stock/barcode-function';
  static const String exportFunction = '$stock/export-function';

  // Branch Sub-Routes
  static const String branchManagement = '$branch/branch-management';

  static const String branchCreation = '$branchManagement/branch-creation';
  static const String branchEdit = '$branchManagement/edit-branch';
  static const String branchDelete = '$branchManagement/delete-branch';

  //////////Purchase ROUTES///////////////

  static const String supplierEntry = '$purchase/supplier-dashboard';
  static const String supplierCreate = '$supplierEntry/create-supplier';
  static const String supplierEdit = '$supplierEntry/edit-supplier';
  static const String supplierDelete = '$supplierEntry/delete-supplier';

  //static const String purchaseEntry = '$purchase/purchase-dashboard';
  static const String purchaseReview = '$purchase/purchase-review';
  static const String purchaseSupplierInfo =
      '$purchaseReview/purchase-supplier-info';
  static const String purchaseItemEntry = '$purchaseReview/purchase-item-entry';
  static const String purchaseOrderPayment = '$purchaseReview/payment-summary';
  static const String purchaseOrderReceive = '$purchaseReview/purchase-receive';

  static const String creditPurchaseReview = '$purchase/credit-purchase-review';

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
