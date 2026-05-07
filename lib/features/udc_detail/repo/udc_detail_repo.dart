import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
import 'package:sqflite/sqflite.dart';

class UdcDetailRepo extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  UdcDetailRepo({required this.databaseService});

  // Get record header id
  Future<int?> getRecordHeaderId(String headerCode) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      'SELECT id FROM udc_header WHERE udc_code = ?',
      [headerCode],
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    }
    return null;
  }

  Future<List<UdcDetails>> findByGroup(String groupCode) async {
    final db = await databaseService.database;
    final results = await db.rawQuery(
      '''
      SELECT d.*,
       h.id as header_id,
       h.udc_code as udc_code,
       h.udc_description as udc_description,
       h.sync_key as sync_key
      FROM udc_details d
      LEFT JOIN udc_header h ON d.record_header = h.id
      WHERE h.udc_code = ?
      ORDER BY d.id ASC
      ''',
      [groupCode],
    );
    return results.map((r) => UdcDetails.fromJson(r)).toList();
  }

  Future<List<UdcDetails>> findAll() async {
    final db = await databaseService.database;
    final results = await db.rawQuery('''
      SELECT d.*,
       h.udc_code as udc_code,
       h.udc_description as udc_description,
       h.sync_key as sync_key
      FROM udc_details d
      LEFT JOIN udc_header h ON d.record_header = h.id
      ORDER BY d.id ASC
    ''');
    return results.map((r) => UdcDetails.fromJson(r)).toList();
  }

  Future<int> create(UdcDetails detail, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final map = detail.toDatabaseMap();
    map.remove('id');
    
    final id = await db.insert('udc_details', withSyncKey(map));
    map['id'] = id;
    
    captureSync(
      tableName: 'udc_details',
      entityMap: map,
      entityId: id.toString(),
      operation: 'INSERT',
    );
    return id;
  }

  Future<int> update(UdcDetails detail, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final map = detail.toDatabaseMap();
    
    final result = await db.update(
      'udc_details',
      map,
      where: 'id = ?',
      whereArgs: [detail.id],
    );
    
    captureSync(
      tableName: 'udc_details',
      entityMap: map,
      entityId: detail.id.toString(),
      operation: 'UPDATE',
    );
    return result;
  }

  Future<void> deleteMultiple(List<int> ids, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    
    // Fetch rows before deletion for sync
    final rows = await db.query(
      'udc_details',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    
    await db.delete(
      'udc_details',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    
    for (final row in rows) {
      captureSync(
        tableName: 'udc_details',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
      );
    }
  }
}