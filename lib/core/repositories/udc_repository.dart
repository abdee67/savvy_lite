import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/models/udc_details.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../errors/exceptions.dart';

class UdcRepository {
  final String baseUrl;
  final LocalDatabaseService localDatabaseService;
  final http.Client httpClient;

  UdcRepository({
    required this.baseUrl,
    required this.localDatabaseService,
    required this.httpClient,
  });

  // Get UDC details by code (offline-first)
  Future<List<UdcDetails>> getUdcDetailsByCode(String detailCode) async {
    try {
      return await getLocalUdcDetailsByCode(detailCode);
    } catch (e) {
      developer.log('Unexpected error, trying local database: $e');
      return await getLocalUdcDetailsByCode(detailCode);
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

  // Local database operations
  Future<List<UdcDetails>> getLocalUdcDetailsByCode(String detailCode) async {
    final db = await localDatabaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'udc_details',
        where: 'detail_code = ?',
        whereArgs: [detailCode],
      );
      developer.log('Found ${maps.length} UDC details for code: $detailCode');
      return maps.map((map) => UdcDetails.fromJson(map)).toList();
    } catch (e) {
      developer.log('Error getting local UDC details: $e');
      return [];
    }
  }

  Future<List<UdcDetails>> getLocalUdcDetailsByHeaderCode(
    String headerCode,
  ) async {
    final db = await localDatabaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT udc_details.* 
        FROM udc_details 
        INNER JOIN udc_header ON udc_details.record_header = udc_header.id 
        WHERE udc_header.header_code = ?
      ''',
        [headerCode],
      );
      return maps.map((map) => UdcDetails.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper methods
  Future<void> _saveUdcDetailsToLocal(List<UdcDetails> details) async {
    final db = await localDatabaseService.database;
    final batch = db.batch();

    for (final detail in details) {
      batch.insert(
        'udc_details',
        detail.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
    developer.log('Saved ${details.length} UDC details to local database');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> _getAuthToken() async {
    // Implement your auth token retrieval logic
    return 'your-auth-token';
  }
}
