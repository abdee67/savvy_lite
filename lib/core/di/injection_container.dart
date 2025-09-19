import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/core/repositories/system_constant_repository.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/auth/auth_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/system_constant/system_constant_service.dart';
import 'package:savvy_stock/core/services/udc_service.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/repositories/sales_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final client = http.Client();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  getIt.registerLazySingleton<http.Client>(() => client);
  // Blocs

  // Repositories
  getIt.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl());

  // Repository
  getIt.registerLazySingleton<SystemConstantRepository>(
    () => SystemConstantRepository(localDatabaseService: getIt()),
  );

  getIt.registerLazySingleton<LocalDatabaseService>(
    () => LocalDatabaseService(),
  );

  getIt.registerLazySingleton<AuthService>(() => AuthService(prefs, client));

  // BLoCs
  getIt.registerFactory<SystemConstantBloc>(
    () => SystemConstantBloc(
      systemConstantRepository: getIt(),
      authService: getIt(),
      udcService: getIt(),
    ),
  );

  getIt.registerLazySingleton<UdcService>(() => UdcService(getIt()));

  getIt.registerLazySingleton<UdcRepository>(
    () => UdcRepository(
      baseUrl: ApiConstants.baseUrl,
      localDatabaseService: getIt(),
      httpClient: getIt(),
    ),
  );

  getIt.registerLazySingleton<SystemConstantsService>(
    () => SystemConstantsService(getIt()),
  );

  getIt.registerFactory<PaymentBloc>(() => PaymentBloc(getIt()));
  // HTTP Client
  // Other dependencies...
}
