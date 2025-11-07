// core/repositories/base_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

abstract class BaseRepository {
  Future<dynamic> getDatabaseExecutor({Transaction? txn}) async {
    return txn ?? await databaseService.database;
  }

  // This should be implemented by each repository
  LocalDatabaseService get databaseService;
}
