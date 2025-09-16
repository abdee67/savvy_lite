import 'package:get_it/get_it.dart';
import 'package:savvy_stock/features/sales/repositories/sales_repository.dart';

final getIt = GetIt.instance;

void initDependencies() {
  // Blocs

  // Repositories
  getIt.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl());

  // Other dependencies...
}
