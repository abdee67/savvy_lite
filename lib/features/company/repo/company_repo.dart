import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';

class CompanyRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  CompanyRepository({required this.databaseService});

  Future<List<Company>> loadCompanies(int companyId) async {
    final db = await databaseService.database;
    final companies = await db.query(
      'company_table',
      where: 'id = ?',
      whereArgs: [companyId],
    );
    return companies.map((company) => Company.fromMap(company)).toList();
  }

  Future<int> insertCompany(Company company) async {
    final db = await databaseService.database;
    final companyMap = company.toMap();
    companyMap.remove('id');

    final id = await db.insert('company_table', withSyncKey(companyMap));
    companyMap['id'] = id;
    captureSync(
      tableName: 'CompanyTable',
      entityMap: companyMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: id.toString(),
    );
    return id;
  }

  Future<int> updateCompany(Company company) async {
    final db = await databaseService.database;
    final companyMap = company.toMap();

    final result = await db.update(
      'company_table',
      companyMap,
      where: 'id = ?',
      whereArgs: [company.id],
    );
    captureSync(
      tableName: 'CompanyTable',
      entityMap: companyMap,
      entityId: company.id.toString(),
      operation: 'UPDATE',
      company: company.id?.toString(),
    );
    return result;
  }

  Future<int> deleteCompany(int companyId) async {
    final db = await databaseService.database;
    final existingCompany = await db.query(
      'company_table',
      where: 'id = ?',
      whereArgs: [companyId],
    );
    final result = await db.delete(
      'company_table',
      where: 'id = ?',
      whereArgs: [companyId],
    );
    for (final row in existingCompany) {
      captureSync(
        tableName: 'CompanyTable',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
    return result;
  }

  Future<void> deleteMultipleCompanies(List<int> companyIds) async {
    if (companyIds.isEmpty) return;

    final db = await databaseService.database;
    final placeholders = List.filled(companyIds.length, '?').join(',');
    final existingCompany = await db.query(
      'company_table',
      where: 'id IN ($placeholders)',
      whereArgs: companyIds,
    );
    await db.delete(
      'company_table',
      where: 'id IN ($placeholders)',
      whereArgs: companyIds,
    );
    for (final row in existingCompany) {
      captureSync(
        tableName: 'CompanyTable',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: row['company'].toString(),
      );
    }
  }
}
