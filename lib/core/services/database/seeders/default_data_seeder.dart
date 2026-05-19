import 'dart:developer' as developer;

import 'package:savvy_stock/core/constants/server_seed_data.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class DefaultDataSeeder extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  DefaultDataSeeder({required this.databaseService});

  Future<void> insertDefaultData(Database db) async {
    developer.log('Inserting default data...');

    final batch = db.batch();

    for (final udcHeader in serverUdcHeaderSeedData) {
      batch.insert(
        'udc_header',
        Map<String, Object?>.from(udcHeader),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final udcDetail in serverUdcDetailSeedData) {
      batch.insert(
        'udc_details',
        Map<String, Object?>.from(udcDetail),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final privilege in serverPrivilegeSeedData) {
      batch.insert(
        'previlage_table',
        Map<String, Object?>.from(privilege),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      /*captureSync(
        tableName: 'previlage_table',
        entityMap: Map<String, Object?>.from(privilege),
        entityId: privilege['id'].toString(),
        operation: 'insert',
        company: 
      );*/
    }

    await batch.commit(noResult: true);
    developer.log(
      'Seeded ${serverUdcHeaderSeedData.length} UDC headers, '
      '${serverUdcDetailSeedData.length} UDC details, and '
      '${serverPrivilegeSeedData.length} privileges from server data',
    );

    final urlPayload = withSyncKey({
      'config_key': 'server_url',
      'config_value': 'https://f274-196-190-62-197.ngrok-free.app/stock',
      'environment': 'production',
      'active': 'Y',
    });

    await db.insert(
      'system_url_config',
      urlPayload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    developer.log(
      'Seeded default system_url_config: ${urlPayload['config_value']}',
    );

    developer.log(
      'Database initialized. User registration will create company data.',
    );
  }
}
