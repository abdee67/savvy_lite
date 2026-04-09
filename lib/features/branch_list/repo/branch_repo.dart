import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:sqflite/sqflite.dart';

class BranchRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  BranchRepository({required this.databaseService});

  Future<List<Branch>> loadBranches(int companyId) async {
    final db = await databaseService.database;
    final branches = await db.query(
      'branch_table',
      where: 'company = ?',
      whereArgs: [companyId],
    );
    return branches.map((branch) => Branch.fromMap(branch)).toList();
  }

  Future<int> countBranches() async {
    final db = await databaseService.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM branch_table'),
        ) ??
        0;
  }

  Future<int> insertBranch(Branch branch, int companyId) async {
    final db = await databaseService.database;
    final branchMap = branch.toMap();
    branchMap.remove('id');
    branchMap['company'] = companyId;

    final id = await db.insert('branch_table', withSyncKey(branchMap));
    branchMap['id'] = id;
    captureSync(
      tableName: 'BranchTable',
      entityMap: branchMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: companyId.toString(),
    );
    return id;
  }

  Future<int> updateBranch(Branch branch, int companyId) async {
    final db = await databaseService.database;
    final branchMap = branch.toMap()..['company'] = companyId;

    final result = await db.update(
      'branch_table',
      branchMap,
      where: 'id = ? AND company = ?',
      whereArgs: [branch.id, companyId],
    );
    captureSync(
      tableName: 'BranchTable',
      entityMap: branchMap,
      entityId: branch.id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  Future<int> deleteBranch(int branchId, int companyId) async {
    final db = await databaseService.database;
    final existingBranch = await db.query(
      'branch_table',
      where: 'id = ? AND company = ?',
      whereArgs: [branchId, companyId],
    );
    final result = await db.delete(
      'branch_table',
      where: 'id = ? AND company = ?',
      whereArgs: [branchId, companyId],
    );
    for(final row in existingBranch){
    captureSync(
      tableName: 'BranchTable',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    }
    return result;
  }

  Future<void> deleteMultipleBranches(List<int> branchIds, int companyId) async {
    if (branchIds.isEmpty) return;

    final db = await databaseService.database;
    final placeholders = List.filled(branchIds.length, '?').join(',');
    final whereArgs = [...branchIds, companyId];

    await db.delete(
      'branch_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );
  }
}
