import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/errors/unauthorized_screen.dart';
import 'package:savvy_stock/core/widgets/route_guard.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/employees/screens/employee_dashboard.dart';
import 'package:savvy_stock/features/admin/employees/widgets/emloyee_create_and_edit.dart.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/privilege/screens/privilege_dahsboard.dart';
import 'package:savvy_stock/features/admin/privilege/widgets/privilege_form.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/role/screens/role_dashboard.dart';
import 'package:savvy_stock/features/admin/role/widgets/role_form.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/admin/users/screens/user_dashboard.dart';
import 'package:savvy_stock/features/admin/users/widgets/user_creat_edit.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/auth/screens/login_screen.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/branch_list/screens/branch_list_dashboard.dart';
import 'package:savvy_stock/features/branch_list/widgets/branch_list_create_and_edit.dart.dart';
import 'package:savvy_stock/features/dashboards/screens/home_page.dart';
import 'package:savvy_stock/features/onboarding/screens/welcome_screen.dart';
import 'package:savvy_stock/features/onboarding/widgets/getStarted.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/credit_purchase/credit_purchase_review.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_item_entry/screens/purchase_item_entry.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_payment/screens/payment_screen.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_review.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/screens/supplier_info_screen.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/screens/supplier_list.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/widget/supplier_create_edit.dart';
import 'package:savvy_stock/features/reports/stock_report/dashboard/stock_report_dashboard.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/balance_of_item.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/expiration_report.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/inventory_movement.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/inventory_transaction.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/item_cost_report.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/reorder_point_report.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/upcoming_expiration.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/customer/screens/customer_list.dart';
import 'package:savvy_stock/features/sales/customer/screens/sales_customer_screen.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_create_edit.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quotation_review.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_customer_screen/quote_customer_entry.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_invoice_screen/quote_invoice_review_screen.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_item_entry_screen/quote_item_entry.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_payment_screen/quote_payment_screen.dart';
import 'package:savvy_stock/features/sales/sales_order/header/credit_receipt/sales_credit_receipt_reveiw.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/screens/invoice_review_screen.dart';
import 'package:savvy_stock/features/sales/sales_order/payment/screens/payment_screen.dart';
import 'package:savvy_stock/features/sales/sales_order/sales_item_entry/screens/sales_item_entry.dart';
import 'package:savvy_stock/features/sales/sales_order/sales_report.dart';
import 'package:savvy_stock/features/sales/sales_return/screens/sales_return_screen.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/models/item_uom_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/screens/item_uom_conversion_dashboard.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/widgets/item_uom_conversion_create_and_edit.dart.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/screens/item_entry_dashboard.dart';
import 'package:savvy_stock/features/stock/item_entry/widgets/item_entry_create_and_edit.dart.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/screens/item_master_create.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/widgets/batch_upload_section.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/widgets/single_item_entry_form.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/screens/item_in_branch_dashboard.dart';
import 'package:savvy_stock/features/stock/item_in_branch/widgets/item_in_branch_create_and_edit.dart.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/screens/item_transaction_dashboard.dart';
import 'package:savvy_stock/features/stock/item_transactions/widgets/item_tansaction_form.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/stock/location_entry/screens/location_master_screen.dart';
import 'package:savvy_stock/features/stock/location_entry/screens/location_master_create_edit.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/screens/lot_colorings_screen.dart';
import 'package:savvy_stock/features/stock/lot_coloring/widgets/lot_coloring_form.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/screens/lot_master_dashboard.dart';
import 'package:savvy_stock/features/stock/lot_master/widgets/lot_master_create_and_edit.dart.dart';
import 'package:savvy_stock/features/system_constant/screen/system_constants_screen.dart';

// Import your screen files for missing routes
// import 'package:savvy_stock/features/sales/sales_entry/screens/sales_entry_screen.dart';
// import 'package:savvy_stock/features/sales/sales_dashboard/screens/sales_dashboard.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthBloc authBloc;
  final UserBloc userBloc;
  final bool showOnboarding;
  AppRouter({
    required this.showOnboarding,
    required this.authBloc,
    required this.userBloc,
  });

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: showOnboarding ? AppRoutes.welcome : AppRoutes.authCheck,
    routes: [
      // Auth Routes
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.authCheck,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        redirect: (context, state) => _authRedirect(context, state),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
        redirect: (context, state) => _loginRedirect(context, state),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const GetStart(),
      ),

      // Main Dashboard
      GoRoute(
        path: AppRoutes.homePage,
        builder: (context, state) => const HomePage(),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      // Sales Routes
      GoRoute(
        path: AppRoutes.customerEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.customerEntry,
          parentPrivilege: AppRoutes.salesDashboard,
          child: CustomerListPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.customerCreate,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.customerCreate,
          parentPrivilege: AppRoutes.customerEntry,
          child: CustomerCreateEdit(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.customerEdit,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final customer = extra != null
              ? extra['customer'] as Customer?
              : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.customerEdit,
            parentPrivilege: AppRoutes.customerEntry,
            child: CustomerCreateEdit(authBloc: authBloc, customer: customer),
          );
        },
        redirect: _protectedRouteRedirect,
      ),

      GoRoute(
        path: AppRoutes.salesCustomerInfo,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesCustomerInfo,
          parentPrivilege: AppRoutes.salesDashboard,
          child: CustomerInfoScreen(
            authBloc: authBloc,
            extra: state.extra as Map<String, dynamic>?,
          ),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesItemEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesItemEntry,
          parentPrivilege: AppRoutes.salesCustomerInfo,
          child: ItemEntryScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesReview,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesReview,
          parentPrivilege: AppRoutes.salesDashboard,
          child: SalesReviewPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesCreditReceiptReview,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesCreditReceiptReview,
          parentPrivilege: AppRoutes.salesDashboard,
          child: CreditSalesReviewPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),

      GoRoute(
        path: AppRoutes.paymentSummary,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.paymentSummary,
          parentPrivilege: AppRoutes.salesCustomerInfo,
          child: PaymentScreen(
            authBloc: authBloc,
            orderData: state.extra as Map<String, dynamic>?,
          ),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesInvoice,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesInvoice,
          parentPrivilege: AppRoutes.salesCustomerInfo,
          child: InvoiceReviewScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesReturn,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesReturn,
          parentPrivilege: AppRoutes.salesDashboard,
          child: SalesReturnScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Quotation Order
      GoRoute(
        path: AppRoutes.quotationOrder,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.quotationOrder,
          parentPrivilege: AppRoutes.salesDashboard,
          child: QuotationCustomerInfoScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.quotationItemEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.quotationItemEntry,
          parentPrivilege: AppRoutes.quotationOrder,
          child: QuotationItemEntryScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.quotationOrderPayment,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.quotationOrderPayment,
          parentPrivilege: AppRoutes.quotationOrder,
          child: QuotePaymentScreen(
            authBloc: authBloc,
            orderData: state.extra as Map<String, dynamic>?,
          ),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.quotationInvoiceReview,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.quotationInvoiceReview,
          parentPrivilege: AppRoutes.quotationOrder,
          child: QuotationInvoiceReviewScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.quotationOrderReview,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.quotationOrderReview,
          parentPrivilege: AppRoutes.salesDashboard,
          child: QuotationReviewPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      // Admin Routes
      GoRoute(
        path: AppRoutes.roleManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.roleManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: RoleDashboard(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.roleCreation,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.roleCreation,
          parentPrivilege: AppRoutes.roleManagement,
          child: RoleFormScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.roleEdit,
        builder: (context, state) {
          final extra = state.extra;
          final role = extra != null ? extra as Role : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.roleEdit,
            parentPrivilege: AppRoutes.roleManagement,
            child: RoleFormScreen(role: role, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.privilegeManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.privilegeManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: PrivilegeManagementScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.editPrivilege,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final privilege = extra != null
              ? extra['privilege'] as Privilege?
              : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.editPrivilege,
            parentPrivilege: AppRoutes.privilegeManagement,
            child: PrivilegeForm(privilege: privilege),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.createPrivilege,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.createPrivilege,
          parentPrivilege: AppRoutes.privilegeManagement,
          child: PrivilegeForm(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.userManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: UserDashboard(authBloc: authBloc, userBloc: userBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.userCreation,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.userCreation,
          parentPrivilege: AppRoutes.userManagement,
          child: UserManagementScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.userEdit,
        builder: (context, state) {
          final extra = state.extra;
          UserWithRole? userWithRole;

          // Handle both UserModel and UserWithRole cases
          if (extra is UserWithRole) {
            userWithRole = extra;
          } else if (extra is UserModel) {
            // If only UserModel is passed, create a basic UserWithRole
            userWithRole = UserWithRole(user: extra, roles: []);
          }
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.userEdit,
            parentPrivilege: AppRoutes.userManagement,
            child: UserManagementScreen(user: userWithRole, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),

      GoRoute(
        path: AppRoutes.employeeManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.employeeManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: EmployeeListPage(authBloc: authBloc, userBloc: userBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.employeeConversionToUser,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final employee = extra != null
              ? extra['employee'] as Employee?
              : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.employeeConversionToUser,
            parentPrivilege: AppRoutes.employeeManagement,
            child: UserManagementScreen(employee: employee, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.employeeEdit,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final employee = extra != null
              ? extra['employee'] as Employee?
              : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.employeeEdit,
            parentPrivilege: AppRoutes.employeeManagement,
            child: EmployeeFormPage(employee: employee, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.employeeCreation,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.employeeCreation,
            parentPrivilege: AppRoutes.employeeManagement,
            child: EmployeeFormPage(authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.employeeDelete,
        builder: (context, state) {
          final extra = state.extra;
          final employee = extra != null ? extra as Employee? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.employeeDelete,
            parentPrivilege: AppRoutes.employeeManagement,
            child: EmployeeFormPage(employee: employee, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      //  =======Stock Routes=======
      // Item Entry
      GoRoute(
        path: AppRoutes.itemEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.itemEntry,
          parentPrivilege: AppRoutes.stockDashboard,
          child: ItemEntryDashboard(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemCreation,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.itemCreation,
          parentPrivilege: AppRoutes.itemEntry,
          child: ItemEntryFormPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemEdit,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as ItemEntryModel? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemEdit,
            parentPrivilege: AppRoutes.itemEntry,
            child: ItemEntryFormPage(item: item, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemDelete,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as ItemEntryModel? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemDelete,
            parentPrivilege: AppRoutes.itemEntry,
            child: ItemEntryFormPage(item: item, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      // Item In Branch
      GoRoute(
        path: AppRoutes.itemInBranch,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.itemInBranch,
          parentPrivilege: AppRoutes.stockDashboard,
          child: ItemInBranchDashboard(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.addItemToBranch,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final item = extra != null ? extra['item'] as ItemEntryModel? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.addItemToBranch,
            parentPrivilege: AppRoutes.itemInBranch,
            child: ItemInBranchFormPage(itemEntry: item, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.editItemInBranch,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as ItemInBranchModel? : null;
          // final itemEntry = extra != null ? extra as ItemEntryModel? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.editItemInBranch,
            parentPrivilege: AppRoutes.itemInBranch,
            child: ItemInBranchFormPage(item: item, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemDelete,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as ItemInBranchModel? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemDelete,
            parentPrivilege: AppRoutes.itemInBranch,
            child: ItemInBranchFormPage(item: item, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      // UOM Conversion
      GoRoute(
        path: AppRoutes.itemUomConversions,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.itemUomConversions,
          parentPrivilege: AppRoutes.stockDashboard,
          child: ItemUomConversionListScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemUomConversionsCreate,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemUomConversionsCreate,
            parentPrivilege: AppRoutes.itemInBranch,
            child: ItemUomConversionForm(authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemUomConversionsEdit,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as ItemUomConversion? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemUomConversionsEdit,
            parentPrivilege: AppRoutes.itemUomConversions,
            child: ItemUomConversionForm(editingItem: item, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      //location entry
      GoRoute(
        path: AppRoutes.locationEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.locationEntry,
          parentPrivilege: AppRoutes.stockDashboard,
          child: LocationMasterListPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.locationMasterCreate,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.locationMasterCreate,
            parentPrivilege: AppRoutes.locationEntry,
            child: LocationMasterCreatePage(
              authBloc: authBloc,
              isEditMode: false,
            ),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.locationMasterEdit,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as LocationMaster? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.locationMasterEdit,
            parentPrivilege: AppRoutes.locationEntry,
            child: LocationMasterCreatePage(
              authBloc: authBloc,
              editingLocation: item,
              isEditMode: true,
            ),
          );
        },
        redirect: _protectedRouteRedirect,
      ),

      //lot entry
      GoRoute(
        path: AppRoutes.lotEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.lotEntry,
          parentPrivilege: AppRoutes.stockDashboard,
          child: LotMasterDashboard(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.lotCreation,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.lotCreation,
            parentPrivilege: AppRoutes.lotEntry,
            child: LotMasterFormPage(authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.lotEdit,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as LotMaster? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.lotEdit,
            parentPrivilege: AppRoutes.lotEntry,
            child: LotMasterFormPage(authBloc: authBloc, lot: item),
          );
        },
        redirect: _protectedRouteRedirect,
      ),

      //lot colorings
      GoRoute(
        path: AppRoutes.lotColorings,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.lotColorings,
          parentPrivilege: AppRoutes.stockDashboard,
          child: LotExpirationColorsDashboard(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.lotColoringCreate,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.lotColoringCreate,
            parentPrivilege: AppRoutes.lotColorings,
            child: LotExpirationColorsFormPage(authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.lotColoringEdit,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as LotExpirationColor? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.lotColoringEdit,
            parentPrivilege: AppRoutes.lotColorings,
            child: LotExpirationColorsFormPage(
              authBloc: authBloc,
              existingColoring: item,
            ),
          );
        },
        redirect: _protectedRouteRedirect,
      ),

      //item Transactions Sub-Routes
      GoRoute(
        path: AppRoutes.inventoryTransaction,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.inventoryTransaction,
          parentPrivilege: AppRoutes.stockDashboard,
          child: ItemTransactionsListPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),

      GoRoute(
        path: AppRoutes.inventoryTransactionCreate,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.inventoryTransaction,
            parentPrivilege: AppRoutes.lotColorings,
            child: ItemTransactionsFormPage(authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.inventoryTransactionEdit,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra != null ? extra as ItemTransactionModel? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.inventoryTransaction,
            parentPrivilege: AppRoutes.lotColorings,
            child: ItemTransactionsFormPage(
              authBloc: authBloc,
              existingTransaction: item,
            ),
          );
        },
        redirect: _protectedRouteRedirect,
      ),

      //item master sub routes
      GoRoute(
        path: AppRoutes.itemWorkbench,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.itemWorkbench,
          parentPrivilege: AppRoutes.stockDashboard,
          child: ItemMasterCreatePage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemWorkbenchSingleCreate,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemWorkbenchSingleCreate,
            parentPrivilege: AppRoutes.itemWorkbench,
            child: SingleItemEntryForm(authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.itemWorkbenchBatchUpload,
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.itemWorkbenchBatchUpload,
            parentPrivilege: AppRoutes.itemWorkbench,
            child: BatchUploadSection(),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.branchManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.branchManagement,
          parentPrivilege: AppRoutes.branchListDashboard,
          child: BranchDashboard(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.branchCreation,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.branchCreation,
          parentPrivilege: AppRoutes.branchManagement,
          child: BranchFormPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.branchEdit,
        builder: (context, state) {
          final extra = state.extra;
          final branch = extra != null ? extra as Branch? : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.branchEdit,
            parentPrivilege: AppRoutes.branchManagement,
            child: BranchFormPage(branch: branch, authBloc: authBloc),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      // Purchase Routes
      GoRoute(
        path: AppRoutes.supplierEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.supplierEntry,
          parentPrivilege: AppRoutes.purchaseDashboard,
          child: SupplierListPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.supplierCreate,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.supplierCreate,
          parentPrivilege: AppRoutes.supplierEntry,
          child: SupplierEntryScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.supplierEdit,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final supplier = extra != null
              ? extra['supplier'] as SupplierModel?
              : null;
          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.supplierEdit,
            parentPrivilege: AppRoutes.supplierEntry,
            child: SupplierEntryScreen(authBloc: authBloc, supplier: supplier),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.purchaseReview,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.purchaseReview,
          parentPrivilege: AppRoutes.purchaseDashboard,
          child: PurchaseReviewPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.purchaseSupplierInfo,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.purchaseSupplierInfo,
          parentPrivilege: AppRoutes.purchaseReview,
          child: SupplierInfoScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.purchaseItemEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.purchaseItemEntry,
          parentPrivilege: AppRoutes.purchaseSupplierInfo,
          child: PurchaseItemEntryScreen(
            orderData: state.extra as Map<String, dynamic>,
          ),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.purchaseOrderPayment,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.purchaseOrderPayment,
          parentPrivilege: AppRoutes.purchaseItemEntry,
          child: PurchasePaymentScreen(
            orderData: state.extra as Map<String, dynamic>,
          ),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.creditPurchaseReview,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.creditPurchaseReview,
          parentPrivilege: AppRoutes.purchaseDashboard,
          child: CreditPurchaseReviewPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //===================REPORT ROUTES===================
      //====================STOCK REPORT ROUTS=======================
      GoRoute(
        path: AppRoutes.stockReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.stockReport,
          parentPrivilege: AppRoutes.reportDashboard,
          child: StockReportDashboard(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Expiration Report
      GoRoute(
        path: AppRoutes.expirationReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.expirationReport,
          parentPrivilege: AppRoutes.stockReport,
          child: ExpirationReportPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Upcoming Expiration Report
      GoRoute(
        path: AppRoutes.upcomingExpirationReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.upcomingExpirationReport,
          parentPrivilege: AppRoutes.stockReport,
          child: UpcomingupcomingExpiryPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Balance of Item Report
      GoRoute(
        path: AppRoutes.balanceOfItemEntryReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.balanceOfItemEntryReport,
          parentPrivilege: AppRoutes.stockReport,
          child: BalanceOfItemReport(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Inventory Movement Report
      GoRoute(
        path: AppRoutes.inventoryMovementReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.inventoryMovementReport,
          parentPrivilege: AppRoutes.stockReport,
          child: InventoryMovementReport(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Item Cost Report
      GoRoute(
        path: AppRoutes.itemCostReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.itemCostReport,
          parentPrivilege: AppRoutes.stockReport,
          child: ItemCostReportPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Inventory Transaction Report
      GoRoute(
        path: AppRoutes.inventoryTransactionReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.inventoryTransactionReport,
          parentPrivilege: AppRoutes.stockReport,
          child: InventoryTransactionReport(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      //Reorder Point Report
      GoRoute(
        path: AppRoutes.reorderPointReport,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.reorderPointReport,
          parentPrivilege: AppRoutes.stockReport,
          child: ReorderPointReport(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      // System Constants
      GoRoute(
        path: AppRoutes.systemConstants,
        builder: (context, state) => SystemConstantsScreen(authBloc: authBloc),
      ),

      // Unauthorized
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.homePage),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );

  // Redirect logic (same as before)
  String? _authRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) return null;

    if (authState.status == AuthStatus.authenticated) {
      final intended = state.uri.queryParameters['redirect'];
      return intended ?? AppRoutes.homePage;
    }
    return AppRoutes.login;
  }

  String? _loginRedirect(BuildContext context, GoRouterState state) {
    if (authBloc.state.status == AuthStatus.authenticated) {
      return AppRoutes.homePage;
    }
    return null;
  }

  String? _protectedRouteRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) return AppRoutes.authCheck;

    if (authState.status != AuthStatus.authenticated) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    return null;
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic state) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
