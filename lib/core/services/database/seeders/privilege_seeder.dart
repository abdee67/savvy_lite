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

      // ==================== ADMIN MANAGEMENT ====================
      // Privilege Management
      _createPrivilege(
        'Privilege Management',
        'link',
        AppRoutes.privilegeManagement,
        'privilege_management',
      ),
      _createPrivilege(
        'Add Privilege',
        'button',
        '/admin/privilege-management/add-privilege',
        'add_privilege',
      ),
      _createPrivilege(
        'Edit Privilege',
        'button',
        '/admin/privilege-management/edit-privilege',
        'edit_privilege',
      ),
      _createPrivilege(
        'Delete Privilege',
        'button',
        '/admin/privilege-management/delete-privilege',
        'delete_privilege',
      ),

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
        '/admin/employee-management/add-employee',
        'add_employee',
      ),
      _createPrivilege(
        'Edit Employee',
        'button',
        '/admin/employee-management/edit-employee',
        'edit_employee',
      ),
      _createPrivilege(
        'Delete Employee',
        'button',
        '/admin/employee-management/delete-employee',
        'delete_employee',
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
        '/admin/user-management/add-user',
        'add_user',
      ),
      _createPrivilege(
        'Edit User',
        'button',
        '/admin/user-management/edit-user',
        'edit_user',
      ),
      _createPrivilege(
        'Delete User',
        'button',
        '/admin/user-management/delete-user',
        'delete_user',
      ),

      // ==================== SALES MODULE ====================
      // Sales Entry & Sub-features
      _createPrivilege(
        'Sales Customer Info',
        'link',
        AppRoutes.salesCustomerInfo,
        'sales_customer_info',
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
        'button',
        '/sales/customer-dashboard/add-customer',
        'add_customer',
      ),
      _createPrivilege(
        'Edit Customer',
        'button',
        '/sales/customer-dashboard/edit-customer',
        'edit_customer',
      ),
      _createPrivilege(
        'Delete Customer',
        'button',
        '/sales/customer-dashboard/delete-customer',
        'delete_customer',
      ),

      // ==================== STOCK MODULE ====================
      _createPrivilege('Item Entry', 'link', AppRoutes.itemEntry, 'item_entry'),
      _createPrivilege(
        'UoM Management',
        'link',
        AppRoutes.uomManagement,
        'uom_management',
      ),
      _createPrivilege(
        'Item Workbench',
        'link',
        AppRoutes.itemWorkbench,
        'item_workbench',
      ),
      _createPrivilege(
        'Item UoM Conversions',
        'link',
        AppRoutes.itemUomConversions,
        'item_uom_conversions',
      ),
      _createPrivilege(
        'Location Entry',
        'link',
        AppRoutes.locationEntry,
        'location_entry',
      ),
      _createPrivilege('Lot Entry', 'link', AppRoutes.lotEntry, 'lot_entry'),
      _createPrivilege(
        'Lot Colorings',
        'link',
        AppRoutes.lotColorings,
        'lot_colorings',
      ),
      _createPrivilege(
        'Inventory Transaction',
        'link',
        AppRoutes.inventoryTransaction,
        'inventory_transaction',
      ),
      _createPrivilege(
        'Item Branch Entry',
        'link',
        AppRoutes.itemBranchEntry,
        'item_branch_entry',
      ),
      _createPrivilege(
        'Barcode Function',
        'link',
        AppRoutes.barcodeFunction,
        'barcode_function',
      ),
      _createPrivilege(
        'Export Function',
        'link',
        AppRoutes.exportFunction,
        'export_function',
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
