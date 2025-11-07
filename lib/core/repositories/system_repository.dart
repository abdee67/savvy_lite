import 'package:dartz/dartz.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import '../errors/failures.dart';

abstract class SystemRepository {
  // Basic CRUD operations
  Future<Either<Failure, SystemConstant>> createSystemConstant(
    SystemConstant systemConstant,
  );
  Future<Either<Failure, SystemConstant>> updateSystemConstant(
    SystemConstant systemConstant,
  );
  Future<Either<Failure, void>> deleteSystemConstant(int id);
  Future<Either<Failure, void>> deleteSystemConstants(List<int> ids);

  // Query operations
  Future<Either<Failure, List<SystemConstant>>> getSystemConstants({
    required bool isSuperUser,
    required int companyId,
  });
  Future<Either<Failure, List<SystemConstant>>> getSystemConstantsForCompany(
    int companyId,
  );
  Future<Either<Failure, SystemConstant>> getSystemConstant(int id);

  // Bulk operations
  Future<Either<Failure, void>> createSystemConstants(
    List<SystemConstant> systemConstants,
  );
  Future<Either<Failure, void>> updateSystemConstants(
    List<SystemConstant> systemConstants,
  );

  // Utility methods
  Future<Either<Failure, List<Map<String, dynamic>>>> getLotTypes();
  Future<Either<Failure, bool>> validateRates(SystemConstant systemConstant);
}
