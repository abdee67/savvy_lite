import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/features/stock/item_UoM_conversions/repo/item_uom_conv_repo.dart';
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
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/next_number/repo/next_number_repo.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/blocs/item_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/repo/item_master_repo.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/repo/migration_service.dart';
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
import 'package:savvy_stock/features/stock/sales_order_detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/repo/sales_order_detail_repo.dart';
import 'package:savvy_stock/features/stock/sales_order_header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/stock/sales_order_header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';

final getIt = GetIt.instance;

void initDependencies() {
  // Secure Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => FlutterSecureStorage(),
  );

  // HTTP Client
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Database Service
  getIt.registerLazySingleton<LocalDatabaseService>(
    () => LocalDatabaseService(),
  );

  // Repositories
  // Repository (with auth service dependency)
  getIt.registerLazySingleton<SystemConstantRepository>(
    () => SystemConstantRepository(
      baseUrl: ApiConstants.baseUrl,
      localDatabaseService: getIt(),
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
  getIt.registerLazySingleton<SalesOrderDetailRepository>(
    () => SalesOrderDetailRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<SalesOrderHeaderRepository>(
    () => SalesOrderHeaderRepository(),
  );
  getIt.registerLazySingleton<ItemLocationsRepository>(
    () => ItemLocationsRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<LotMasterRepository>(
    () => LotMasterRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<ItemMasterRepository>(
    () => ItemMasterRepository(databaseService: getIt()),
  );

  getIt.registerLazySingleton<ItemUomConversionsRepository>(
    () => ItemUomConversionsRepository(databaseService: getIt()),
  );

  getIt.registerLazySingleton<ItemCostRepository>(
    () => ItemCostRepository(databaseService: getIt()),
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
      itemUomConversionBloc: getIt(),
      itemUomConversionRepository: getIt(),
      itemCostRepository: getIt(),
      udcDetailsController: getIt(),
      systemConstantBloc: getIt(),
      nextNumberBloc: getIt(),
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
    ),
  );
  getIt.registerLazySingleton<LocationMasterRepository>(
    () => LocationMasterRepository(databaseService: getIt()),
  );
  getIt.registerLazySingleton<NextNumberRepository>(
    () => NextNumberRepository(databaseService: getIt()),
  );
  // BLoCs

  getIt.registerFactory<PaymentBloc>(() => PaymentBloc(getIt()));

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(databaseService: getIt(), secureStorage: getIt()),
  );
  getIt.registerLazySingleton<UserBloc>(
    () => UserBloc(databaseService: getIt(), authBloc: getIt()),
  );
  getIt.registerLazySingleton<EmployeeBloc>(
    () => EmployeeBloc(databaseService: getIt(), authBloc: getIt()),
  );
  getIt.registerLazySingleton<PrivilegeBloc>(
    () => PrivilegeBloc(databaseService: getIt(), authBloc: getIt()),
  );
  getIt.registerLazySingleton<RoleBloc>(
    () => RoleBloc(databaseService: getIt(), authBloc: getIt()),
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
    () => BranchBloc(databaseService: getIt(), authBloc: getIt()),
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
      //  itemCostBloc: getIt(),
      itemTransactionsRepository: getIt(),
      lotMasterBloc: getIt(),
      itemUomConversionsBloc: getIt(),
    ),
  );

  getIt.registerFactory<ItemUomConversionBloc>(
    () => ItemUomConversionBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<UdcDetailsBloc>(
    () => UdcDetailsBloc(databaseService: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<LocationMasterBloc>(
    () => LocationMasterBloc(
      authBloc: getIt(),
      locationMasterRepository: getIt(),
    ),
  );
  getIt.registerFactory<StockItemLocationBloc>(
    () => StockItemLocationBloc(repository: getIt(), authBloc: getIt()),
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
      databaseService: getIt(),
      authBloc: getIt(),
      systemConstantBloc: getIt(),
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
      repository: getIt(),
      invoiceHeaderRepository: getIt(),
      itemBranchRepository: getIt(),
      itemCostTableRepository: getIt(),
      itemUomConversionsRepository: getIt(),
      headerRepository: getIt(),
      lotExpirationColorsRepository: getIt(),
      lotMasterRepository: getIt(),
      nextNumberRepository: getIt(),
      udcDetailsRepository: getIt(),
      customerTableRepository: getIt(),
    ),
  );
  getIt.registerFactory<InvoiceBloc>(() => InvoiceBloc());
  getIt.registerFactory<SalesOrderHeaderBloc>(
    () => SalesOrderHeaderBloc(repository: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<CustomerBloc>(
    () => CustomerBloc(databaseService: getIt(), authBloc: getIt()),
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
}
