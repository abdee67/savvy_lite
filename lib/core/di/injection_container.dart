import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/core/repositories/system_constant_repository.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/system_constant/system_constant_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';

final getIt = GetIt.instance;

void initDependencies() {
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

  // Repository (with auth service dependency)
  getIt.registerLazySingleton<SystemConstantRepository>(
    () => SystemConstantRepository(
      baseUrl: ApiConstants.baseUrl,
      localDatabaseService: getIt(),
      httpClient: getIt(),
      authBloc: getIt(), // Pass auth service
    ),
  );

  // UDC Repository
  getIt.registerLazySingleton<UdcRepository>(
    () => UdcRepository(
      baseUrl: ApiConstants.baseUrl,
      localDatabaseService: getIt(),
      httpClient: getIt(),
    ),
  );

  // Services
  getIt.registerLazySingleton<SystemConstantsService>(
    () => SystemConstantsService(getIt()),
  );

  // BLoCs
  getIt.registerFactory<SystemConstantBloc>(
    () => SystemConstantBloc(
      systemConstantRepository: getIt(),
      authBloc: getIt(),
      systemConstantService: getIt(),
    ),
  );

  getIt.registerFactory<BranchBloc>(
    () => BranchBloc(databaseService: getIt(), authBloc: getIt()),
  );

  getIt.registerFactory<StockItemEntryBloc>(
    () => StockItemEntryBloc(databaseService: getIt(), authBloc: getIt()),
  );

  getIt.registerFactory<StockItemInBranchBloc>(
    () => StockItemInBranchBloc(databaseService: getIt(), authBloc: getIt()),
  );

  getIt.registerFactory<ItemUomConversionBloc>(
    () => ItemUomConversionBloc(databaseService: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<UdcDetailsBloc>(
    () => UdcDetailsBloc(databaseService: getIt(), authBloc: getIt()),
  );
  getIt.registerFactory<LocationMasterBloc>(
    () => LocationMasterBloc(databaseService: getIt(), authBloc: getIt()),
  );
}
