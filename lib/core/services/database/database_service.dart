import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  static Database? _database;

  factory LocalDatabaseService() {
    return _instance;
  }

  LocalDatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'savvy_stock.db');
    return await openDatabase(
      path,
      version: 1, // Increment this for future migrations
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add upgrade handler
      onOpen: (db) async {
        await _debugPrintTablesAndData(db);
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Example migration for version 2
      await db.execute('''
      ALTER TABLE system_constant ADD COLUMN new_column TEXT DEFAULT NULL
    ''');
    }

    if (oldVersion < 3) {
      // Migration for version 3
      await db.execute('''
      CREATE TABLE IF NOT EXISTS new_feature_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feature_data TEXT
      )
    ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating database tables...');

    // 1. Create udc_header table (must be first due to foreign key constraints)
    await db.execute('''
      CREATE TABLE udc_header (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        header_code TEXT NOT NULL,
        description_1 TEXT NOT NULL,
        description_2 TEXT,
        system_code TEXT,
        date_created INTEGER,
        date_updated INTEGER,
        created_by INTEGER,
        updated_by INTEGER
      )
    ''');
    developer.log('Created table: udc_header');

    // 2. Create udc_details table
    await db.execute('''
      CREATE TABLE udc_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        detail_code TEXT NOT NULL,
        description_1 TEXT NOT NULL,
        description_2 TEXT,
        record_header INTEGER,
        udc_group TEXT,
        FOREIGN KEY (record_header) REFERENCES udc_header (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        UNIQUE (detail_code, record_header)
      )
    ''');
    developer.log('Created table: udc_details');

    // 3. Create company_table
    await db.execute('''
      CREATE TABLE company_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        tin_number TEXT,
        phone_number_1 TEXT,
        phone_number_2 TEXT,
        phone_number_3 TEXT,
        email_address_1 TEXT,
        email_address_2 TEXT,
        city TEXT,
        region TEXT,
        state TEXT,
        country TEXT,
        address_line TEXT,
        logo_company TEXT,
        subscription_fee REAL,
        user_limmit INTEGER,
        branch_limmit INTEGER,
        days_left INTEGER,
        woreda TEXT,
        category_code INTEGER,
        referred_by_salesperson_id INTEGER,
        date_created INTEGER,
        date_updated INTEGER,
        margin_rate REAL,
        margin_type TEXT,
        inventory_planner INTEGER,
        FOREIGN KEY (category_code) REFERENCES udc_details (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    developer.log('Created table: company_table');

    // 4. Create user_table
    await db.execute('''
      CREATE TABLE user_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        password TEXT NOT NULL,
        employees_id INTEGER,
        created_by INTEGER,
        updated_by INTEGER,
        date_created INTEGER,
        date_updated INTEGER,
        usercol TEXT,
        branch INTEGER,
        status TEXT,
        password_last_updated INTEGER,
        company INTEGER,
        user_email TEXT,
        confirmation_code TEXT,
        confirmations_expire_time INTEGER,
        user_name TEXT,
        type TEXT DEFAULT 'Company',
        salesperson INTEGER,
        FOREIGN KEY (company) REFERENCES company_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    developer.log('Created table: user_table');

    // 5. Create system_constant table
    await db.execute('''
      CREATE TABLE system_constant (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apply_lot_mgm TEXT,
        apply_location_mgm TEXT,
        interface_customer TEXT,
        interface_employee TEXT,
        decimal_places INTEGER,
        date_last_updated INTEGER,
        time_last_updated INTEGER,
        updated_by INTEGER,
        generate_barcode_for_item TEXT,
        company INTEGER,
        rate_vat_percentage REAL,
        rate_with_percentage REAL,
        with_hold_initials REAL,
        auto_sales_price TEXT DEFAULT 'N',
        lot_type INTEGER,
        location_category_level INTEGER DEFAULT 1,
        lot_qty_auto_for_sales TEXT DEFAULT 'Y',
        is_synced INTEGER DEFAULT 1,
        last_sync_time INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (company) REFERENCES company_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (lot_type) REFERENCES udc_details (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (updated_by) REFERENCES user_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    developer.log('Created table: system_constant');

    // 6. Create sync_queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER,
        operation TEXT NOT NULL,
        data TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        attempts INTEGER DEFAULT 0,
        last_attempt INTEGER
      )
    ''');
    developer.log('Created table: sync_queue');

    // Insert default data for LOT types
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    developer.log('Inserting default data...');

    // Insert default LOT type header
    final headerId = await db.insert('udc_header', {
      'header_code': 'LT',
      'description_1': 'LOT Types',
      'description_2': 'Different types of LOT management',
      'system_code': 'LOT_MGMT',
      'date_created': DateTime.now().millisecondsSinceEpoch,
    });

    // Insert default LOT types
    final lotTypes = [
      {
        'detail_code': '01',
        'description_1': 'Expiration Date',
        'description_2': 'Select items by expiration date',
        'record_header': headerId,
        'udc_group': 'LOT_TYPE',
      },
      {
        'detail_code': '02',
        'description_1': 'Effective Date',
        'description_2': 'Select items by effective date',
        'record_header': headerId,
        'udc_group': 'LOT_TYPE',
      },
      {
        'detail_code': '03',
        'description_1': 'Receipt Date',
        'description_2': 'Select items by receipt date',
        'record_header': headerId,
        'udc_group': 'LOT_TYPE',
      },
    ];

    for (final lotType in lotTypes) {
      await db.insert('udc_details', lotType);
    }
    developer.log('Inserted default LOT types');
  }

  Future<void> _debugPrintTablesAndData(Database db) async {
    developer.log('=== DATABASE DEBUG INFORMATION ===');

    try {
      // Get all tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );

      developer.log('Available tables:');
      for (final table in tables) {
        final tableName = table['name'] as String;
        developer.log('  - $tableName');

        // Get table schema
        final schema = await db.rawQuery("PRAGMA table_info($tableName)");
        developer.log('    Schema:');
        for (final column in schema) {
          developer.log('      ${column['name']} (${column['type']})');
        }

        // Get row count
        final countResult = await db.rawQuery(
          "SELECT COUNT(*) as count FROM $tableName",
        );
        final count = countResult.first['count'] as int;

        developer.log('    Row count: $count');

        // Show sample data (first 5 rows if any)
        if (count > 0) {
          final sampleData = await db.query(tableName, limit: 5);
          developer.log('    Sample data:');
          for (final row in sampleData) {
            developer.log('      $row');
          }
        }
      }

      developer.log('=== END DATABASE DEBUG ===');
    } catch (e) {
      developer.log('Error during database debugging: $e');
    }
  }

  // Helper method to debug specific table
  Future<void> debugTable(String tableName) async {
    final db = await database;
    developer.log('=== DEBUG TABLE: $tableName ===');

    try {
      // Check if table exists
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
      );

      if (tableExists.isEmpty) {
        developer.log('Table $tableName does not exist');
        return;
      }

      // Get all data from table
      final data = await db.query(tableName);
      developer.log('Data in $tableName:');
      for (final row in data) {
        developer.log('  $row');
      }

      // Get row count
      final countResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM $tableName",
      );
      final count = countResult.first['count'] as int;
      developer.log('Total rows: $count');
    } catch (e) {
      developer.log('Error debugging table $tableName: $e');
    }
  }

  // Helper method to clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    developer.log('Clearing all data from database...');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name != 'sqlite_sequence'",
    );

    await db.transaction((txn) async {
      for (final table in tables) {
        final tableName = table['name'] as String;
        await txn.execute('DELETE FROM $tableName');
        developer.log('Cleared table: $tableName');
      }
    });

    developer.log('All data cleared');
  }

  // Helper method to reset database (drop and recreate)
  Future<void> resetDatabase() async {
    developer.log('Resetting database...');
    await close();

    String path = join(await getDatabasesPath(), 'savvy_stock.db');
    await deleteDatabase(path);

    _database = null;
    await database; // This will recreate the database
    developer.log('Database reset complete');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

// Example usage and testing
void testDatabase() async {
  final dbService = LocalDatabaseService();

  // Initialize database
  final db = await dbService.database;

  // Debug all tables
  await dbService._debugPrintTablesAndData(db);

  // Debug specific table
  await dbService.debugTable('system_constant');
  await dbService.debugTable('udc_details');

  // Example: Insert a test system constant
  final testSystemConstant = {
    'apply_lot_mgm': 'N',
    'apply_location_mgm': 'Y',
    'decimal_places': 2,
    'generate_barcode_for_item': 'N',
    'rate_vat_percentage': 15.0,
    'rate_with_percentage': 2.0,
    'with_hold_initials': 0.0,
    'auto_sales_price': 'N',
    'lot_qty_auto_for_sales': 'Y',
    'location_category_level': 1,
    'is_synced': 0, // Not synced yet
  };

  final id = await db.insert('system_constant', testSystemConstant);
  developer.log('Inserted test system constant with ID: $id');

  // Verify insertion
  await dbService.debugTable('system_constant');
}

// Add this method to your LocalDatabaseService class
Future<List<Map<String, dynamic>>> getUdcDetailsByCode(
  String detailCode,
) async {
  final db = await LocalDatabaseService().database;
  try {
    final results = await db.query(
      'udc_details',
      where: 'detail_code = ?',
      whereArgs: [detailCode],
    );
    developer.log('Found ${results.length} UDC details for code: $detailCode');
    return results;
  } catch (e) {
    developer.log('Error getting UDC details: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> getUdcDetailsByHeaderCode(
  String headerCode,
) async {
  final db = await LocalDatabaseService().database;
  try {
    final results = await db.rawQuery(
      '''
      SELECT udc_details.* 
      FROM udc_details 
      INNER JOIN udc_header ON udc_details.record_header = udc_header.id 
      WHERE udc_header.header_code = ?
    ''',
      [headerCode],
    );

    developer.log(
      'Found ${results.length} UDC details for header: $headerCode',
    );
    return results;
  } catch (e) {
    developer.log('Error getting UDC details by header: $e');
    return [];
  }
}
