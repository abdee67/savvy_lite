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
    AppRoutes.reportDashboard: null,

    // ==================== ADMIN MANAGEMENT ====================
    // Privilege Management (child of Admin Dashboard)
    /* AppRoutes.privilegeManagement: AppRoutes.adminDashboard,
    AppRoutes.createPrivilege: AppRoutes.privilegeManagement,
    AppRoutes.editPrivilege: AppRoutes.privilegeManagement,
    AppRoutes.deletePrivilege: AppRoutes.privilegeManagement,*/
    AppRoutes.fsnmrManagement: AppRoutes.fsnmrDashboard,
    AppRoutes.fsnmrCreate: AppRoutes.fsnmrManagement,
    AppRoutes.fsnmrEdit: AppRoutes.fsnmrManagement,
    AppRoutes.fsnmrDelete: AppRoutes.fsnmrManagement,

    // Role Management (child of Admin Dashboard)
    AppRoutes.roleManagement: AppRoutes.adminDashboard,
    AppRoutes.roleCreation: AppRoutes.roleManagement,
    AppRoutes.roleEdit: AppRoutes.roleManagement,
    AppRoutes.roleDelete: AppRoutes.roleManagement,

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

    //Sales Report (child of Sales Dashboard)
    AppRoutes.salesReview: AppRoutes.salesDashboard,
    AppRoutes.salesCreditReceiptReview: AppRoutes.salesDashboard,

    //Sales Return (child of Sales Dashboard)
    AppRoutes.salesReturn: AppRoutes.salesDashboard,

    //Quotation Order (child of Sales Dashboard)
    AppRoutes.quotationOrder: AppRoutes.salesDashboard,
    AppRoutes.quotationItemEntry: AppRoutes.quotationOrder,
    AppRoutes.quotationOrderPayment: AppRoutes.quotationOrder,
    AppRoutes.quotationInvoiceReview: AppRoutes.quotationOrder,

    AppRoutes.quotationOrderReview: AppRoutes.salesDashboard,
    // Customer Entry (child of Sales Dashboard)
    AppRoutes.customerEntry: AppRoutes.salesDashboard,
    AppRoutes.customerCreate: AppRoutes.customerEntry,
    AppRoutes.customerEdit: AppRoutes.customerEntry,
    AppRoutes.customerDelete: AppRoutes.customerEntry,

    // ==================== STOCK MODULE ====================
    // Item Entry (child of Stock Dashboard)
    AppRoutes.itemEntry: AppRoutes.stockDashboard,
    AppRoutes.itemCreation: AppRoutes.itemEntry,
    AppRoutes.itemEdit: AppRoutes.itemEntry,
    AppRoutes.itemDelete: AppRoutes.itemEntry,
    AppRoutes.itemExport: AppRoutes.itemEntry,
    AppRoutes.itemImport: AppRoutes.itemEntry,

    // Item In Branch (child of Stock Dashboard)
    AppRoutes.itemInBranch: AppRoutes.stockDashboard,
    AppRoutes.addItemToBranch: AppRoutes.itemInBranch,
    AppRoutes.editItemInBranch: AppRoutes.itemInBranch,
    AppRoutes.deleteItemInBranch: AppRoutes.itemInBranch,
    AppRoutes.exportItemInBranch: AppRoutes.itemInBranch,
    AppRoutes.importItemInBranch: AppRoutes.itemInBranch,

    // UOM Management (child of Stock Dashboard)
    AppRoutes.uomManagement: AppRoutes.stockDashboard,
    AppRoutes.uomCreation: AppRoutes.uomManagement,
    AppRoutes.uomEdit: AppRoutes.uomManagement,

    // Item Workbench (child of Stock Dashboard)
    AppRoutes.itemWorkbench: AppRoutes.stockDashboard,
    AppRoutes.itemWorkbenchSingleCreate: AppRoutes.itemWorkbench,
    AppRoutes.itemWorkbenchBatchUpload: AppRoutes.itemWorkbench,
    AppRoutes.itemWorkbenchDelete: AppRoutes.itemWorkbench,

    // Item UoM Conversions (child of Stock Dashboard)
    AppRoutes.itemUomConversions: AppRoutes.stockDashboard,
    AppRoutes.itemUomConversionsCreate: AppRoutes.itemUomConversions,
    AppRoutes.itemUomConversionsEdit: AppRoutes.itemUomConversions,
    AppRoutes.itemUomConversionsDelete: AppRoutes.itemUomConversions,

    // Location Entry (child of Stock Dashboard)
    AppRoutes.locationEntry: AppRoutes.stockDashboard,
    AppRoutes.locationMasterCreate: AppRoutes.locationEntry,
    AppRoutes.locationMasterEdit: AppRoutes.locationEntry,
    AppRoutes.locationMasterDelete: AppRoutes.locationEntry,

    //lot entry
    AppRoutes.lotEntry: AppRoutes.stockDashboard,
    AppRoutes.lotCreation: AppRoutes.lotEntry,
    AppRoutes.lotEdit: AppRoutes.lotEntry,
    AppRoutes.lotDelete: AppRoutes.lotEntry,

    //lot coloring
    AppRoutes.lotColorings: AppRoutes.stockDashboard,
    AppRoutes.lotColoringCreate: AppRoutes.lotColorings,
    AppRoutes.lotColoringEdit: AppRoutes.lotColorings,
    AppRoutes.lotColoringDelete: AppRoutes.lotColorings,

    //item Transactions Sub-Routes
    AppRoutes.inventoryTransaction: AppRoutes.stockDashboard,
    AppRoutes.inventoryTransactionCreate: AppRoutes.inventoryTransaction,
    AppRoutes.inventoryTransactionEdit: AppRoutes.inventoryTransaction,
    AppRoutes.inventoryTransactionDelete: AppRoutes.inventoryTransaction,

    // ==================== COMPANY MODULE ====================
    AppRoutes.companyManagement: AppRoutes.companyDashboard,
    AppRoutes.companyCreation: AppRoutes.companyManagement,
    AppRoutes.companyEdit: AppRoutes.companyManagement,
    AppRoutes.companyDelete: AppRoutes.companyManagement,
    // ==================== BRANCH MODULE ====================
    AppRoutes.branchManagement: AppRoutes.branchListDashboard,
    AppRoutes.branchCreation: AppRoutes.branchManagement,
    AppRoutes.branchEdit: AppRoutes.branchManagement,
    AppRoutes.branchDelete: AppRoutes.branchManagement,

    // ==================== PURCHASE MODULE ====================
    AppRoutes.supplierEntry: AppRoutes.purchaseDashboard,
    AppRoutes.supplierCreate: AppRoutes.supplierEntry,
    AppRoutes.supplierEdit: AppRoutes.supplierEntry,
    AppRoutes.supplierDelete: AppRoutes.supplierEntry,

    // AppRoutes.purchaseEntry: AppRoutes.purchaseDashboard,
    AppRoutes.purchaseReview: AppRoutes.purchaseDashboard,
    AppRoutes.purchaseSupplierInfo: AppRoutes.purchaseReview,
    AppRoutes.purchaseItemEntry: AppRoutes.purchaseReview,
    AppRoutes.purchaseOrderPayment: AppRoutes.purchaseReview,

    // AppRoutes.purchaseOrderReceive: AppRoutes.purchaseReview,
    AppRoutes.creditPurchaseReview: AppRoutes.purchaseDashboard,

    //===================REPORT MODULE====================
    AppRoutes.stockReport: AppRoutes.reportDashboard,
    AppRoutes.salesReport: AppRoutes.reportDashboard,
    AppRoutes.purchaseReport: AppRoutes.reportDashboard,
    AppRoutes.cashFlowReport: AppRoutes.reportDashboard,

    //===============STOCK REPORT====================
    AppRoutes.expirationReport: AppRoutes.stockReport,
    AppRoutes.upcomingExpirationReport: AppRoutes.stockReport,
    AppRoutes.dailyStockReport: AppRoutes.stockReport,
    AppRoutes.balanceOfItemEntryReport: AppRoutes.stockReport,
    AppRoutes.inventoryMovementReport: AppRoutes.stockReport,
    AppRoutes.itemCostReport: AppRoutes.stockReport,
    AppRoutes.inventoryTransactionReport: AppRoutes.stockReport,
    AppRoutes.reorderPointReport: AppRoutes.stockReport,

    //===============SALES REPORT====================
    AppRoutes.salesTransactionReport: AppRoutes.salesReport,
    AppRoutes.agedCreditSalesReport: AppRoutes.salesReport,
    AppRoutes.creditRecievedReport: AppRoutes.salesReport,

    //=================PURCHASE REPORT================
    AppRoutes.purchaseTransactionReport: AppRoutes.purchaseReport,
    AppRoutes.agedCreditPaymentReceiptReport: AppRoutes.purchaseReport,
    AppRoutes.pendingPurcahseReport: AppRoutes.purchaseReport,
    AppRoutes.goodsReceivedNote: AppRoutes.purchaseReport,
    AppRoutes.creditPaymentReport: AppRoutes.purchaseReport,

    //=================CASH FLOW REPORT================
    AppRoutes.cashFlowSummaryReport: AppRoutes.cashFlowReport,
    AppRoutes.cashInFlowReport: AppRoutes.cashFlowReport,
    AppRoutes.cashOutFlowReport: AppRoutes.cashFlowReport,
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
