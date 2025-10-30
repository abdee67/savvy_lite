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
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/customer/screens/customer_list.dart';
import 'package:savvy_stock/features/sales/customer/screens/customer_screen.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_create_edit.dart';
import 'package:savvy_stock/features/sales/invoice/screens/invoice_review_screen.dart';
import 'package:savvy_stock/features/sales/payment/screens/payment_screen.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/screens/item_UoM_conversion_dashboard.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/widgets/item_UoM_conversion_create_and_edit.dart.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/screens/item_entry_dashboard.dart';
import 'package:savvy_stock/features/stock/item_entry/widgets/item_entry_create_and_edit.dart.dart';
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
          child: CustomerInfoScreen(authBloc: authBloc),
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
        path: AppRoutes.paymentSummary,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;

          if (args == null ||
              args['confirmedItems'] == null ||
              args['totalAmount'] == null ||
              args['customer'] == null) {
            return Scaffold(
              body: Center(child: Text('Missing payment arguments')),
            );
          }

          return PrivilegeRouteGuard(
            requiredPrivilege: AppRoutes.paymentSummary,
            parentPrivilege: AppRoutes.salesCustomerInfo,
            child: PaymentScreen(
              confirmedItems: args['confirmedItems'] as List<ConfirmedItem>,
              totalAmount: args['totalAmount'] as double,
              customer: args['customer'] as Customer,
              authBloc: authBloc,
            ),
          );
        },
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
