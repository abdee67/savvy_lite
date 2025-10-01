import 'dart:convert';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/services/database/seeders/privilege_seeder.dart';
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
        FOREIGN KEY (category_code) REFERENCES udc_details (detail_code) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    developer.log('Created table: company_table');

    //4. Create branch table
    await db.execute('''
  CREATE TABLE branch_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reference_id INTEGER,
    description TEXT,
    city TEXT,
    region TEXT,
    state TEXT,
    country TEXT,
    address_line TEXT,
    company INTEGER,
    branch_phone TEXT,
    margin_rate REAL,
    margin_type TEXT,
    FOREIGN KEY (company) REFERENCES company_table(id)
  );
''');
    developer.log('Created table: branch_table');
    //5. Create employee table
    developer.log('Creating table: employees');
    await db.execute('''
  CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id TEXT,
    name_first TEXT,
    name_last TEXT,
    name_middle TEXT,
    title TEXT,
    birth_date TEXT,
    hire_date TEXT,
    address TEXT,
    city TEXT,
    region TEXT,
    country TEXT,
    phone TEXT,
    email TEXT,
    gender TEXT,
    company INTEGER,
    branch INTEGER,
    FOREIGN KEY (company) REFERENCES company_table(id),
    FOREIGN KEY (branch) REFERENCES branch_table(id)
  );
''');
    developer.log('Created table: employees');

    //6.create privilege table
    await db.execute('''
  CREATE TABLE privilege_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    description TEXT,
    created_by INTEGER,
    date_created TEXT,
    updated_by INTEGER,
    date_updated TEXT,
    type TEXT,
    link TEXT,
    button TEXT,
    link_lable TEXT UNIQUE,
    button_lable TEXT,
    vendor_only TEXT DEFAULT 'N',
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id)
  );
''');
    developer.log('Created table: privilege_table');

    //7.Create role table
    await db.execute('''
  CREATE TABLE role_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    created_by INTEGER,
    updated_by INTEGER,
    description TEXT,
    date_created TEXT,
    date_updated TEXT,
    company INTEGER,
    UNIQUE (name, company),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id),
    FOREIGN KEY (company) REFERENCES company_table(id)
  );
''');
    developer.log('Created table: role_table');

    //8.create role_privilege table
    await db.execute('''
  CREATE TABLE role_privilege (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_table_id INTEGER,
    privilege_table_id INTEGER,
    created_by INTEGER,
    updated_by INTEGER,
    date_created TEXT,
    date_updated TEXT,
    FOREIGN KEY (role_table_id) REFERENCES role_table(id),
    FOREIGN KEY (privilege_table_id) REFERENCES privilege_table(id),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id)
  );
''');
    developer.log('Created table: role_privilege');

    // 9. Create user_table
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
          FOREIGN KEY (employees_id) REFERENCES employees(id),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id),
    FOREIGN KEY (branch) REFERENCES branch_table(id),
    FOREIGN KEY (company) REFERENCES company_table(id)
      )
    ''');
    developer.log('Created table: user_table');

    //10. Create user role table
    await db.execute('''
  CREATE TABLE user_role (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_table_id INTEGER,
    user_id INTEGER,
    created_by INTEGER,
    updated_by INTEGER,
    date_created TEXT,
    date_updated TEXT,
    FOREIGN KEY (role_table_id) REFERENCES role_table(id),
    FOREIGN KEY (user_id) REFERENCES user_table(id),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id)
  );
''');
    developer.log('Created table: user_role');

    // 11. Create system_constant table
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

    // Add indexes for better performance
    await db.execute('CREATE INDEX idx_company ON company_table(id)');
    await db.execute('CREATE INDEX idx_user_company ON user_table(company)');
    await db.execute(
      'CREATE INDEX idx_privilege_uri ON privilege_table(link_lable)',
    );
    await db.execute(
      'CREATE INDEX idx_role_table_id ON user_role(role_table_id)',
    );
    await db.execute('CREATE INDEX idx_user_id ON user_role(user_id)');

    await db.execute('''
  CREATE UNIQUE INDEX IF NOT EXISTS idx_user_company_username
  ON user_table (user_name, company)
''');

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

    // Insert Company
    final companies = [
      {
        'id': 1,
        'company_name': 'Savvy Corp',
        'tin_number': 'TIN123456',
        'phone_number_1': '+251911223344',
        'email_address_1': 'info@savvy.com',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'address_line': 'Bole Street, 5th Floor',
        'subscription_fee': 999.99,
        'user_limmit': 50,
        'branch_limmit': 10,
        'days_left': 30,
        'margin_rate': 10.0,
        'margin_type': 'Percentage',
        'inventory_planner': 1,
        'category_code': 1,
        'date_created': DateTime.now().millisecondsSinceEpoch,
        'date_updated': DateTime.now().millisecondsSinceEpoch,
      },
      /*{
        'id': 2,
        'company_name': 'ABCD Corp',
        'tin_number': 'TIN77777',
        'phone_number_1': '+251911223344',
        'email_address_1': 'info@abcd.com',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'address_line': 'Sar bet, 5th Floor',
        'subscription_fee': 888.88,
        'user_limmit': 20,
        'branch_limmit': 5,
        'days_left': 10,
        'margin_rate': 15.0,
        'margin_type': 'number',
        'inventory_planner': 1,
        'category_code': 2,
        'date_created': DateTime.now().millisecondsSinceEpoch,
        'date_updated': DateTime.now().millisecondsSinceEpoch,
      }, */
    ];

    for (final company in companies) {
      await db.insert('company_table', company);
    }
    developer.log('Inserted companies');

    // Insert Branch
    final branches = [
      {
        'id': 1,
        'reference_id': 1001,
        'description': 'Savvy Main Branch',
        'city': 'Addis Ababa',
        'region': 'Addis',
        'country': 'Ethiopia',
        'address_line': 'Kera road',
        'company': 1,
        'margin_rate': 10.0,
        'margin_type': 'Percentage',
        'branch_phone': '+2519111111',
      },
      /* {
        'id': 2,
        'reference_id': 1002,
        'description': 'Sar bet Branch',
        'city': 'Addis Ababa',
        'region': 'Addis',
        'country': 'Ethiopia',
        'address_line': 'Kera Road',
        'company': 1,
        'margin_rate': 10.0,
        'margin_type': 'Percentage',
        'branch_phone': '+251911223355',
      },
      {
        'id': 3,
        'reference_id': 2001,
        'description': 'ABCD Main Branch',
        'city': 'Addis Ababa',
        'region': 'Addis',
        'country': 'Ethiopia',
        'address_line': 'Bole Road',
        'company': 2,
        'margin_rate': 15.0,
        'margin_type': 'number',
        'branch_phone': '+2519222222',
      },
      {
        'id': 4,
        'reference_id': 2002,
        'description': 'Bole Branch',
        'city': 'Addis Ababa',
        'region': 'Addis',
        'country': 'Ethiopia',
        'address_line': 'Bole Road',
        'company': 2,
        'margin_rate': 15.0,
        'margin_type': 'number',
        'branch_phone': '+251922222',
      },*/
    ];
    for (final branch in branches) {
      await db.insert('branch_table', branch);
    }
    developer.log('Inserted companies');

    // Insert Employee
    final employees = [
      {
        'employee_id': 'EMP001',
        'name_first': 'Abdi(admin)',
        'name_last': 'G',
        'gender': 'M',
        'hire_date': '2022-01-01',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'company': 1,
        'branch': 1,
        'name_middle': 'M',
        'title': 'Admin',
        'birth_date': '2022-01-01',
        'address': 'Addis Ababa',
        'region': 'Addis',
        'phone': '+2519111111',
        'email': 'admin@gmail.com',
      },
      {
        'employee_id': 'EMP002',
        'name_first': 'Chalatu(salesManager)',
        'name_last': 'C',
        'gender': 'F',
        'hire_date': '2000-01-01',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'company': 1,
        'branch': 1,
        'name_middle': 'M',
        'title': 'Sales Manager',
        'birth_date': '2022-01-01',
        'address': 'Addis Ababa',
        'region': 'Addis',
        'phone': '+2519111111',
        'email': 'salesManager@gmail.com',
      },
      {
        'employee_id': 'EMP003',
        'name_first': 'pimp',
        'name_last': 'slickback',
        'gender': 'M',
        'hire_date': '2000-01-01',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'company': 1,
        'branch': 1,
        'name_middle': 'M',
        'title': 'Sales Manager',
        'birth_date': '2022-01-01',
        'address': 'Addis Ababa',
        'region': 'Addis',
        'phone': '+2519111111',
        'email': 'stockManager@gmail.com',
      },
      {
        'employee_id': 'EMP003',
        'name_first': 'baby',
        'name_last': 'slickback',
        'gender': 'F',
        'hire_date': '2000-01-01',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'company': 1,
        'branch': 1,
        'name_middle': 'M',
        'title': 'Sales Manager',
        'birth_date': '2022-01-01',
        'address': 'Addis Ababa',
        'region': 'Addis',
        'phone': '+2519111111',
        'email': 'babyManager@gmail.com',
      },
    ];
    for (final employee in employees) {
      await db.insert('employees', employee);
    }
    developer.log('employee inewelsdfghbnvcxsdf');

    // 1. Seed privileges
    await PrivilegeSeeder.seedPrivileges(db);

    // 2. Fetch privileges back (with their IDs)
    final privileges = await db.query('privilege_table');

    // 3. Use map for quick lookup
    final privilegeByUri = {
      for (var p in privileges) p['link'] as String: p['id'] as int,
    };

    final roles = [
      {
        'name': 'Administrator',
        'description': 'Full system access with all privileges',
      },
      {
        'name': 'Sales Manager',
        'description': 'Sales operations with customer management',
      },
      {
        'name': 'Stock Manager',
        'description': 'Inventory and stock management',
      },
    ];

    final roleIds = <String, int>{};

    for (final role in roles) {
      role['company'] = '1';
      role['created_by'] = '1';
      role['date_created'] = DateTime.now().toIso8601String();
      role['updated_by'] = '1';
      role['date_updated'] = DateTime.now().toIso8601String();
      final id = await db.insert('role_table', role);
      roleIds[role['name']!] = id;
    }

    // Example: assign all to Admin
    for (final privilege in privileges) {
      await db.insert('role_privilege', {
        'role_table_id': roleIds['Administrator'],
        'privilege_table_id': privilege['id'],
        'created_by': 1,
        'date_created': DateTime.now().toIso8601String(),
      });
    }

    developer.log('Inserted admin role privileges');

    // Example: Sales Manager subset
    final salesPrivileges = [
      AppRoutes.salesDashboard,
      AppRoutes.customerEntry,
      AppRoutes.salesCustomerInfo,
      AppRoutes.salesItemEntry,
    ];

    for (final uri in salesPrivileges) {
      final pid = privilegeByUri[uri];
      if (pid != null) {
        await db.insert('role_privilege', {
          'role_table_id': roleIds['Sales Manager'],
          'privilege_table_id': pid,
          'created_by': 1,
          'date_created': DateTime.now().toIso8601String(),
        });
      }
    }
    developer.log('Inserted sales manager role privileges');

    // Example: Stock Manager subset
    final stockPrivileges = [
      AppRoutes.stockDashboard,
      AppRoutes.itemEntry,
      AppRoutes.uomManagement,
      AppRoutes.itemWorkbench,
      AppRoutes.itemUomConversions,
      AppRoutes.locationEntry,
      AppRoutes.lotEntry,
      AppRoutes.lotColorings,
      AppRoutes.inventoryTransaction,
      AppRoutes.itemBranchEntry,
      AppRoutes.barcodeFunction,
      AppRoutes.exportFunction,
    ];

    for (final uri in stockPrivileges) {
      final pid = privilegeByUri[uri];
      if (pid != null) {
        await db.insert('role_privilege', {
          'role_table_id': roleIds['Stock Manager'],
          'privilege_table_id': pid,
          'created_by': 1,
          'date_created': DateTime.now().toIso8601String(),
        });
      }
    }
    developer.log('Inserted stock manager role privileges');

    // Helper function to generate Argon2 hash
    Future<String> generateArgon2Hash(password) async {
      final salt = 'somesalt'.toBytesLatin1();
      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_i,
        salt,
        version: Argon2Parameters.ARGON2_VERSION_10,
        iterations: 2,
        memoryPowerOf2: 16,
      );

      final argon2 = Argon2BytesGenerator();
      argon2.init(parameters);
      final passwordBytes = parameters.converter.convert(password);
      final result = Uint8List(32);
      argon2.generateBytes(passwordBytes, result, 0, result.length);
      return result.toHexString();
    }

    // Insert User (password = "password123", argon-hashed)
    // Generate Argon2 hash for "admin123"
    final argon2Hash = await generateArgon2Hash('admin123');
    final users = [
      {
        'password': argon2Hash,
        'employees_id': 1,
        'created_by': 1,
        'branch': 1,
        'company': 1,
        'user_name': 'admin',
        'status': 'active',
        'password_last_updated': DateTime.now().millisecondsSinceEpoch,
        'usercol': 'admin',
        'user_email': 'admin@gmail.com',
        'confirmation_code': '123456',
        'confirmations_expire_time': DateTime.now().millisecondsSinceEpoch,
        'type': 'Company',
        'salesperson': 1,
        'date_created': DateTime.now().millisecondsSinceEpoch,
        'date_updated': DateTime.now().millisecondsSinceEpoch,
      },

      {
        'password': argon2Hash,
        'employees_id': 2,
        'created_by': 1,
        'branch': 1,
        'company': 1,
        'user_name': 'salesManager',
        'status': 'active',
        'date_created': DateTime.now().millisecondsSinceEpoch,
        'password_last_updated': DateTime.now().millisecondsSinceEpoch,
        'user_email': 'salesManager@gmail.com',
        'confirmation_code': '123456',
        'confirmations_expire_time': DateTime.now().millisecondsSinceEpoch,
        'type': 'Company',
        'salesperson': 1,
        'date_updated': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'password': argon2Hash,
        'employees_id': 3,
        'created_by': 1,
        'branch': 1,
        'company': 1,
        'user_name': 'StockManager',
        'status': 'active',
        'date_created': DateTime.now().millisecondsSinceEpoch,
        'password_last_updated': DateTime.now().millisecondsSinceEpoch,
        'user_email': 'stockManager@gmail.com',
        'confirmation_code': '123456',
        'confirmations_expire_time': DateTime.now().millisecondsSinceEpoch,
        'type': 'Company',
        'salesperson': 1,
        'date_updated': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (final user in users) {
      await db.insert('user_table', user);
    }
    developer.log('Inserted users');

    final userRoles = [
      {
        'user_id': 1, // admin user
        'role_table_id': roleIds['Administrator'],
        'created_by': 1,
        'date_created': DateTime.now().toIso8601String(),
      },

      {
        'user_id': 2, // stock manager
        'role_table_id': roleIds['Stock Manager'],
        'created_by': 1,
        'date_created': DateTime.now().toIso8601String(),
      },
    ];

    for (final userRole in userRoles) {
      await db.insert('user_role', userRole);
    }
    developer.log('Inserted user roles');

    await db.insert('system_constant', {
      'apply_lot_mgm': 'Y',
      'apply_location_mgm': 'Y',
      'interface_customer': 'Y',
      'interface_employee': 'Y',
      'decimal_places': 2,
      'date_last_updated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'time_last_updated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_by': 1,
      'generate_barcode_for_item': 'Y',
      'company': 1,
      'rate_vat_percentage': 17.0,
      'rate_with_percentage': 1.0,
      'with_hold_initials': 2000.0,
      'auto_sales_price': 'Y',
      'lot_type': 'Expiration Date',
      'location_category_level': 2,
      'lot_qty_auto_for_sales': 'Y',
      'is_synced': 1,
      'last_sync_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    developer.log('✅ Sample user and related data inserted successfully.');
  }

  Future<void> _debugPrintTablesAndData(Database db) async {
    developer.log('\n📦 === DATABASE DEBUG START ===');

    try {
      // Get all tables excluding internal ones
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );

      if (tables.isEmpty) {
        developer.log('⚠️ No user-defined tables found.');
        return;
      }

      for (final table in tables) {
        final tableName = table['name'] as String;

        // Table header
        developer.log('\n📁 Table: $tableName');

        // Row count
        final countResult = await db.rawQuery(
          "SELECT COUNT(*) AS count FROM $tableName",
        );
        final count = countResult.first['count'] as int;
        developer.log('  🔢 Row count: $count');

        // Sample data
        if (count > 0) {
          final sampleRows = await db.query(tableName, limit: 5);
          developer.log('  📄 Sample rows (max 5):');

          for (int i = 0; i < sampleRows.length; i++) {
            final rowJson = const JsonEncoder.withIndent(
              '    ',
            ).convert(sampleRows[i]);
            developer.log('    #${i + 1}:\n$rowJson');
          }
        } else {
          developer.log('  🚫 No rows found.');
        }
      }

      developer.log('\n✅ === DATABASE DEBUG END ===');
    } catch (e, stackTrace) {
      developer.log('❌ Error during database debug: $e\n$stackTrace');
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
