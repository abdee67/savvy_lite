import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
import 'package:sqflite/sqflite.dart';

class UdcRepository extends BaseRepository {
  final String baseUrl;
  @override
  final LocalDatabaseService databaseService;
  final http.Client httpClient;

  UdcRepository({
    required this.baseUrl,
    required this.databaseService,
    required this.httpClient,
  });

  // Get UDC details by code (offline-first)
  Future<List<UdcDetails>> getUdcDetailsByCode(
    String detailCode,
    String headerCode,
  ) async {
    try {
      return await getLocalUdcDetailsByCode(detailCode, headerCode);
    } catch (e) {
      developer.log('Unexpected error, trying local database: $e');
      return await getLocalUdcDetailsByCode(detailCode, headerCode);
    }
  }

  // Get UDC details by header code (offline-first)
  Future<List<UdcDetails>> getUdcDetailsByHeaderCode(String headerCode) async {
    try {
      return await getLocalUdcDetailsByHeaderCode(headerCode);
    } catch (e) {
      return await getLocalUdcDetailsByHeaderCode(headerCode);
    }
  }

  Future<int?> getUdcDetailIdByHeaderCode(String detailCode) async {
    try {
      final db = await databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'udc_details',
        where: 'detail_code = ?',
        whereArgs: [detailCode],
      );
      developer.log('Found ${maps.length} UDC details for code: $detailCode');
      return maps.map((map) => UdcDetails.fromJson(map)).toList().first.id;
    } catch (e) {
      developer.log('Error getting local UDC details: $e');
      return null;
    }
  }

  Future<UdcDetails?> getUdcDetailById(int? id, {Transaction? txn}) async {
    if (id == null) return null;
    try {
      final db = txn ?? await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT * FROM udc_details 
      WHERE id = ?
    ''',
        [id],
      );

      return result.isNotEmpty ? UdcDetails.fromJson(result.first) : null;
    } catch (e) {
      developer.log('Error getting local UDC detail: $e');
      return null;
    }
  }

  // Local database operations
  Future<List<UdcDetails>> getLocalUdcDetailsByCode(
    String detailCode,
    String headerCode, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT udc_details.* 
        FROM udc_details 
        INNER JOIN udc_header ON udc_details.record_header = udc_header.id 
        WHERE udc_details.detail_code = ? AND udc_header.udc_code = ?
        ''',
        [detailCode, headerCode],
      );
      developer.log('Found ${maps.length} UDC details for code: $detailCode');
      return maps.map((map) => UdcDetails.fromJson(map)).toList();
    } catch (e) {
      developer.log('Error getting local UDC details: $e');
      return [];
    }
  }

  //get single udc detail by code
  Future<UdcDetails?> getSingleUdcDetailsByCode(
    String detailCode,
    String headerCode, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT udc_details.* 
        FROM udc_details 
        INNER JOIN udc_header ON udc_details.record_header = udc_header.id 
        WHERE udc_details.detail_code = ? AND udc_header.udc_code = ?
        ''',
        [detailCode, headerCode],
      );
      developer.log('Found ${maps.length} UDC details for code: $detailCode');
      return maps.map((map) => UdcDetails.fromJson(map)).toList().first;
    } catch (e) {
      developer.log('Error getting local UDC details: $e');
      return null;
    }
  }

  Future<int?> getUdcDetailId(
    String headerCode,
    String detailCode, {
    Transaction? txn,
  }) async {
    try {
      final db = txn ?? await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT ud.id FROM udc_details ud
      JOIN udc_header uh ON ud.record_header = uh.id
      WHERE uh.udc_code = ? AND ud.detail_code = ?
      ''',
        [headerCode, detailCode],
      );

      if (result.isNotEmpty) {
        return result.first['id'] as int?;
      }

      if (kDebugMode) {
        developer.log(
          '❌ No UDC found for header: $headerCode, detail: $detailCode',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error getting UDC detail ID: $e');
      }
      return null;
    }
  }

  Future<List<UdcDetails>> getLocalUdcDetailsByHeaderCode(
    String headerCode,
  ) async {
    final db = await databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT udc_details.* 
        FROM udc_details 
        INNER JOIN udc_header ON udc_details.record_header = udc_header.id 
        WHERE udc_header.udc_code = ?
      ''',
        [headerCode],
      );
      return maps.map((map) => UdcDetails.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save UOM entry (matching Java logic)
  Future<void> saveUomEntry(UdcDetails detail) async {
    final db = await databaseService.database;
    try {
      final headerId = await getRecordHeaderId('UM');
      if (headerId == null) {
        throw Exception('UdcHeader with code UM not found');
      }

      final map = detail.toDatabaseMap();
      // Ensure these are always set for UOM
      map['record_header'] = headerId;
      map['udc_group'] = 'UM';

      if (detail.id == 0) {
        // If it's a new record
        map.remove('id'); // ID is autoincrement
        final id = await db.insert('udc_details', withSyncKey(map));
        map['id'] = id;
        captureSync(
          tableName: 'udc_details',
          entityMap: map,
          entityId: id.toString(),
          operation: 'INSERT',
        );
      } else {
        await db.update(
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
      }
    } catch (e) {
      developer.log('Error saving UOM entry: $e');
      rethrow;
    }
  }

  //get record header id
  Future<int?> getRecordHeaderId(String headerCode) async {
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT uh.id FROM udc_header uh
      WHERE uh.udc_code = ?
      ''',
        [headerCode],
      );

      if (result.isNotEmpty) {
        return result.first['id'] as int?;
      }

      if (kDebugMode) {
        developer.log('❌ No UDC header found for code: $headerCode');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error getting UDC header ID: $e');
      }
      return null;
    }
  }
}
