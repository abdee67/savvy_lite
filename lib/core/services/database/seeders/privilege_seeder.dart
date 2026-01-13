import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:sqflite/sqflite.dart';

class PrivilegeSeeder {
  static Future<void> seedPrivileges(Database db) async {
    final privileges = [
      // ==================== MAIN DASHBOARDS ====================
      _createPrivilege(
        'Admin Dashboard',
        'link',
        AppRoutes.adminDashboard,
        'admin_dashboard',
      ),
      _createPrivilege(
        'Sales Dashboard',
        'link',
        AppRoutes.salesDashboard,
        'sales_dashboard',
      ),
      _createPrivilege(
        'Stock Dashboard',
        'link',
        AppRoutes.stockDashboard,
        'stock_dashboard',
      ),
      _createPrivilege(
        'Availability Dashboard',
        'link',
        AppRoutes.availabilityDashboard,
        'availability_dashboard',
      ),
      _createPrivilege(
        'Purchase Dashboard',
        'link',
        AppRoutes.purchaseDashboard,
        'purchase_dashboard',
      ),
      _createPrivilege(
        'Company Dashboard',
        'link',
        AppRoutes.companyDashboard,
        'company_dashboard',
      ),
      _createPrivilege(
        'Branch List Dashboard',
        'link',
        AppRoutes.branchListDashboard,
        'branch_list_dashboard',
      ),
      _createPrivilege(
        'Report Dashboard',
        'link',
        AppRoutes.reportDashboard,
        'report_dashboard',
      ),
      _createPrivilege(
        'FSNMR Dashboard',
        'link',
        AppRoutes.fsnmrDashboard,
        'fsnmr_dashboard',
      ),
      _createPrivilege(
        'FSNMR Management',
        'link',
        AppRoutes.fsnmrManagement,
        'fsnmr_management',
      ),
      _createPrivilege('FSNMR', 'link', AppRoutes.fsnmr, 'fsnmr'),
      _createPrivilege(
        'FSNMR Create',
        'link',
        AppRoutes.fsnmrCreate,
        'fsnmr_create',
      ),
      _createPrivilege('FSNMR Edit', 'link', AppRoutes.fsnmrEdit, 'fsnmr_edit'),

      // ==================== ADMIN MANAGEMENT ====================
      /* // Privilege Management
      _createPrivilege(
        'Privilege Management',
        'link',
        AppRoutes.privilegeManagement,
        'privilege_management',
      ),
      _createPrivilege(
        'Add Privilege',
        'button',
        AppRoutes.createPrivilege,
        'add_privilege',
      ),
      _createPrivilege(
        'Edit Privilege',
        'button',
        AppRoutes.editPrivilege,
        'edit_privilege',
      ),
      _createPrivilege(
        'Delete Privilege',
        'button',
        AppRoutes.deletePrivilege,
        'delete_privilege',
      ),*/

      // Role Management
      _createPrivilege(
        'Role Management',
        'link',
        AppRoutes.roleManagement,
        'role_management',
      ),
      _createPrivilege(
        'Add Role',
        'button',
        '/admin/role-management/add-role',
        'add_role',
      ),
      _createPrivilege(
        'Edit Role',
        'button',
        '/admin/role-management/edit-role',
        'edit_role',
      ),
      _createPrivilege(
        'Delete Role',
        'button',
        '/admin/role-management/delete-role',
        'delete_role',
      ),

      // Employee Management
      _createPrivilege(
        'Employee Management',
        'link',
        AppRoutes.employeeManagement,
        'employee_management',
      ),
      _createPrivilege(
        'Add Employee',
        'button',
        AppRoutes.employeeCreation,
        'add_employee',
      ),
      _createPrivilege(
        'Edit Employee',
        'button',
        AppRoutes.employeeEdit,
        'edit_employee',
      ),
      _createPrivilege(
        'Delete Employee',
        'button',
        AppRoutes.employeeDelete,
        'delete_employee',
      ),
      _createPrivilege(
        'Convert Employee to User',
        'button',
        AppRoutes.employeeConversionToUser,
        'convert_employee_to_user',
      ),

      // User Management
      _createPrivilege(
        'User Management',
        'link',
        AppRoutes.userManagement,
        'user_management',
      ),
      _createPrivilege(
        'Add User',
        'button',
        AppRoutes.userCreation,
        'add_user',
      ),
      _createPrivilege('Edit User', 'button', AppRoutes.userEdit, 'edit_user'),
      _createPrivilege(
        'Delete User',
        'button',
        AppRoutes.userDelete,
        'delete_user',
      ),

      // ==================== SALES MODULE ====================
      // Sales Entry & Sub-features
      _createPrivilege(
        'Sales Entry',
        'link',
        AppRoutes.salesCustomerInfo,
        'sales_entry',
      ),
      _createPrivilege(
        'Sales Item Entry',
        'link',
        AppRoutes.salesItemEntry,
        'sales_item_entry',
      ),
      _createPrivilege(
        'Payment Summary',
        'link',
        AppRoutes.paymentSummary,
        'payment_summary',
      ),
      _createPrivilege(
        'Sales Invoice',
        'link',
        AppRoutes.salesInvoice,
        'sales_invoice',
      ),

      // Customer Management
      _createPrivilege(
        'Customer Entry',
        'link',
        AppRoutes.customerEntry,
        'customer_entry',
      ),
      _createPrivilege(
        'Add Customer',
        'link',
        AppRoutes.customerCreate,
        'add_customer',
      ),
      _createPrivilege(
        'Edit Customer',
        'link',
        AppRoutes.customerEdit,
        'edit_customer',
      ),
      _createPrivilege(
        'Delete Customer',
        'button',
        AppRoutes.customerDelete,
        'delete_customer',
      ),

      //Sales Report
      _createPrivilege(
        'Sales Review',
        'link',
        AppRoutes.salesReview,
        'sales_review',
      ),
      _createPrivilege(
        'Sales Credit Receipt',
        'link',
        AppRoutes.salesCreditReceiptReview,
        'sales_credit_receipt',
      ),

      _createPrivilege(
        'Sales Return',
        'link',
        AppRoutes.salesReturn,
        'sales_return',
      ),
      _createPrivilege(
        'Quotation Order',
        'link',
        AppRoutes.quotationOrder,
        'quotation_order',
      ),
      _createPrivilege(
        'Quotation Item Entry',
        'link',
        AppRoutes.quotationItemEntry,
        'quotatio_item_entry',
      ),
      _createPrivilege(
        'Quotation Order Payment',
        'link',
        AppRoutes.quotationOrderPayment,
        'quotation_order_payment',
      ),
      _createPrivilege(
        'Quotation Invoice Review',
        'link',
        AppRoutes.quotationInvoiceReview,
        'quotation_invoice_review',
      ),
      _createPrivilege(
        'Quotation Order Review',
        'link',
        AppRoutes.quotationOrderReview,
        'quotation_report',
      ),

      // ==================== STOCK MODULE ====================
      //item entry
      _createPrivilege('Item Entry', 'link', AppRoutes.itemEntry, 'item_entry'),

      _createPrivilege(
        'Add Item',
        'button',
        AppRoutes.itemCreation,
        'add_item',
      ),
      _createPrivilege('Edit Item', 'button', AppRoutes.itemEdit, 'edit_item'),
      _createPrivilege(
        'Delete Item',
        'button',
        AppRoutes.itemDelete,
        'delete_item',
      ),

      //item in branch
      _createPrivilege(
        'Item In Branch',
        'link',
        AppRoutes.itemInBranch,
        'item_in_branch',
      ),
      _createPrivilege(
        'Add Item In Branch',
        'button',
        AppRoutes.addItemToBranch,
        'add_item_in_branch',
      ),
      _createPrivilege(
        'Edit Item In Branch',
        'button',
        AppRoutes.editItemInBranch,
        'edit_item_in_branch',
      ),
      _createPrivilege(
        'Delete Item In Branch',
        'button',
        AppRoutes.deleteItemInBranch,
        'delete_item_in_branch',
      ),

      //uom management
      _createPrivilege(
        'UoM Management',
        'link',
        AppRoutes.uomManagement,
        'uom_management',
      ),
      _createPrivilege('Add UoM', 'button', AppRoutes.uomCreation, 'add_uom'),
      _createPrivilege('Edit UoM', 'button', AppRoutes.uomEdit, 'edit_uom'),

      //item uom conversions
      _createPrivilege(
        'Item UoM Conversions',
        'link',
        AppRoutes.itemUomConversions,
        'item_uom_conversions',
      ),
      _createPrivilege(
        'Add Item UoM Conversion',
        'button',
        AppRoutes.itemUomConversionsCreate,
        'add_item_uom_conversion',
      ),
      _createPrivilege(
        'Edit Item UoM Conversion',
        'button',
        AppRoutes.itemUomConversionsEdit,
        'edit_item_uom_conversion',
      ),
      _createPrivilege(
        'Delete Item UoM Conversion',
        'button',
        AppRoutes.itemUomConversionsDelete,
        'delete_item_uom_conversion',
      ),

      //location entry
      _createPrivilege(
        'Location Entry',
        'link',
        AppRoutes.locationEntry,
        'location_entry',
      ),
      _createPrivilege(
        'Location Master Create',
        'button',
        AppRoutes.locationMasterCreate,
        'location_master_create',
      ),
      _createPrivilege(
        'Location Master Edit',
        'button',
        AppRoutes.locationMasterEdit,
        'location_master_edit',
      ),
      _createPrivilege(
        'Location Master Delete',
        'button',
        AppRoutes.locationMasterDelete,
        'location_master_delete',
      ),

      //lot entry
      _createPrivilege('Lot Entry', 'link', AppRoutes.lotEntry, 'lot_entry'),
      _createPrivilege('Add Lot', 'link', AppRoutes.lotCreation, 'add_lot'),
      _createPrivilege('Edit Lot', 'link', AppRoutes.lotEdit, 'edit_lot'),
      _createPrivilege(
        'Delete Lot',
        'button',
        AppRoutes.lotDelete,
        'delete_lot',
      ),

      //lot colorings
      _createPrivilege(
        'Lot Colorings',
        'link',
        AppRoutes.lotColorings,
        'lot_colorings',
      ),
      _createPrivilege(
        'Add Lot Colorings',
        'button',
        AppRoutes.lotColoringCreate,
        'add_lot_colorings',
      ),
      _createPrivilege(
        'Edit Lot Colorings',
        'button',
        AppRoutes.lotColoringEdit,
        'edit_lot_colorings',
      ),
      _createPrivilege(
        'Delete Lot Colorings',
        'button',
        AppRoutes.lotColoringDelete,
        'delete_lot_colorings',
      ),

      //item Transactions Sub-Routes
      _createPrivilege(
        'Inventory Transaction',
        'link',
        AppRoutes.inventoryTransaction,
        'inventory_transaction',
      ),
      _createPrivilege(
        'Create Inventory Transaction',
        'button',
        AppRoutes.inventoryTransactionCreate,
        'create_inventory_transaction',
      ),
      _createPrivilege(
        'Edit Inventory Transaction',
        'button',
        AppRoutes.inventoryTransactionEdit,
        'edit_inventory_transaction',
      ),
      _createPrivilege(
        'Delete Inventory Transaction',
        'button',
        AppRoutes.inventoryTransactionDelete,
        'delete_inventory_transaction',
      ),

      //item entry workbench
      _createPrivilege(
        'Item Entry Workbench',
        'link',
        AppRoutes.itemWorkbench,
        'item_entry_workbench',
      ),
      _createPrivilege(
        'Single Item Entry',
        'button',
        AppRoutes.itemWorkbenchSingleCreate,
        'single_item_entry',
      ),
      _createPrivilege(
        'Batch Upload',
        'button',
        AppRoutes.itemWorkbenchBatchUpload,
        'batch_upload',
      ),

      _createPrivilege(
        'Delete Item',
        'button',
        AppRoutes.itemWorkbenchDelete,
        'delete_item',
      ),

      // ==================== COMPANY MODULE ====================
      _createPrivilege(
        'Company Management',
        'link',
        AppRoutes.companyManagement,
        'company_management',
      ),
      _createPrivilege(
        'Add Company',
        'button',
        AppRoutes.companyCreation,
        'add_company',
      ),
      _createPrivilege(
        'Edit Company',
        'button',
        AppRoutes.companyEdit,
        'edit_company',
      ),
      _createPrivilege(
        'Delete Company',
        'button',
        AppRoutes.companyDelete,
        'delete_company',
      ),

      // ==================== BRANCH MODULE ====================
      _createPrivilege(
        'Branch Management',
        'link',
        AppRoutes.branchManagement,
        'branch_management',
      ),
      _createPrivilege(
        'Add Branch',
        'button',
        AppRoutes.branchCreation,
        'add_branch',
      ),
      _createPrivilege(
        'Edit Branch',
        'button',
        AppRoutes.branchEdit,
        'edit_branch',
      ),
      _createPrivilege(
        'Delete Branch',
        'button',
        AppRoutes.branchDelete,
        'delete_branch',
      ),

      // ==================== PURCHASE MODULE ====================
      _createPrivilege(
        'Supplier Entry',
        'link',
        AppRoutes.supplierEntry,
        'supplier_entry',
      ),
      _createPrivilege(
        'Add Supplier',
        'button',
        AppRoutes.supplierCreate,
        'create_supplier',
      ),
      _createPrivilege(
        'Edit Supplier',
        'button',
        AppRoutes.supplierEdit,
        'edit_supplier',
      ),
      _createPrivilege(
        'Delete Supplier',
        'button',
        AppRoutes.supplierDelete,
        'delete_supplier',
      ),
      /*  _createPrivilege(
        'Purchase Order Entry',
        'link',
        AppRoutes.purchaseEntry,
        'purchase_order_entry',
      ),*/
      _createPrivilege(
        'Purchase Order',
        'button',
        AppRoutes.purchaseReview,
        'review_purchase_order',
      ),
      _createPrivilege(
        'Supplier Info',
        'button',
        AppRoutes.purchaseSupplierInfo,
        'purchase_supplier_info',
      ),
      _createPrivilege(
        'Purchase Item Entry',
        'button',
        AppRoutes.purchaseItemEntry,
        'purchase_item_entry',
      ),
      _createPrivilege(
        'Purchase Payment',
        'button',
        AppRoutes.purchaseOrderPayment,
        'purchase_order_payment',
      ),
      _createPrivilege(
        'Purchase Receive',
        'button',
        AppRoutes.purchaseOrderReceive,
        'purchase_order_receive',
      ),
      _createPrivilege(
        'Credit Purchase',
        'button',
        AppRoutes.creditPurchaseReview,
        'review_credit_purchase_order',
      ),

      //=======================REPORT MODULE===================
      _createPrivilege(
        'Stock Report',
        'link',
        AppRoutes.stockReport,
        'stock_report',
      ),
      _createPrivilege(
        'Sales Report',
        'link',
        AppRoutes.salesReport,
        'sales_report',
      ),
      _createPrivilege(
        'Purchase Report',
        'link',
        AppRoutes.purchaseReport,
        'purchase_report',
      ),
      _createPrivilege(
        'Cash Flow Report',
        'link',
        AppRoutes.cashFlowReport,
        'cash_flow_report',
      ),

      //===============STOCK REPORTS==========
      _createPrivilege(
        'Expiration Report',
        'link',
        AppRoutes.expirationReport,
        'expiration_report',
      ),
      _createPrivilege(
        'Daily Stock Report',
        'link',
        AppRoutes.dailyStockReport,
        'daily_stock_report',
      ),
      _createPrivilege(
        'Upcoming Expiration',
        'link',
        AppRoutes.upcomingExpirationReport,
        'upcoming_expiration_report',
      ),
      _createPrivilege(
        'Balance of Item Entry',
        'link',
        AppRoutes.balanceOfItemEntryReport,
        'balance_of_item_entry_report',
      ),
      _createPrivilege(
        'Inventory Movement ',
        'link',
        AppRoutes.inventoryMovementReport,
        'inventory_movement_report',
      ),
      _createPrivilege(
        'Item Cost ',
        'link',
        AppRoutes.itemCostReport,
        'item_cost_report',
      ),
      _createPrivilege(
        'Inventory Transaction ',
        'link',
        AppRoutes.inventoryTransactionReport,
        'inventory_transaction_report',
      ),
      _createPrivilege(
        'Reorder Point ',
        'link',
        AppRoutes.reorderPointReport,
        'reorder_point_report',
      ),

      //===============SALES REPORT============
      _createPrivilege(
        'Sales Transaction',
        'link',
        AppRoutes.salesTransactionReport,
        'sales_trnasaction_report',
      ),
      _createPrivilege(
        'Aged Credit Sales',
        'link',
        AppRoutes.agedCreditSalesReport,
        'aged_credit_sales_report',
      ),
      _createPrivilege(
        'Credit Received',
        'link',
        AppRoutes.creditRecievedReport,
        'credit_received_report',
      ),

      //===================PURCHASE REPORT===========================
      _createPrivilege(
        'Purchase Transaction',
        'link',
        AppRoutes.purchaseTransactionReport,
        'purchase_trnasaction_report',
      ),
      _createPrivilege(
        'Aged Credit Payment',
        'link',
        AppRoutes.agedCreditPaymentReceiptReport,
        'aged_credit_payment_report',
      ),
      _createPrivilege(
        'Credit Payment',
        'link',
        AppRoutes.creditPaymentReport,
        'credit_payment_report',
      ),
      _createPrivilege(
        'Pending Purchase',
        'link',
        AppRoutes.pendingPurcahseReport,
        'pending_purchase_report',
      ),
      _createPrivilege(
        'Goods Recieved Note',
        'link',
        AppRoutes.goodsReceivedNote,
        'goods_received_note',
      ),
      //===============CASHFLOW REPORT===========
      _createPrivilege(
        'CashFlow Summary',
        'link',
        AppRoutes.cashFlowSummaryReport,
        'cash_flow_summary_report',
      ),
      _createPrivilege(
        'Cash In Flow',
        'link',
        AppRoutes.cashInFlowReport,
        'cash_in_flow_report',
      ),
      _createPrivilege(
        'Cash Out Flow',
        'link',
        AppRoutes.cashOutFlowReport,
        'cash_out_flow_report',
      ),
      _createPrivilege(
        'License',
        'link',
        AppRoutes.licenseDetails,
        'license_details',
      ),
    ];

    for (final privilege in privileges) {
      final fullPrivilege = {
        ...privilege,
        'description': privilege['name']!,
        'created_by': '1',
        'date_created': DateTime.now().toIso8601String(),
        'vendor_only': 'N',
        'updated_by': '1',
        'date_updated': DateTime.now().toIso8601String(),
      };

      await db.insert('privilege_table', fullPrivilege);
    }
  }

  static Map<String, dynamic> _createPrivilege(
    String name,
    String type,
    String link,
    String label,
  ) {
    return {
      'name': name,
      'type': type,
      'link': link,
      type == 'link' ? 'link_lable' : 'button_lable': label,
    };
  }
}
