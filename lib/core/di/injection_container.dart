import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/sync/sync_receiver.dart';
import 'package:savvy_stock/core/services/sync/sync_repository.dart';
import 'package:savvy_stock/core/services/sync/sync_sender.dart';
import 'package:savvy_stock/core/services/sync/sync_service.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_bloc.dart';
import 'package:savvy_stock/features/FSNMR/repo/FSNMR_repository.dart';
import 'package:savvy_stock/features/admin/employees/repo/employees_repo.dart';
import 'package:savvy_stock/features/auth/repo/auth_repo.dart';
import 'package:savvy_stock/features/admin/users/repo/user_repo.dart';
import 'package:savvy_stock/features/admin/privilege/repo/privilege_repo.dart';
import 'package:savvy_stock/features/admin/role/repo/role_repo.dart';
import 'package:savvy_stock/features/auth/blocs/password_reset/password_reset_bloc.dart';
import 'package:savvy_stock/features/company/blocs/company_bloc.dart';
import 'package:savvy_stock/features/company/repo/company_repo.dart';
import 'package:savvy_stock/features/licensing/bloc/license_bloc.dart';
import 'package:savvy_stock/features/licensing/services/license_service.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/repos/purchase_order_report_repo.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/repos/purchase_order_repository.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/services/purchase_order_stock_service.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/repo/supplier_repo.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:savvy_stock/features/registration/services/registration_service.dart';
import 'package:savvy_stock/features/sales/customer/repo/customer_repo.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/repo/quotation_order_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/header/repo/sales_order_report_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/bloc/invoice_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/repo/invoice_detail_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/repo/invoice_header_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/service/sales_order_integration_service.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/service/validate_stock_availability.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_bloc.dart';
import 'package:savvy_stock/features/sales/sales_return/repos/sales_return_repository.dart';
import 'package:savvy_stock/features/sales/sales_return/services/sales_return_stock_service.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';
import 'package:savvy_stock/features/stock/pricing/services/pricing_service.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_repository.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/repo/branch_repo.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/next_number/repo/next_number_repo.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/repo/item_master_repo.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/repo/migration_service.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/repo/location_master_repository.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/repo/sales_order_detail_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_bloc.dart';
import 'package:savvy_stock/features/reports/cash_flow/repo/cash_flow_repo.dart';
import 'package:savvy_stock/features/purchase/other_expenses/bloc/other_expenses_bloc.dart';
import 'package:savvy_stock/features/purchase/other_expenses/repo/other_expense_repository.dart';
import 'package:savvy_stock/features/auth/services/password_reset_service.dart';
import 'package:savvy_stock/features/auth/services/remote_auth_service.dart';
import 'package:savvy_stock/features/auth/services/initial_data_sync_service.dart';
import 'package:savvy_stock/features/udc_detail/repo/udc_detail_repo.dart';

final getIt = GetIt.instance;

void initDependencies() {
  // Secure Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<DeviceInfoPlugin>(() => DeviceInfoPlugin());

  // HTTP Client
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Database Service
  getIt.registerLazySingleton<LocalDatabaseService>(
    () => LocalDatabaseService(),
  );

  // Connectivity Service
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // ─── Sync Services ─────────────────────────────────────────────────
  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SyncSender>(
    () => SyncSender(httpClient: getIt()),
  );
  getIt.registerLazySingleton<SyncReceiver>(
    () => SyncReceiver(httpClient: getIt()),
  );
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      syncRepository: getIt(),
      syncSender: getIt(),
      syncReceiver: getIt(),
      connectivityService: getIt(),
      databaseService: getIt(),
    ),
  );

  // Repositories
  // Repository (with auth service dependency)
  getIt.registerLazySingleton<SystemConstantRepository>(
    () => SystemConstantRepository(
      baseUrl: ApiConstants.baseUrl,
      databaseService: getIt(),
      httpClient: getIt(),
      authBloc: getIt(), // Pass auth service
      udcRepository: getIt(),
    ),
  );

  // UDC Repository
  getIt.registerLazySingleton<UdcRepository>(
    () => UdcRepository(
      baseUrl: ApiConstants.baseUrl,
      databaseService: getIt(),
      httpClient: getIt(),
    ),
  );

  // Services
  getIt.registerLazySingleton<SystemConstantsService>(
    () => SystemConstantsService(getIt()),
  );

  getIt.registerLazySingleton<StockItemsEntryRepository>(
    () => StockItemsEntryRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<ItemLocationsRepository>(
    () => ItemLocationsRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<LotMasterRepository>(
    () => LotMasterRepository(
      udcRepository: getIt(),
      systemConstantBloc: getIt(),
      databaseService: getIt(),
    ),
  );
  getIt.registerLazySingleton<ItemMasterRepository>(
    () => ItemMasterRepository(databaseService: getIt()),
  );

  getIt.registerLazySingleton<ItemUomConversionsRepository>(
    () => ItemUomConversionsRepository(databaseService: getIt()),
  );

  getIt.registerLazySingleton<ItemCostRepository>(
    () => ItemCostRepository(
      databaseService: getIt(),
      uomConversionRepository: getIt(),
    ),
  );
  getIt.registerLazySingleton<StockItemInBranchRepository>(
    () => StockItemInBranchRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<ItemTransactionRepository>(
    () => ItemTransactionRepository(
      authBloc: getIt(),
      lotMasterRepository: getIt(),
      itemInBranchRepository: getIt(),
      itemLocationsRepository: getIt(),
      locationMasterRepository: getIt(),
      itemUomConversionBloc: getIt(),
      itemUomConversionRepository: getIt(),
      itemCostRepository: getIt(),
      udcDetailsController: getIt(),
      systemConstantBloc: getIt(),
      nextNumberRepository: getIt(),
      databaseService: getIt(),
    ),
  );

  getIt.registerLazySingleton<MigrationService>(
    () => MigrationService(
      authBloc: getIt(),
      itemsEntryRepository: getIt(),
      locationMasterRepository: getIt(),
      itemsInBranchRepository: getIt(),
      itemLocationsRepository: getIt(),
      lotMasterRepository: getIt(),
      itemCostRepository: getIt(),
      itemMasterRepository: getIt(),
      udcRepository: getIt(),
      nextNumberRepository: getIt(),
      systemConstantBloc: getIt(),
      databaseService: getIt(),
      itemUomConversionsRepository: getIt(),
      itemTransactionRepository: getIt(),
    ),
  );
  getIt.registerLazySingleton<LocationMasterRepository>(
    () => LocationMasterRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<NextNumberRepository>(
    () => NextNumberRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<BranchRepository>(
    () => BranchRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<CompanyRepository>(
    () => CompanyRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<PrivilegeRepository>(
    () => PrivilegeRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<RoleRepository>(
    () => RoleRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<LotExpirationColorsRepository>(
    () => LotExpirationColorsRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SalesOrderHeaderRepository>(
    () => SalesOrderHeaderRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SalesOrderDetailRepository>(
    () => SalesOrderDetailRepository(
      databaseService: getIt(),
      authBloc: getIt(),
      itemEntryRepository: getIt(),
      itemInBranchRepository: getIt(),
      lotMasterRepository: getIt(),
      udcDetailsRepository: getIt(),
    ),
  );
  getIt.registerLazySingleton<SalesOrderIntegrationService>(
    () => SalesOrderIntegrationService(
      headerBloc: getIt(),
      detailBloc: getIt(),
      authBloc: getIt(),
      invoiceHeaderBloc: getIt(),
      invoiceDetailBloc: getIt(),
    ),
  );
  getIt.registerLazySingleton<ValidateStockAvailabilityService>(
    () => ValidateStockAvailabilityService(
      lotMasterRepository: getIt(),
      itemLocationsRepository: getIt(),
      itemTransactionsRepository: getIt(),
      itemUomConversionsRepository: getIt(),
      stockItemInBranchRepository: getIt(),
      systemConstantBloc: getIt(),
      udcRepository: getIt(),
      expirationColorsRepository: getIt(),
    ),
  );

  getIt.registerLazySingleton<InvoiceHistoryHeaderRepository>(
    () => InvoiceHistoryHeaderRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<InvoiceHistoryDetailRepository>(
    () => InvoiceHistoryDetailRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SalesReturnRepository>(
    () => SalesReturnRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SalesReturnStockService>(
    () => SalesReturnStockService(
      itemLocationsRepository: getIt(),
      udcRepository: getIt(),
      itemUomConversionsRepository: getIt(),
      itemTransactionsRepository: getIt(),
      itemsInBranchRepository: getIt(),
      salesOrderDetailRepository: getIt(),
      salesOrderHeaderRepository: getIt(),
      salesReturnRepository: getIt(),
      systemConstantBloc: getIt(),
      lotMasterRepository: getIt(),
    ),
  );
  getIt.registerLazySingleton<QuotationOrderRepository>(
    () => QuotationOrderRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(databaseService: getIt()),
  );
  getIt.registerLazySingleton<PurchaseOrderRepository>(
    () => PurchaseOrderRepository(
      databaseService: getIt(),
      udcRepository: getIt(),
    ),
  );
  getIt.registerLazySingleton<UdcDetailRepo>(
    () => UdcDetailRepo(databaseService: getIt()),
  );
  getIt.registerLazySingleton<PurchaseOrderStockService>(
    () => PurchaseOrderStockService(
      itemLocationsRepository: getIt(),
      udcRepository: getIt(),
      itemUomConversionsRepository: getIt(),
      itemTransactionsRepository: getIt(),
      systemConstantBloc: getIt(),
      lotMasterRepository: getIt(),
      stockItemInBranchRepository: getIt(),
      expirationColorsRepository: getIt(),
    ),
  );
  getIt.registerLazySingleton<PurchaseOrderReportRepository>(
    () => PurchaseOrderReportRepository(),
  );
  getIt.registerLazySingleton<SalesOrderReportRepository>(
    () => SalesOrderReportRepository(),
  );
  getIt.registerLazySingleton<CashFlowRepository>(() => CashFlowRepository());

  getIt.registerLazySingleton<FSNMRRepository>(
    () => FSNMRRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<RegistrationService>(
    () => RegistrationService(databaseService: getIt(), httpClient: getIt()),
  );
  getIt.registerLazySingleton<LicenseService>(
    () => LicenseService(secureStorage: getIt(), deviceInfoPlugin: getIt()),
  );
  getIt.registerLazySingleton<PasswordResetService>(
    () => PasswordResetService(databaseService: getIt()),
  );
  getIt.registerLazySingleton<RemoteAuthService>(
    () => RemoteAuthService(httpClient: getIt(), authRepository: getIt()),
  );
  getIt.registerLazySingleton<InitialDataSyncService>(
    () => InitialDataSyncService(
      authRepository: getIt(),
      syncService: getIt(),
      httpClient: getIt(),
    ),
  );
  getIt.registerLazySingleton<PricingService>(
    () => PricingService(
      databaseService: getIt(),
      uomConversionRepository: getIt(),
      systemConstantService: getIt(),
      lotMasterRepository: getIt(),
    ),
  );
  ///////////// BLoCs///////////////

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      repository: getIt(),
      secureStorage: getIt(),
      licenseService: getIt(),
      initialDataSyncService: getIt(),
      connectivityService: getIt(),
    ),
  );
  getIt.registerLazySingleton<UserBloc>(
    () => UserBloc(
      repository: getIt(),
      authBloc: getIt(),
      licenseService: getIt(),
    ),
  );
  getIt.registerLazySingleton<EmployeeBloc>(
    () => EmployeeBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerLazySingleton<PrivilegeBloc>(
    () => PrivilegeBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerLazySingleton<RoleBloc>(
    () => RoleBloc(repository: getIt(), authBloc: getIt()),
  );

  // System constants should be shared across the app. Register as a singleton so
  // all blocs/services that depend on it use the same instance.
  getIt.registerLazySingleton<SystemConstantBloc>(
    () => SystemConstantBloc(
      systemConstantRepository: getIt(),
      authBloc: getIt(),
      systemConstantService: getIt(),
    ),
  );

  getIt.registerFactory<BranchBloc>(
    () => BranchBloc(
      repository: getIt(),
      authBloc: getIt(),
      licenseService: getIt(),
    ),
  );

  getIt.registerFactory<StockItemsEntryBloc>(
    () => StockItemsEntryBloc(
      repository: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      itemsInBranchBloc: getIt(),
    ),
  );

  getIt.registerFactory<StockItemInBranchBloc>(
    () => StockItemInBranchBloc(
      authBloc: getIt(),
      repository: getIt(),
      systemConstantBloc: getIt(),
      itemTransactionsRepository: getIt(),
      lotMasterBloc: getIt(),
      itemUomConversionsRepo: getIt(),
      itemCostRepository: getIt(),
    ),
  );

  getIt.registerFactory<ItemUomConversionBloc>(
    () => ItemUomConversionBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<UdcDetailsBloc>(
    () => UdcDetailsBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<LocationMasterBloc>(
    () => LocationMasterBloc(
      authBloc: getIt(),
      locationMasterRepository: getIt(),
    ),
  );
  getIt.registerFactory<StockItemLocationBloc>(
    () => StockItemLocationBloc(
      repository: getIt(),
      itemCostRepository: getIt(),
      authBloc: getIt(),
      uomConversionsRepository: getIt(),
      itemInBranchRepository: getIt(),
    ),
  );
  getIt.registerFactory<NextNumberBloc>(
    () => NextNumberBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<LotMasterBloc>(
    () => LotMasterBloc(
      repository: getIt(),
      udcRepository: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      nextNumberBloc: getIt(),
      lotExpirationColorsBloc: getIt(),
    ),
  );
  getIt.registerFactory<LotExpirationColorsBloc>(
    () => LotExpirationColorsBloc(
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      repository: getIt(),
    ),
  );
  getIt.registerFactory<ItemCostBloc>(
    () => ItemCostBloc(
      systemConstantController: getIt(),
      itemsInBranchController: getIt(),
      itemUomConversionsController: getIt(),
      repository: getIt(),
      authBloc: getIt(),
    ),
  );
  getIt.registerFactory<SalesOrderDetailBloc>(
    () => SalesOrderDetailBloc(
      headerBloc: getIt(),
      itemCostRepository: getIt(),
      repository: getIt(),
      lotMasterRepository: getIt(),
      udcDetailsRepository: getIt(),
      validateStockAvailabilityService: getIt(),
      itemUOMConversionsRepository: getIt(),
      itemsInBranchRepository: getIt(),
      itemsTableRepository: getIt(),
      salesOrderHeaderRepository: getIt(),
      systemConstantBloc: getIt(),
      authBloc: getIt(),
    ),
  );
  getIt.registerFactory<SalesOrderHeaderBloc>(
    () => SalesOrderHeaderBloc(
      customerRepository: getIt(),
      employeesRepository: getIt(),
      udcDetailRepository: getIt(),
      repository: getIt(),
      systemConstantBloc: getIt(),
      authBloc: getIt(),
      uomConversionsRepository: getIt(),
      itemInBranchRepository: getIt(),
      salesOrderReportRepository: getIt(),
    ),
  );
  getIt.registerFactory<CustomerBloc>(
    () => CustomerBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<ItemTransactionsBloc>(
    () => ItemTransactionsBloc(
      repository: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      udcRepository: getIt(),
      nextNumberBloc: getIt(),
      salesOrderHeaderController: getIt(),
      itemsTableController: getIt(),
    ),
  );

  getIt.registerFactory<ItemMasterBloc>(
    () => ItemMasterBloc(
      repository: getIt(),
      migrationService: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      itemsEntryBloc: getIt(),
      locationMasterBloc: getIt(),
      itemsInBranchBloc: getIt(),
      itemLocationsBloc: getIt(),
      lotMasterBloc: getIt(),
      itemCostBloc: getIt(),
      udcDetailsBloc: getIt(),
      nextNumberBloc: getIt(),
    ),
  );
  getIt.registerFactory<InvoiceHistoryHeaderBloc>(
    () => InvoiceHistoryHeaderBloc(
      repository: getIt(),
      authBloc: getIt(),
      udcRepository: getIt(),
    ),
  );
  getIt.registerFactory<InvoiceHistoryDetailBloc>(
    () => InvoiceHistoryDetailBloc(
      repository: getIt(),
      authBloc: getIt(),
      headerBloc: getIt(),
    ),
  );
  getIt.registerFactory<SalesOrderCoordinatorBloc>(
    () => SalesOrderCoordinatorBloc(
      headerBloc: getIt(),
      detailBloc: getIt(),
      authBloc: getIt(),
      invoiceHeaderBloc: getIt(),
      invoiceDetailBloc: getIt(),
      systemConstantBloc: getIt(),
      quotationRepo: getIt(),
      itemCostRepository: getIt(),
    ),
  );
  getIt.registerFactory<SalesReturnBloc>(
    () => SalesReturnBloc(
      repository: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      salesOrderHeaderRepository: getIt(),
      salesReturnStockService: getIt(),
    ),
  );
  getIt.registerFactory<QuotationOrderBloc>(
    () => QuotationOrderBloc(
      repository: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      customerRepository: getIt(),
      uomConversionsRepository: getIt(),
      itemInBranchRepository: getIt(),
      invoiceDetailBloc: getIt(),
      invoiceDetailRepository: getIt(),
      invoiceHeaderBloc: getIt(),
      invoiceHeaderRepository: getIt(),
      udcRepository: getIt(),
      itemCostRepository: getIt(),
    ),
  );
  // Purchase
  getIt.registerFactory<SupplierBloc>(
    () => SupplierBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<PurchaseOrderBloc>(
    () => PurchaseOrderBloc(
      repository: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
      udcRepository: getIt(),
      nextNumberRepository: getIt(),
      stockService: getIt(),
      itemsTableRepository: getIt(),
      itemCostsRepository: getIt(),
      supplierRepository: getIt(),
      purchaseOrderReportRepository: getIt(),
      pricingService: getIt(),
    ),
  );

  // Cash Flow
  getIt.registerFactory<CashFlowBloc>(
    () => CashFlowBloc(authBloc: getIt(), cashFlowRepository: getIt()),
  );
  getIt.registerFactory<CompanyBloc>(
    () => CompanyBloc(authBloc: getIt(), repository: getIt()),
  );

  // FSNMR
  getIt.registerFactory<FSNMRBloc>(
    () => FSNMRBloc(authBloc: getIt(), repository: getIt()),
  );
  getIt.registerLazySingleton<RegistrationBloc>(
    () =>
        RegistrationBloc(registrationService: getIt(), secureStorage: getIt()),
  );
  getIt.registerLazySingleton<LicenseBloc>(
    () => LicenseBloc(licenseService: getIt()),
  );

  // Other Expenses
  getIt.registerLazySingleton<OtherExpenseRepository>(
    () => OtherExpenseRepository(databaseService: getIt()),
  );
  getIt.registerFactory<OtherExpensesBloc>(
    () => OtherExpensesBloc(
      repository: getIt(),
      authBloc: getIt(),
      itemCostBloc: getIt(),
      itemInBranchBloc: getIt(),
      systemConstantBloc: getIt(),
      itemEntryBloc: getIt(),
    ),
  );

  // Password Reset

  getIt.registerFactory<PasswordResetBloc>(
    () => PasswordResetBloc(passwordResetService: getIt()),
  );
}
