// features/stock/fast_slow_nonmoving_rule/repositories/fast_slow_nonmoving_rule_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/FSNMR/models/fast_slow_nonmoving_rule.dart';
import 'package:sqflite/sqflite.dart';

/// Result class for saveInEdit operation - equivalent to Java's return with messages
class SaveInEditResult {
  final bool success;
  final String message;
  final bool isDuplicate;
  final bool hasChanges;

  SaveInEditResult({
    required this.success,
    required this.message,
    this.isDuplicate = false,
    this.hasChanges = true,
  });
}

class FSNMRRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  FSNMRRepository({required this.databaseService});

  // ========== JAVA CONTROLLER EQUIVALENT METHODS ==========

  /// Get all edit items for a company (equivalent to Java's getEditItems)
  /// Returns all rules filtered by company ID
  Future<List<FastSlowNonMovingRule>> getEditItems(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      WHERE fsnr.company = ?
      ORDER BY fsnr.id DESC
    ''',
      [companyId],
    );

    // Filter by company (already done in WHERE, but mimics Java's stream filter)
    return maps
        .where((map) => map['company'] != null && map['company'] == companyId)
        .map((map) => FastSlowNonMovingRule.fromMap(map))
        .toList();
  }

  /// Save or update a rule with validation (equivalent to Java's saveInEdit)
  /// Handles duplicate checking, create/update logic, and change detection
  Future<SaveInEditResult> saveInEdit(
    FastSlowNonMovingRule item,
    int companyId,
    int userId,
  ) async {
    try {
      // Step 1: Check for duplicates (equivalent to Java's duplicateChecker)
      final isDuplicate = await duplicateCheckerByReportFrequencyAndPeriod(
        reportFrequency: item.reportFrequency,
        periodInDays: item.periodInDays,
        companyId: companyId,
        excludeId: item.id,
      );

      if (isDuplicate) {
        return SaveInEditResult(
          success: false,
          message: 'Duplicate record not allowed!',
          isDuplicate: true,
        );
      }

      // Step 2: Check if this is a new record or update
      if (item.id == null || item.id == 0) {
        // New record - Create
        final now = DateTime.now();
        final newRule = item.copyWith(
          company: companyId,
          userId: userId,
          createdDate: now,
          updatedDate: now,
        );

        await create(newRule);

        return SaveInEditResult(
          success: true,
          message: 'New record has been created successfully',
        );
      } else {
        // Existing record - Compare before update (equivalent to Java's comparingItemsData)
        final existing = await findById(item.id!, companyId);

        if (existing == null) {
          return SaveInEditResult(
            success: false,
            message: 'Record not found for update',
          );
        }

        // Check if there are any changes
        final hasChangesResult = hasChanges(item, existing);

        if (!hasChangesResult) {
          return SaveInEditResult(
            success: false,
            message: 'No changes detected, record not updated.',
            hasChanges: false,
          );
        }

        // Has changes - perform update
        final updatedRule = item.copyWith(
          userId: userId,
          updatedDate: DateTime.now(),
        );

        await update(updatedRule);

        // Get report frequency description for message
        String reportFreqDesc = '';
        final reportFreqDescription = item.reportFrequencyRef?.description1;
        if (reportFreqDescription != null) {
          reportFreqDesc = reportFreqDescription;
        } else {
          reportFreqDesc = item.reportFrequency?.toString() ?? 'Rule';
        }

        return SaveInEditResult(
          success: true,
          message: '$reportFreqDesc has been updated successfully',
        );
      }
    } catch (e) {
      return SaveInEditResult(success: false, message: 'Error occurred: $e');
    }
  }

  /// Check for duplicate records by report frequency and period in days
  /// (equivalent to Java's duplicateChecker)
  Future<bool> duplicateCheckerByReportFrequencyAndPeriod({
    required int? reportFrequency,
    required int? periodInDays,
    required int companyId,
    int? excludeId,
  }) async {
    try {
      final db = await databaseService.database;

      String query = '''
        SELECT id FROM fast_slow_nonmoving_rule
        WHERE report_frequency = ? 
        AND period_in_days = ? 
        AND company = ?
      ''';

      List<dynamic> args = [reportFrequency, periodInDays, companyId];

      if (excludeId != null && excludeId != 0) {
        query += ' AND id != ?';
        args.add(excludeId);
      }

      final result = await db.rawQuery(query, args);

      // If there are results and (id is null/0 OR the found id is different), it's a duplicate
      if (result.isNotEmpty) {
        final foundId = result.first['id'] as int?;
        if (excludeId == null || excludeId == 0) {
          return true; // New record with same values exists
        } else if (foundId != excludeId) {
          return true; // Different record with same values exists
        }
      }

      return false;
    } catch (e) {
      print('Error in duplicateChecker: $e');
      return false;
    }
  }

  /// Compare two rules to detect changes (equivalent to Java's comparingItemsData)
  /// Returns true if there are changes, false if identical
  bool hasChanges(
    FastSlowNonMovingRule newItem,
    FastSlowNonMovingRule existing,
  ) {
    return newItem.reportFrequency != existing.reportFrequency ||
        newItem.periodInDays != existing.periodInDays ||
        newItem.fastMovementRuleUnit != existing.fastMovementRuleUnit ||
        newItem.unitOfMeasureDefault != existing.unitOfMeasureDefault ||
        newItem.slowMovementRuleUnit != existing.slowMovementRuleUnit ||
        newItem.nonMovementRuleUnit != existing.nonMovementRuleUnit;
  }

  // ========== BASIC CRUD OPERATIONS ==========

  // Create new rule
  Future<int> create(FastSlowNonMovingRule rule, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final ruleMap = rule.toMap();
    ruleMap.remove('id');
    return await db.insert('fast_slow_nonmoving_rule', ruleMap);
  }

  // Update existing rule
  Future<int> update(FastSlowNonMovingRule rule, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.update(
      'fast_slow_nonmoving_rule',
      rule.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [rule.id, rule.company],
    );
  }

  // Delete rule
  Future<int> delete(int id, int companyId, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.delete(
      'fast_slow_nonmoving_rule',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Delete multiple rules
  Future<void> deleteMultiple(
    List<int> ids,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete(
        'fast_slow_nonmoving_rule',
        where: 'id = ? AND company = ?',
        whereArgs: [id, companyId],
      );
    }

    await batch.commit();
  }

  // Find rule by ID with full joins
  Future<FastSlowNonMovingRule?> findById(int id, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      WHERE fsnr.id = ? AND fsnr.company = ?
    ''',
      [id, companyId],
    );

    if (maps.isNotEmpty) {
      return FastSlowNonMovingRule.fromMap(maps.first);
    }
    return null;
  }

  // Find all rules for company
  Future<List<FastSlowNonMovingRule>> findAll(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      WHERE fsnr.company = ?
      ORDER BY fsnr.id DESC
    ''',
      [companyId],
    );

    return maps.map((map) => FastSlowNonMovingRule.fromMap(map)).toList();
  }

  // Find rule by rules ID
  Future<FastSlowNonMovingRule?> findByRulesId(
    String rulesId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      WHERE fsnr.rules_id = ? AND fsnr.company = ?
    ''',
      [rulesId, companyId],
    );

    if (maps.isNotEmpty) {
      return FastSlowNonMovingRule.fromMap(maps.first);
    }
    return null;
  }

  // Find by report frequency
  Future<FastSlowNonMovingRule?> findByReportFrequency(
    int reportFrequency,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      WHERE fsnr.report_frequency = ? AND fsnr.company = ?
    ''',
      [reportFrequency, companyId],
    );

    if (maps.isNotEmpty) {
      return FastSlowNonMovingRule.fromMap(maps.first);
    }
    return null;
  }

  // Check for duplicate rules
  Future<bool> checkDuplicate({
    required int companyId,
    int? reportFrequency,
    int? periodInDays,
    int? excludeId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    String whereClause =
        'company = ? AND report_frequency = ? AND period_in_days = ?';
    List<dynamic> whereArgs = [companyId, reportFrequency, periodInDays];

    if (excludeId != null && excludeId != 0) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'fast_slow_nonmoving_rule',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Search rules (fixed SQL syntax error)
  Future<List<FastSlowNonMovingRule>> search(
    String query,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      WHERE fsnr.company = ? AND (
        CAST(fsnr.report_frequency AS TEXT) LIKE ? OR 
        CAST(fsnr.period_in_days AS TEXT) LIKE ? OR
        rf.description_1 LIKE ? OR
        ud.description_1 LIKE ?
      )
      ORDER BY fsnr.id DESC
    ''',
      [companyId, '%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return maps.map((map) => FastSlowNonMovingRule.fromMap(map)).toList();
  }

  // Filter rules by multiple criteria
  Future<List<FastSlowNonMovingRule>> filter({
    required int companyId,
    int? reportFrequency,
    int? periodInDays,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'WHERE fsnr.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (reportFrequency != null && reportFrequency > 0) {
      whereClause += ' AND fsnr.report_frequency = ?';
      whereArgs.add(reportFrequency);
    }

    if (periodInDays != null && periodInDays > 0) {
      whereClause += ' AND fsnr.period_in_days = ?';
      whereArgs.add(periodInDays);
    }

    final maps = await db.rawQuery('''
      SELECT fsnr.*,
      ud.description_1 as unit_of_measure_default_description,
      ud.detail_code as unit_of_measure_default_code,
      rf.description_1 as report_frequency_description,
      rf.detail_code as report_frequency_code
      FROM fast_slow_nonmoving_rule fsnr
      LEFT JOIN udc_details ud ON fsnr.unit_of_measure_default = ud.id
      LEFT JOIN udc_details rf ON fsnr.report_frequency = rf.id
      $whereClause
      ORDER BY fsnr.id DESC
    ''', whereArgs);

    return maps.map((map) => FastSlowNonMovingRule.fromMap(map)).toList();
  }

  // Update multiple rules in batch
  Future<void> updateBatch(List<FastSlowNonMovingRule> rules) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final rule in rules) {
      batch.update(
        'fast_slow_nonmoving_rule',
        rule.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [rule.id, rule.company],
      );
    }

    await batch.commit();
  }

  // Get rules for select many (with company filter)
  Future<List<FastSlowNonMovingRule>> getRulesForSelectedCompany(
    int companyId,
  ) async {
    return await findAll(companyId);
  }

  // Get rules for select one (with company filter)
  Future<List<FastSlowNonMovingRule>> getRulesForSelectedCompanyOne(
    int companyId,
  ) async {
    return await getRulesForSelectedCompany(companyId);
  }

  // Check if period in days exists
  Future<bool> periodInDaysExists(
    int periodInDays,
    int companyId, {
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'period_in_days = ? AND company = ?';
    List<dynamic> whereArgs = [periodInDays, companyId];

    if (excludeId != null && excludeId != 0) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'fast_slow_nonmoving_rule',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }
}
