// features/next_number/repositories/next_number_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/next_number/model/next_number_model.dart';
import 'package:sqflite/sqflite.dart';

class NextNumberRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  NextNumberRepository({required this.databaseService});

  // Get all next numbers for a company
  Future<List<NextNumberModel>> getNextNumbers(
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final nextNumbers = await db.rawQuery(
      '''
      SELECT * FROM next_number 
      WHERE company = ? 
      ORDER BY next_number_code
      ''',
      [companyId],
    );
    return nextNumbers.map((p) => NextNumberModel.fromMap(p)).toList();
  }

  // Get next number by ID
  Future<NextNumberModel?> getNextNumberById(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final nextNumbers = await db.query(
      'next_number',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    return nextNumbers.isNotEmpty
        ? NextNumberModel.fromMap(nextNumbers.first)
        : null;
  }

  // Get next number by code
  Future<NextNumberModel?> getNextNumberByCode(
    String code,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final nextNumbers = await db.rawQuery(
      '''
      SELECT * FROM next_number 
      WHERE company = ? AND next_number_code = ?
      ''',
      [companyId, code],
    );
    return nextNumbers.isNotEmpty
        ? NextNumberModel.fromMap(nextNumbers.first)
        : null;
  }

  // Create new next number
  Future<int> createNextNumber(NextNumberModel item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove ID for new insertion
    final id = await db.insert('next_number', itemMap);
    itemMap['id'] = id;
    captureSync(
      tableName: 'next_number',
      entityMap: itemMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: item.company?.toString(),
    );
    return id;
  }

  // Update existing next number
  Future<int> updateNextNumber(NextNumberModel item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.update(
      'next_number',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
    captureSync(
      tableName: 'next_number',
      entityMap: item.toMap(),
      entityId: item.id.toString(),
      operation: 'UPDATE',
      company: item.company?.toString(),
    );
    return result;
  }

  // Delete next number
  Future<int> deleteNextNumber(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final result = await db.delete(
      'next_number',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    captureSync(
      tableName: 'next_number',
      entityMap: {'id': id, 'company': companyId},
      entityId: id.toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    return result;
  }

  // Generate next number for a code
  Future<int> generateNextNumber(
    String code,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // Find the next number record for this code and company
    final nextNumberRecords = await db.rawQuery(
      '''
      SELECT * FROM next_number 
      WHERE company = ? AND next_number_code = ?
      ''',
      [companyId, code],
    );

    int nextNumber;
    NextNumberModel? recordToUpdate;

    if (nextNumberRecords.isEmpty) {
      // No record found, start from 1
      nextNumber = 1;

      // Create a new record starting from 2
      final newRecord = NextNumberModel(
        nextNumberCode: code,
        nextNumberDescription: _getDescriptionForCode(code),
        nextNumber: 2,
        company: companyId,
      );

      await db.insert('next_number', newRecord.toMap());
    } else {
      // Record found, get current number and increment
      recordToUpdate = NextNumberModel.fromMap(nextNumberRecords.first);
      nextNumber = recordToUpdate.nextNumber!;

      if (recordToUpdate.nextNumber == null) {
        nextNumber = 1;
        recordToUpdate = recordToUpdate.copyWith(nextNumber: 2);
      } else {
        nextNumber = recordToUpdate.nextNumber!;
        recordToUpdate = recordToUpdate.copyWith(nextNumber: nextNumber + 1);
      }

      // Update the record with next number
      await db.update(
        'next_number',
        recordToUpdate.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [recordToUpdate.id, companyId],
      );
    }

    return nextNumber;
  }

  // Generate formatted number (like "LM000001")
  Future<String> generateFormattedNumber(
    String code,
    int companyId, {
    Transaction? txn,
  }) async {
    final number = await generateNextNumber(code, companyId, txn: txn);
    return _formatNumber(code, number);
  }

  // Get default next numbers (company IS NULL)
  Future<List<NextNumberModel>> getDefaultNextNumbers({
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final defaultNextNumbers = await db.rawQuery('''
      SELECT * FROM next_number 
      WHERE company IS NULL
      ORDER BY next_number_code
      ''');
    return defaultNextNumbers.map((p) => NextNumberModel.fromMap(p)).toList();
  }

  // Copy default next numbers to a company
  Future<void> copyDefaultNextNumbersToCompany(
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final defaultNumbers = await getDefaultNextNumbers(txn: txn);

    final batch = db.batch();

    for (final defaultNumber in defaultNumbers) {
      final companyNumber = defaultNumber.copyWith(
        id: null,
        company: companyId,
      );
      batch.insert('next_number', companyNumber.toMap());
    }

    await batch.commit();
  }

  // Check if code already exists
  Future<bool> checkCodeExists(
    String code,
    int companyId, {
    int? excludeId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    final whereClause = excludeId != null
        ? 'company = ? AND next_number_code = ? AND id != ?'
        : 'company = ? AND next_number_code = ?';

    final whereArgs = excludeId != null
        ? [companyId, code, excludeId]
        : [companyId, code];

    final existing = await db.query(
      'next_number',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return existing.isNotEmpty;
  }

  // Get next number summary
  Future<Map<String, int>> getNextNumberSummary(
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT next_number_code, next_number 
      FROM next_number 
      WHERE company = ?
      ''',
      [companyId],
    );

    final summary = <String, int>{};
    for (final row in result) {
      summary[row['next_number_code'] as String] = row['next_number'] as int;
    }
    return summary;
  }

  // Helper methods
  String _getDescriptionForCode(String code) {
    final descriptions = {
      'LM': 'Lot Master',
      'PO': 'Purchase Order',
      'SO': 'Sales Order',
      'GR': 'Goods Receipt',
      'GI': 'Goods Issue',
      'TR': 'Transfer',
      'AD': 'Adjustment',
      'TN': 'Transaction Number',
      'IN': 'Invoice Number',
      'CN': 'Credit Note',
      'DN': 'Debit Note',
      'RN': 'Return Note',
      'SR': 'Sales Return',
      'PR': 'Purchase Return',
      'WO': 'Work Order',
      'MO': 'Manufacturing Order',
      'QC': 'Quality Control',
      'ST': 'Stock Transfer',
      'RT': 'Return',
      'JV': 'Journal Voucher',
    };

    return descriptions[code] ?? 'Next Number for $code';
  }

  String _formatNumber(String code, int number) {
    // Format based on code type
    switch (code) {
      case 'LM':
        return 'LM${number.toString().padLeft(6, '0')}';
      case 'PO':
        return 'PO${number.toString().padLeft(6, '0')}';
      case 'SO':
        return 'SO${number.toString().padLeft(6, '0')}';
      case 'GR':
        return 'GR${number.toString().padLeft(6, '0')}';
      case 'GI':
        return 'GI${number.toString().padLeft(6, '0')}';
      case 'TR':
        return 'TR${number.toString().padLeft(6, '0')}';
      case 'AD':
        return 'AD${number.toString().padLeft(6, '0')}';
      default:
        return '$code${number.toString().padLeft(6, '0')}';
    }
  }

  // Reset next number for a code
  Future<void> resetNextNumber(
    String code,
    int startFrom,
    int companyId,
  ) async {
    final db = await databaseService.database;

    await db.update(
      'next_number',
      {'next_number': startFrom},
      where: 'company = ? AND next_number_code = ?',
      whereArgs: [companyId, code],
    );
  }

  // Batch insert next numbers
  Future<void> batchInsertNextNumbers(List<NextNumberModel> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      final itemMap = item.toMap();
      itemMap.remove('id');
      batch.insert('next_number', itemMap);
    }

    await batch.commit();
  }

  // Batch update next numbers
  Future<void> batchUpdateNextNumbers(List<NextNumberModel> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      batch.update(
        'next_number',
        item.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [item.id, item.company],
      );
    }

    await batch.commit();
  }

  // Batch delete next numbers
  Future<void> batchDeleteNextNumbers(List<int> ids, int companyId) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete(
        'next_number',
        where: 'id = ? AND company = ?',
        whereArgs: [id, companyId],
      );
    }

    await batch.commit();
  }
}
