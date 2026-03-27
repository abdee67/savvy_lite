import 'dart:convert';
import 'dart:io';

import 'package:savvy_stock/core/services/database/seeders/default_data_seeder.dart';
import 'package:savvy_stock/core/services/database/seeders/privilege_seeder.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class LocalDatabaseService  {
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
    String path;
    if (Platform.isWindows || Platform.isLinux) {
      // For desktop, use the FFI factory and a known writable directory
      final dbDir = Directory(
        join(Platform.environment['APPDATA'] ?? '.', 'SavvyStock'),
      );
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      path = join(dbDir.path, 'savvy_stock.db');
      developer.log('Desktop DB path: $path');
    } else {
      path = join(await getDatabasesPath(), 'savvy_stock.db');
    }

    final DatabaseFactory factory = (Platform.isWindows || Platform.isLinux)
        ? databaseFactoryFfi
        : databaseFactory;

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1, // Keep schema version at 1
        onCreate: _onCreate,
        onUpgrade: _onUpgrade, // Add upgrade handler
        onOpen: (db) async {
          // await _debugPrintTablesAndData(db);
        },
      ),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 1) {
      // Version 1 migration: Add any new columns or tables here
      // Currently no schema changes needed for version 1
      developer.log('Database upgraded to version 1');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating database tables...');

    // 1. Create udc_header table (must be first due to foreign key constraints)
    await db.execute('''
      CREATE TABLE udc_header (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        udc_code TEXT CHECK(length(udc_code) <= 2),
        udc_description TEXT CHECK(length(udc_description) <= 45),
        sync_key TEXT CHECK(length(sync_key) <= 36),
        UNIQUE (udc_code),
        UNIQUE (udc_description)
      )
    ''');
    developer.log('Created table: udc_header');

    // 2. Create udc_details table
    await db.execute('''
      CREATE TABLE udc_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        detail_code TEXT NOT NULL CHECK(length(detail_code) <= 2),
        description_1 TEXT NOT NULL CHECK(length(description_1) <= 255),
        description_2 TEXT CHECK(length(description_2) <= 255),
        record_header INTEGER,
        udc_group TEXT CHECK(length(udc_group) <= 10),
        sync_key TEXT CHECK(length(sync_key) <= 36),
        FOREIGN KEY (record_header) REFERENCES udc_header (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        UNIQUE (detail_code, record_header)
      )
    ''');
    await db.execute('''
      CREATE INDEX fk_udc_details_record_header_idx ON udc_details(record_header);
    ''');
    developer.log('Created table: udc_details');

    // 3. Create company_table
    await db.execute('''
      CREATE TABLE company_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL CHECK(length(company_name) <= 150),
        tin_number TEXT CHECK(length(tin_number) <= 10),
        phone_number_1 TEXT CHECK(length(phone_number_1) <= 15),
        phone_number_2 TEXT CHECK(length(phone_number_2) <= 15),
        phone_number_3 TEXT CHECK(length(phone_number_3) <= 15),
        email_address_1 TEXT CHECK(length(email_address_1) <= 255),
        email_address_2 TEXT CHECK(length(email_address_2) <= 255),
        city TEXT CHECK(length(city) <= 45),
        region TEXT CHECK(length(region) <= 45),
        state TEXT CHECK(length(state) <= 45),
        country TEXT CHECK(length(country) <= 45),
        address_line TEXT CHECK(length(address_line) <= 200),
        logo_company TEXT CHECK(length(logo_company) <= 255),
        subscription_fee REAL,
        user_limmit INTEGER,
        branch_limmit INTEGER,
        days_left INTEGER,
        woreda TEXT CHECK(length(woreda) <= 25),
        category_code INTEGER,
        referred_by_salesperson_id INTEGER,
        date_created TEXT,
        date_updated TEXT,
        margin_rate REAL,
        margin_type TEXT CHECK(length(margin_type) <= 1),
        reorder_point REAL,
        inventory_planner INTEGER,
        sync_key TEXT CHECK(length(sync_key) <= 36),
        FOREIGN KEY (category_code) REFERENCES udc_details (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (referred_by_salesperson_id) REFERENCES salespersons (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (inventory_planner) REFERENCES employees (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    await db.execute(
      'CREATE INDEX fk_company_table_cat_cd_idx ON company_table(category_code)',
    );
    await db.execute(
      'CREATE INDEX fk_company_table_idx ON company_table(referred_by_salesperson_id)',
    );
    await db.execute(
      'CREATE INDEX fk_company_table_inv_plnr_idx ON company_table(inventory_planner)',
    );
    developer.log('Created table: company_table');

    // 3a. Create system_url_config table
    await db.execute('''
      CREATE TABLE system_url_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_key TEXT CHECK(length(config_key) <= 45),
        config_value TEXT CHECK(length(config_value) <= 500),
        environment TEXT CHECK(length(environment) <= 45),
        active TEXT CHECK(length(active) <= 1),
        company INTEGER,
        sync_key TEXT CHECK(length(sync_key) <= 36),
        UNIQUE (config_key),
        UNIQUE (config_value),
        FOREIGN KEY (company) REFERENCES company_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    await db.execute(
      'CREATE INDEX fk_system_url_config_compay_idx ON system_url_config(company)',
    );
    developer.log('Created table: system_url_config');

    // 3b. Create sync_event table
    await db.execute('''
      CREATE TABLE sync_event (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_name TEXT NOT NULL CHECK(length(entity_name) <= 255),
        entity_id TEXT CHECK(length(entity_id) <= 100),
        operation TEXT NOT NULL CHECK(length(operation) <= 10),
        payload TEXT NOT NULL,
        source_node TEXT CHECK(length(source_node) <= 20),
        created_at TEXT,
        company TEXT CHECK(length(company) <= 100),
        source_key TEXT CHECK(length(source_key) <= 100),
        source_address TEXT CHECK(length(source_address) <= 100),
        source_id TEXT CHECK(length(source_id) <= 100),
        sync_status TEXT DEFAULT 'PENDING' CHECK(length(sync_status) <= 20)
      )
    ''');
    developer.log('Created table: sync_event');

    // 3c. Create sync_device_detail table
    await db.execute('''
      CREATE TABLE sync_device_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_status TEXT DEFAULT 'PENDING' CHECK(length(sync_status) <= 20),
        last_attempt TEXT,
        last_error TEXT CHECK(length(last_error) <= 1000),
        device_address INTEGER,
        retry_count INTEGER DEFAULT 0,
        sync_event INTEGER,
        company TEXT CHECK(length(company) <= 100),
        FOREIGN KEY (device_address) REFERENCES system_url_config (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (sync_event) REFERENCES sync_event (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    await db.execute(
      'CREATE INDEX fk_sdd_device_sync_event_idx ON sync_device_detail(sync_event)',
    );
    await db.execute(
      'CREATE INDEX fk_sdd_device_address_idx ON sync_device_detail(device_address)',
    );
    developer.log('Created table: sync_device_detail');

    // 3d. Create sync_node_status table
    await db.execute('''
      CREATE TABLE sync_node_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        node_id TEXT CHECK(length(node_id) <= 500),
        last_seen TEXT,
        company TEXT NOT NULL CHECK(length(company) <= 100),
        source_node TEXT CHECK(length(source_node) <= 20),
        UNIQUE (node_id),
        UNIQUE (source_node)
      )
    ''');
    developer.log('Created table: sync_node_status');

    //4. Create branch table
    await db.execute('''
      CREATE TABLE branch_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference_id INTEGER,
        description TEXT CHECK(length(description) <= 45),
        city TEXT CHECK(length(city) <= 45),
        region TEXT CHECK(length(region) <= 45),
        state TEXT CHECK(length(state) <= 45),
        country TEXT CHECK(length(country) <= 45),
        address_line TEXT CHECK(length(address_line) <= 200),
        company INTEGER,
        branch_phone TEXT CHECK(length(branch_phone) <= 14),
        margin_rate REAL,
        margin_type TEXT CHECK(length(margin_type) <= 1),
        reorder_point REAL,
        sync_key TEXT CHECK(length(sync_key) <= 36),
        FOREIGN KEY (company) REFERENCES company_table(id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    await db.execute(
      'CREATE INDEX fk_branch_table_company_idx ON branch_table(company)',
    );
    developer.log('Created table: branch_table');
    //5. Create employee table
    developer.log('Creating table: employees');
    await db.execute('''
  CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id TEXT CHECK(length(employee_id) <= 20),
    name_first TEXT CHECK(length(name_first) <= 45),
    name_last TEXT CHECK(length(name_last) <= 45),
    name_middle TEXT CHECK(length(name_middle) <= 45),
    title TEXT CHECK(length(title) <= 45),
    birth_date TEXT,
    hire_date TEXT,
    address TEXT CHECK(length(address) <= 45),
    city TEXT CHECK(length(city) <= 45),
    region TEXT CHECK(length(region) <= 45),
    country TEXT CHECK(length(country) <= 45),
    phone_home TEXT CHECK(length(phone_home) <= 45),
    email TEXT,
    gender TEXT CHECK(length(gender) <= 7),
    company INTEGER,
    branch INTEGER,
    sync_key TEXT CHECK(length(sync_key) <= 36),
    FOREIGN KEY (company) REFERENCES company_table(id),
    FOREIGN KEY (branch) REFERENCES branch_table(id)
  );
''');
    await db.execute(
      'CREATE INDEX fk_employees_company_idx ON employees(company)',
    );
    await db.execute(
      'CREATE INDEX fk_employee_branch_idx ON employees(branch)',
    );
    developer.log('Created table: employees');

    //6.create privilege table
    await db.execute('''
  CREATE TABLE privilege_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT CHECK(length(name) <= 45),
    description TEXT CHECK(length(description) <= 100),
    created_by INTEGER,
    date_created TEXT,
    updated_by INTEGER,
    date_updated TEXT,
    type TEXT CHECK(length(type) <= 12),
    link TEXT CHECK(length(link) <= 120),
    button TEXT CHECK(length(button) <= 20),
    link_lable TEXT UNIQUE CHECK(length(link_lable) <= 60),
    button_lable TEXT CHECK(length(button_lable) <= 20),
    vendor_only TEXT DEFAULT 'N' CHECK(length(vendor_only) <= 1),
    sync_key TEXT CHECK(length(sync_key) <= 36),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id)
  );
''');
    await db.execute(
      'CREATE INDEX fk_pt_created_by_idx ON privilege_table(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_pt_updated_by_idx ON privilege_table(updated_by)',
    );
    developer.log('Created table: privilege_table');

    //7.Create role table
    await db.execute('''
  CREATE TABLE role_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT CHECK(length(name) <= 200),
    created_by INTEGER,
    updated_by INTEGER,
    description TEXT CHECK(length(description) <= 200),
    date_created TEXT,
    date_updated TEXT,
    company INTEGER,
    sync_key TEXT CHECK(length(sync_key) <= 36),
    UNIQUE (name, company),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id),
    FOREIGN KEY (company) REFERENCES company_table(id)
  );
''');
    await db.execute(
      'CREATE INDEX fk_rt_created_by_idx ON role_table(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_rt_updated_by_idx ON role_table(updated_by)',
    );
    await db.execute(
      'CREATE INDEX fk_role_table_company_idx ON role_table(company)',
    );
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
    sync_key TEXT CHECK(length(sync_key) <= 36),
    FOREIGN KEY (role_table_id) REFERENCES role_table(id),
    FOREIGN KEY (privilege_table_id) REFERENCES privilege_table(id),
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id)
  );
''');
    await db.execute(
      'CREATE INDEX fk_rt_has_pt_rt1_idx ON role_privilege(role_table_id)',
    );
    await db.execute(
      'CREATE INDEX fk_rt_has_pt_pt1_idx ON role_privilege(privilege_table_id)',
    );
    await db.execute(
      'CREATE INDEX fk_role_privilege_employees1_idx ON role_privilege(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_role_privilege_employees2_idx ON role_privilege(updated_by)',
    );
    developer.log('Created table: role_privilege');

    // 9. Create user_table
    await db.execute('''
      CREATE TABLE user_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        password TEXT NOT NULL,
        employees_id INTEGER,
        created_by INTEGER,
        updated_by INTEGER,
        date_created TEXT,
        date_updated TEXT,
        usercol TEXT CHECK(length(usercol) <= 45),
        branch INTEGER,
        status TEXT CHECK(length(status) <= 12),
        super_user TEXT CHECK(length(super_user) <= 1),
        password_last_updated TEXT,
        company INTEGER,
        user_name TEXT CHECK(length(user_name) <= 45),
        type TEXT DEFAULT 'Company' CHECK(length(type) <= 20),
        salesperson INTEGER,
        confirmation_code TEXT CHECK(length(confirmation_code) <= 10),
        confirmations_expire_time TEXT,
        user_email TEXT CHECK(length(user_email) <= 100),
        table_number TEXT CHECK(length(table_number) <= 45),
        sync_key TEXT CHECK(length(sync_key) <= 36),
        FOREIGN KEY (employees_id) REFERENCES employees(id),
        FOREIGN KEY (created_by) REFERENCES employees(id),
        FOREIGN KEY (updated_by) REFERENCES employees(id),
        FOREIGN KEY (branch) REFERENCES branch_table(id),
        FOREIGN KEY (company) REFERENCES company_table(id),
        FOREIGN KEY (salesperson) REFERENCES salespersons(id)
      );
    ''');
    await db.execute(
      'CREATE INDEX fk_user_employees1_idx ON user_table(employees_id)',
    );
    await db.execute(
      'CREATE INDEX fk_user_employees2_idx ON user_table(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_user_employees3_idx ON user_table(updated_by)',
    );
    await db.execute('CREATE INDEX fk_user_branch_idx ON user_table(branch)');
    await db.execute(
      'CREATE INDEX fk_user_table_company_idx ON user_table(company)',
    );
    await db.execute(
      'CREATE INDEX fk_user_table_salesperson_idx ON user_table(salesperson)',
    );
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
    sync_key TEXT CHECK(length(sync_key) <= 36),
    FOREIGN KEY (role_table_id) REFERENCES role_table(id),
    FOREIGN KEY (user_id) REFERENCES user_table(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES employees(id),
    FOREIGN KEY (updated_by) REFERENCES employees(id)
  );
''');
    await db.execute(
      'CREATE INDEX fk_role_table_has_user_user1_idx ON user_role(user_id)',
    );
    await db.execute(
      'CREATE INDEX fk_role_table_has_user_role_table1_idx ON user_role(role_table_id)',
    );
    await db.execute(
      'CREATE INDEX fk_user_role_employees1_idx ON user_role(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_user_role_employees2_idx ON user_role(updated_by)',
    );
    developer.log('Created table: user_role');

    //11.Create items table
    await db.execute('''
CREATE TABLE items_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  items_id TEXT CHECK(length(items_id) <= 200),
  item_description TEXT CHECK(length(item_description) <= 200),
  unit_of_measure INTEGER,
  unit_price REAL,
  taxable TEXT CHECK(length(taxable) <= 1),
  tax_rate_area INTEGER,
  barcode TEXT CHECK(length(barcode) <= 45),
  company INTEGER,
  margin_rate REAL,
  margin_type TEXT CHECK(length(margin_type) <= 1),
  reorder_point REAL,
  item_image TEXT CHECK(length(item_image) <= 200),
  reference_id TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  UNIQUE (items_id, item_description, company),
  FOREIGN KEY (company) REFERENCES company_table(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id),
  FOREIGN KEY (tax_rate_area) REFERENCES tax_rate_area(id)
);
''');
    developer.log('Created table: items_table');

    // Indexes for faster lookup
    await db.execute(
      'CREATE INDEX fk_items_table_uom_idx ON items_table(unit_of_measure)',
    );
    await db.execute(
      'CREATE INDEX fk_items_table_company_idx ON items_table(company)',
    );
    await db.execute(
      'CREATE INDEX fk_items_table_tax_rate_area_idx ON items_table(tax_rate_area)',
    );
    await db.execute('CREATE INDEX idx_items_barcode ON items_table(barcode)');
    await db.execute('CREATE INDEX idx_items_id ON items_table(items_id)');
    developer.log('Created indexes for items_table');
    //12. Create item unit conversions
    //16c. create item_uom_conversions table
    await db.execute('''
CREATE TABLE item_uom_conversions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  branch INTEGER,
  item_number INTEGER,
  conversion_factor REAL,
  created_by INTEGER,
  date_created TEXT,
  updated_by INTEGER,
  date_updated TEXT,
  from_uom INTEGER,
  to_uom INTEGER,
  uom_structure_level INTEGER,
  inverse_conversion REAL,
  company INTEGER,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id) ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES user_table(id) ON UPDATE CASCADE,
  FOREIGN KEY (from_uom) REFERENCES udc_details(id),
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (to_uom) REFERENCES udc_details(id),
  FOREIGN KEY (updated_by) REFERENCES user_table(id) ON UPDATE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_from_uom_idx ON item_uom_conversions(from_uom)',
    );
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_to_uom_idx ON item_uom_conversions(to_uom)',
    );
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_branch_idx ON item_uom_conversions(branch)',
    );
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_itemNumber_idx ON item_uom_conversions(item_number)',
    );
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_created_by_idx ON item_uom_conversions(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_updated_by_idx ON item_uom_conversions(updated_by)',
    );
    await db.execute(
      'CREATE INDEX fk_item_uom_conversions_company_idx ON item_uom_conversions(company)',
    );
    developer.log('Created table: item_uom_conversions');

    // 13. Create items in branch table
    await db.execute('''
CREATE TABLE items_in_branch (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_number INTEGER,
  branch INTEGER,
  unit_price REAL,
  quantity_available REAL,
  company INTEGER,
  unit_of_measure INTEGER,
  margin_rate REAL,
  margin_type TEXT CHECK(length(margin_type) <= 1),
  reorder_point REAL,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id)
);
''');
    await db.execute(
      'CREATE INDEX fk_items_in_branch_item_number_idx ON items_in_branch(item_number)',
    );
    await db.execute(
      'CREATE INDEX fk_items_in_branch_branch_idx ON items_in_branch(branch)',
    );
    await db.execute(
      'CREATE INDEX fk_items_in_branch_company_idx ON items_in_branch(company)',
    );
    await db.execute(
      'CREATE INDEX fk_items_in_branch_uom_idx ON items_in_branch(unit_of_measure)',
    );
    developer.log('Created table: items_in_branch');

    // 14. Create system_constant table
    await db.execute('''
      CREATE TABLE system_constant (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apply_lot_mgm TEXT CHECK(length(apply_lot_mgm) <= 1),
        apply_location_mgm TEXT CHECK(length(apply_location_mgm) <= 1),
        interface_customer TEXT CHECK(length(interface_customer) <= 1),
        interface_employee TEXT CHECK(length(interface_employee) <= 1),
        decimal_places INTEGER,
        date_last_updated TEXT,
        time_last_updated TEXT,
        ubpdated_by INTEGER,
        generate_barcode_for_item TEXT CHECK(length(generate_barcode_for_item) <= 1),
        company INTEGER,
        rate_vat_percentage REAL,
        rate_with_percentage REAL,
        with_hold_initials REAL,
        auto_sales_price TEXT DEFAULT 'N' CHECK(length(auto_sales_price) <= 1),
        lot_type INTEGER,
        location_category_level INTEGER DEFAULT 1,
        lot_qty_auto_for_sales TEXT DEFAULT 'Y' CHECK(length(lot_qty_auto_for_sales) <= 1),
        discount_display TEXT DEFAULT 'Y' CHECK(length(discount_display) <= 1),
        tax_info_display TEXT DEFAULT 'Y' CHECK(length(tax_info_display) <= 1),
        reorder_point_uom_type TEXT DEFAULT 'I' CHECK(length(reorder_point_uom_type) <= 1),
        expiration_date_left INTEGER,
        tot_vat TEXT CHECK(length(tot_vat) <= 1),
        currency_code TEXT DEFAULT 'Birr' CHECK(length(currency_code) <= 10),
        pos_integrated TEXT DEFAULT 'N' CHECK(length(pos_integrated) <= 1),
        apply_overhead_cost TEXT DEFAULT 'N' CHECK(length(apply_overhead_cost) <= 1),
        attached_branch_only TEXT DEFAULT 'N' CHECK(length(attached_branch_only) <= 1),
        days_left INTEGER,
        is_synced INTEGER DEFAULT 1,
        last_sync_time INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        sync_key TEXT CHECK(length(sync_key) <= 36),
        FOREIGN KEY (company) REFERENCES company_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (lot_type) REFERENCES udc_details (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
        FOREIGN KEY (ubpdated_by) REFERENCES user_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    await db.execute(
      'CREATE INDEX fk_system_constant_ubpdated_by_idx ON system_constant(ubpdated_by)',
    );
    await db.execute(
      'CREATE INDEX fk_system_constant_company_idx ON system_constant(company)',
    );
    await db.execute(
      'CREATE INDEX fk_system_constant_lt_type_idx ON system_constant(lot_type)',
    );
    developer.log('Created table: system_constant');

    //15.create location master
    await db.execute('''
CREATE TABLE location_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  branch INTEGER,
  code_01 TEXT CHECK(length(code_01) <= 30),
  code_02 TEXT CHECK(length(code_02) <= 30),
  code_03 TEXT CHECK(length(code_03) <= 30),
  code_04 TEXT CHECK(length(code_04) <= 30),
  code_05 TEXT CHECK(length(code_05) <= 30),
  code_06 TEXT CHECK(length(code_06) <= 30),
  code_07 TEXT CHECK(length(code_07) <= 30),
  code_08 TEXT CHECK(length(code_08) <= 30),
  code_09 TEXT CHECK(length(code_09) <= 30),
  code_10 TEXT CHECK(length(code_10) <= 30),
  created_by INTEGER,
  date_created TEXT,
  updated_by INTEGER,
  date_updated TEXT,
  company INTEGER,
  location_description TEXT CHECK(length(location_description) <= 300),
  margin_rate REAL,
  margin_type TEXT CHECK(length(margin_type) <= 1),
  reorder_point REAL,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id) ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES user_table(id) ON UPDATE CASCADE,
  FOREIGN KEY (updated_by) REFERENCES user_table(id) ON UPDATE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX fk_location_master_branch_idx ON location_master(branch)',
    );
    await db.execute(
      'CREATE INDEX fk_location_master_created_by_idx ON location_master(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_location_master_updated_by_idx ON location_master(updated_by)',
    );
    await db.execute(
      'CREATE INDEX fk_location_master_company_idx ON location_master(company)',
    );
    developer.log('Created table: location_master');

    //16.create item location
    await db.execute('''
CREATE TABLE item_location (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  branch INTEGER,
  item_number INTEGER,
  location INTEGER,
  created_by INTEGER,
  date_created TEXT,
  updated_by INTEGER,
  date_updated TEXT,
  quantity_on_hand REAL,
  company INTEGER,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (location) REFERENCES location_master(id) ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES user_table(id) ON UPDATE CASCADE,
  FOREIGN KEY (updated_by) REFERENCES user_table(id) ON UPDATE CASCADE,
  FOREIGN KEY (company) REFERENCES company_table(id) ON UPDATE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX fk_item_locations_branch_idx ON item_location(branch)',
    );
    await db.execute(
      'CREATE INDEX fk_item_locations_itemNumber_idx ON item_location(item_number)',
    );
    await db.execute(
      'CREATE INDEX fk_item_locations_created_by_idx ON item_location(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_item_locations_updated_by_idx ON item_location(updated_by)',
    );
    await db.execute(
      'CREATE INDEX fk_item_locations_company_idx ON item_location(company)',
    );
    await db.execute(
      'CREATE INDEX fk_item_locations_location_idx ON item_location(location)',
    );
    developer.log('Created table: item_location');

    //16b. create item_master table
    await db.execute('''
CREATE TABLE item_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_description TEXT NOT NULL CHECK(length(item_description) <= 200),
  company_category INTEGER,
  category_code_01 INTEGER,
  category_code_02 INTEGER,
  category_code_03 INTEGER,
  category_code_04 INTEGER,
  category_code_05 INTEGER,
  category_code_06 INTEGER,
  category_code_07 INTEGER,
  category_code_08 INTEGER,
  category_code_09 INTEGER,
  category_code_10 INTEGER,
  created_by_flag TEXT DEFAULT 'Y' CHECK(length(created_by_flag) <= 1),
  defualt_uom INTEGER,
  taxable_flag TEXT DEFAULT 'Y' CHECK(length(taxable_flag) <= 1),
  sync_key TEXT CHECK(length(sync_key) <= 36),
  UNIQUE (item_description, company_category),
  FOREIGN KEY (company_category) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_01) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_02) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_03) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_04) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_05) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_06) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_07) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_08) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_09) REFERENCES udc_details(id),
  FOREIGN KEY (category_code_10) REFERENCES udc_details(id),
  FOREIGN KEY (defualt_uom) REFERENCES udc_details(id)
);
''');
    await db.execute(
      'CREATE INDEX fk_item_master_company_category_idx ON item_master(company_category)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_1_idx ON item_master(category_code_01)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_2_idx ON item_master(category_code_02)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_3_idx ON item_master(category_code_03)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_4_idx ON item_master(category_code_04)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_5_idx ON item_master(category_code_05)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_6_idx ON item_master(category_code_06)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_7_idx ON item_master(category_code_07)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_8_idx ON item_master(category_code_08)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_9_idx ON item_master(category_code_09)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_category_cd_10_idx ON item_master(category_code_10)',
    );
    await db.execute(
      'CREATE INDEX fk_item_master_defualt_uom_idx ON item_master(defualt_uom)',
    );
    developer.log('Created table: item_master');

    //17.create lot master
    await db.execute('''
CREATE TABLE lot_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_number INTEGER,
  lot_number INTEGER,
  unit_price REAL,
  quantity_available REAL,
  company INTEGER,
  date_effective TEXT,
  date_expiration TEXT,
  date_received TEXT,
  branch INTEGER,
  location INTEGER,
  lot_status INTEGER,
  batch_number_supplier TEXT CHECK(length(batch_number_supplier) <= 50),
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (location) REFERENCES item_location(id),
  FOREIGN KEY (lot_status) REFERENCES udc_details(id)
);
''');
    await db.execute(
      'CREATE INDEX fk_lot_master_company_idx ON lot_master(company)',
    );
    await db.execute(
      'CREATE INDEX fk_lot_master_item_branch_idx ON lot_master(item_number)',
    );
    await db.execute(
      'CREATE INDEX fk_lot_master_branch_idx ON lot_master(branch)',
    );
    await db.execute(
      'CREATE INDEX fk_lot_master_item_location_idx ON lot_master(location)',
    );
    await db.execute(
      'CREATE INDEX fk_lot_master_lot_status_idx ON lot_master(lot_status)',
    );
    developer.log('Created table: lot_master');

    //18.create item_cost_table
    await db.execute('''
CREATE TABLE item_cost (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_number INTEGER,
  amount_unit_cost REAL,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,
  amount_unit_cost_base REAL,
  overhead_unit_cost REAL,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (user_id) REFERENCES user_table(id)
);
''');
    await db.execute(
      'CREATE INDEX fk_item_cost_table_company_idx ON item_cost(company)',
    );
    await db.execute(
      'CREATE INDEX fk_item_cost_table_item_number_idx ON item_cost(item_number)',
    );
    await db.execute(
      'CREATE INDEX fk_item_cost_table_user_id_idx ON item_cost(user_id)',
    );
    developer.log('Created table: item_cost');

    //19.create supplier table
    await db.execute('''
  CREATE TABLE supplier_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_name TEXT CHECK(length(supplier_name) <= 50),
    city TEXT CHECK(length(city) <= 45),
    region TEXT CHECK(length(region) <= 45),
    state TEXT CHECK(length(state) <= 45),
    country TEXT CHECK(length(country) <= 45),
    phone_no_1 TEXT CHECK(length(phone_no_1) <= 45),
    phone_no_2 TEXT CHECK(length(phone_no_2) <= 45),
    address_line TEXT CHECK(length(address_line) <= 200),
    email TEXT CHECK(length(email) <= 200),
    company INTEGER,
    created_by INTEGER,
    date_created TEXT,
    user_id INTEGER,
    date_updated TEXT,
    tin_number TEXT CHECK(length(tin_number) <= 45),
    contact_person TEXT CHECK(length(contact_person) <= 50),
    contact_title TEXT CHECK(length(contact_title) <= 10),
    defaults_value TEXT DEFAULT 'N' CHECK(length(defaults_value) <= 1),
    sync_key TEXT CHECK(length(sync_key) <= 36),
    FOREIGN KEY (company) REFERENCES company_table (id),
    FOREIGN KEY (created_by) REFERENCES user_table (id),
    FOREIGN KEY (user_id) REFERENCES user_table (id)
  );
''');
    await db.execute(
      'CREATE INDEX fk_supplier_table_company_idx ON supplier_table(company)',
    );
    await db.execute(
      'CREATE INDEX fk_supplier_table_created_by_idx ON supplier_table(created_by)',
    );
    await db.execute(
      'CREATE INDEX fk_supplier_table_user_id_idx ON supplier_table(user_id)',
    );

    developer.log('Created table: supplier_table');

    //20.create purchase_order_header table
    await db.execute('''
  CREATE TABLE purchase_order_header (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_id INTEGER,
    date_transation TEXT,
    date_delivery TEXT,
    po_receive_status INTEGER,
    company INTEGER,
    taxable_amount REAL,
    tax_amount REAL,
    amount_withhold REAL,
    amount_discount REAL,
    amount_gross REAL,
    amount_other_costs REAL,
    amount_grand_total_cost REAL,
    payment_status INTEGER,
    payment_instrument INTEGER,
    user_id INTEGER,
    date_updated TEXT,
    amount_open_credit REAL,
    order_number INTEGER,
    payment_term INTEGER,
    order_type INTEGER,
    credit_due_date TEXT,
    invoice_number TEXT CHECK (length(invoice_number) <= 150),
    sync_key TEXT CHECK(length(sync_key) <= 36),

    -- FOREIGN KEYS
    CONSTRAINT fk_poh_order_type FOREIGN KEY (order_type) REFERENCES udc_details (id),
    CONSTRAINT fk_purchase_order_header_company FOREIGN KEY (company) REFERENCES company_table (id),
    CONSTRAINT fk_purchase_order_header_po_rcv_sts FOREIGN KEY (po_receive_status) REFERENCES udc_details (id),
    CONSTRAINT fk_purchase_order_header_pymnt_inst FOREIGN KEY (payment_instrument) REFERENCES udc_details (id),
    CONSTRAINT fk_purchase_order_header_pymnt_sts FOREIGN KEY (payment_status) REFERENCES udc_details (id),
    CONSTRAINT fk_purchase_order_header_user_id FOREIGN KEY (user_id) REFERENCES user_table (id),
    CONSTRAINT fk_purchase_order_supplier_id FOREIGN KEY (supplier_id) REFERENCES supplier_table (id)
  );

CREATE INDEX fk_purchase_order_header_company_idx ON purchase_order_header(company);
CREATE INDEX fk_purchase_order_header_supplier_id_idx ON purchase_order_header(supplier_id);
CREATE INDEX fk_purchase_order_header_user_id_idx ON purchase_order_header(user_id);
CREATE INDEX fk_purchase_order_header_po_rcv_sts_idx ON purchase_order_header(po_receive_status);
CREATE INDEX fk_purchase_order_header_pymnt_sts_idx ON purchase_order_header(payment_status);
CREATE INDEX fk_purchase_order_header_pymnt_inst_idx ON purchase_order_header(payment_instrument);
CREATE INDEX fk_poh_order_type_idx ON purchase_order_header(order_type);
''');

    developer.log('Created table: purchase_order_header');

    //21.create purchase_order_details table
    await db.execute('''
  CREATE TABLE purchase_order_detail (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    po_header INTEGER,
    item_number INTEGER,
    po_receive_status INTEGER,
    quantity_transaction REAL,
    unit_cost REAL,
    amount_extended_cost REAL,
    quantity_open REAL,
    amount_open REAL,
    quantity_recieved REAL,
    amount_received REAL,
    date_received TEXT,
    date_delivery TEXT,
    company INTEGER,
    user_id INTEGER,
    date_updated TEXT,
    date_effective TEXT,
    date_expiration TEXT,
    unit_of_measure INTEGER,
    batch_number_supplier TEXT CHECK (length(batch_number_supplier) <= 50),
    sync_key TEXT CHECK(length(sync_key) <= 36),

    -- FOREIGN KEYS
    CONSTRAINT fk_purchase_order_detail_company FOREIGN KEY (company) REFERENCES company_table (id),
    CONSTRAINT fk_purchase_order_detail_itm_nmbr FOREIGN KEY (item_number) REFERENCES items_table (id),
    CONSTRAINT fk_purchase_order_detail_po_rcv_sts FOREIGN KEY (po_receive_status) REFERENCES udc_details (id),
    CONSTRAINT fk_purchase_order_detail_user_id FOREIGN KEY (user_id) REFERENCES user_table (id),
    CONSTRAINT fk_purchase_order_po_header FOREIGN KEY (po_header) REFERENCES purchase_order_header (id),
    CONSTRAINT fk_purchase_order_uom FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );

CREATE INDEX fk_purchase_order_detail_company_idx ON purchase_order_detail(company);
CREATE INDEX fk_purchase_order_detail_po_header_idx ON purchase_order_detail(po_header);
CREATE INDEX fk_purchase_order_detail_user_id_idx ON purchase_order_detail(user_id);
CREATE INDEX fk_purchase_order_detail_po_rcv_sts_idx ON purchase_order_detail(po_receive_status);
CREATE INDEX fk_purchase_order_detail_itm_nmbr_idx ON purchase_order_detail(item_number);
CREATE INDEX fk_purchase_order_uom_idx ON purchase_order_detail(unit_of_measure);
''');

    developer.log('Created table: purchase_order_detail');

    //22.create purchase_order_receiver table
    await db.execute('''
  CREATE TABLE purchase_order_receiver (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    po_detail INTEGER,
    item_number INTEGER,
    quantity_transaction REAL,
    unit_cost REAL,
    amount_extended_cost REAL,
    quantity_open REAL,
    amount_open REAL,
    quantity_recieved REAL,
    amount_received REAL,
    date_received TEXT,
    company INTEGER,
    user_id INTEGER,
    date_updated TEXT,
    branch_recieved INTEGER,
    date_effective TEXT,
    date_expiration TEXT,
    location INTEGER,
    unit_of_measure INTEGER,
    batch_number_supplier TEXT CHECK (length(batch_number_supplier) <= 50),
    sync_key TEXT CHECK(length(sync_key) <= 36),

    -- FOREIGN KEYS
    CONSTRAINT fk_purchase_order_po_detail FOREIGN KEY (po_detail) REFERENCES purchase_order_detail (id),
    CONSTRAINT fk_purchase_order_receiver_brnch_rcvd FOREIGN KEY (branch_recieved) REFERENCES branch_table (id),
    CONSTRAINT fk_purchase_order_receiver_company FOREIGN KEY (company) REFERENCES company_table (id),
    CONSTRAINT fk_purchase_order_receiver_itm_nmbr FOREIGN KEY (item_number) REFERENCES items_table (id),
    CONSTRAINT fk_purchase_order_receiver_location FOREIGN KEY (location) REFERENCES item_location (id),
    CONSTRAINT fk_purchase_order_receiver_user_id FOREIGN KEY (user_id) REFERENCES user_table (id),
    CONSTRAINT fk_purchase_order_rsv_uom FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );

CREATE INDEX fk_purchase_order_receiver_company_idx ON purchase_order_receiver(company);
CREATE INDEX fk_purchase_order_receiver_po_detail_idx ON purchase_order_receiver(po_detail);
CREATE INDEX fk_purchase_order_receiver_user_id_idx ON purchase_order_receiver(user_id);
CREATE INDEX fk_purchase_order_receiver_brnch_rcvd_idx ON purchase_order_receiver(branch_recieved);
CREATE INDEX fk_purchase_order_receiver_itm_nmbr_idx ON purchase_order_receiver(item_number);
CREATE INDEX fk_purchase_order_receiver_location_idx ON purchase_order_receiver(location);
CREATE INDEX fk_purchase_order_rsv_uom_idx ON purchase_order_receiver(unit_of_measure);
''');

    developer.log('Created table: purchase_order_receiver');

    //23.create item_transactions table
    await db.execute('''
  CREATE TABLE item_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_location INTEGER,
    created_by INTEGER,
    date_created TEXT,
    quantity_transaction REAL,
    remark TEXT CHECK(length(remark) <= 50),
    company INTEGER,
    lot_number INTEGER,
    transaction_type INTEGER,
    item_branch INTEGER,
    transaction_number INTEGER,
    item_number INTEGER,
    lot_status INTEGER,
    branch INTEGER,
    supplier INTEGER,
    customer INTEGER,
    order_type INTEGER,
    unit_of_measure INTEGER,
    before_store_quantity_available REAL,
    unit_cost REAL,
    amount_cost REAL,
    before_amount_cost REAL,
    sync_key TEXT CHECK(length(sync_key) <= 36),
    FOREIGN KEY (item_location) REFERENCES item_location (id) ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES user_table (id) ON UPDATE CASCADE,
    FOREIGN KEY (company) REFERENCES company_table (id) ON UPDATE CASCADE,
    FOREIGN KEY (lot_number) REFERENCES lot_master (id),
    FOREIGN KEY (transaction_type) REFERENCES udc_details (id),
    FOREIGN KEY (item_branch) REFERENCES items_in_branch (id),
    FOREIGN KEY (item_number) REFERENCES items_table (id),
    FOREIGN KEY (lot_status) REFERENCES udc_details (id),
    FOREIGN KEY (branch) REFERENCES branch_table (id),
    FOREIGN KEY (supplier) REFERENCES supplier_table (id),
    FOREIGN KEY (customer) REFERENCES customer_table (id),
    FOREIGN KEY (order_type) REFERENCES udc_details (id),
    FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );

CREATE INDEX fk_item_transactions_item_location_idx ON item_transactions(item_location);
CREATE INDEX fk_item_transactions_created_by_idx ON item_transactions(created_by);
CREATE INDEX fk_item_transactions_company_idx ON item_transactions(company);
CREATE INDEX fk_item_transactions_lot_number_idx ON item_transactions(lot_number);
CREATE INDEX fk_item_transactions_transaction_type_idx ON item_transactions(transaction_type);
CREATE INDEX fk_item_transactions_item_branch_idx ON item_transactions(item_branch);
CREATE INDEX fk_item_transactions_item_number_idx ON item_transactions(item_number);
CREATE INDEX fk_item_transactions_lot_status_idx ON item_transactions(lot_status);
CREATE INDEX fk_item_transactions_branch_idx ON item_transactions(branch);
CREATE INDEX fk_item_transactions_supplier_idx ON item_transactions(supplier);
CREATE INDEX fk_item_transactions_customer_idx ON item_transactions(customer);
CREATE INDEX fk_item_transactions_order_type_idx ON item_transactions(order_type);
CREATE INDEX fk_item_transactions_unit_of_measure_idx ON item_transactions(unit_of_measure);
''');
    developer.log('Created table: item_transactions');

    //24. create next number table
    await db.execute('''
  CREATE TABLE next_number (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    next_number_code TEXT NOT NULL CHECK(length(next_number_code) <= 2),
    next_number_description TEXT NOT NULL CHECK(length(next_number_description) <= 30),
    next_number INTEGER NOT NULL DEFAULT 1,
    company INTEGER,
    sync_key TEXT CHECK(length(sync_key) <= 36),
    CONSTRAINT fk_next_number_company FOREIGN KEY (company) REFERENCES company_table (id)
  );
''');
    await db.execute('''
CREATE INDEX fk_next_number_company_idx ON next_number(company);
''');
    developer.log('Created table: next_number');

    //25. create lot_coloring table
    await db.execute('''
  CREATE TABLE lot_expiration_colors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_number INTEGER,
    branch INTEGER,
    days_maximum INTEGER,
    color_type INTEGER,
    company INTEGER,
    description TEXT CHECK(length(description) <= 50),
    days_minimum INTEGER,
    active_for_sales_flag TEXT DEFAULT 'Y' CHECK(length(active_for_sales_flag) <= 1),
    lot_exp_level TEXT CHECK(length(lot_exp_level) <= 1),
    sync_key TEXT CHECK(length(sync_key) <= 36),
    CONSTRAINT fk_lot_expiration_colors_itm_nmbr FOREIGN KEY (item_number) REFERENCES items_table (id),
    CONSTRAINT fk_lot_expiration_colors_branch FOREIGN KEY (branch) REFERENCES branch_table (id),
    CONSTRAINT fk_lot_expiration_colors_clr_typ FOREIGN KEY (color_type) REFERENCES udc_details (id),
    CONSTRAINT fk_lot_expiration_colors_company FOREIGN KEY (company) REFERENCES company_table (id)
  );
''');
    await db.execute('''
CREATE INDEX fk_lot_expiration_colors_company_idx ON lot_expiration_colors(company);
CREATE INDEX fk_lot_expiration_colors_itm_nmbr_idx ON lot_expiration_colors(item_number);
CREATE INDEX fk_lot_expiration_colors_branch_idx ON lot_expiration_colors(branch);
CREATE INDEX fk_lot_expiration_colors_clr_typ_idx ON lot_expiration_colors(color_type);
''');
    developer.log('Created table: lot_expiration_colors');

    //26. create sales_order_header table
    await db.execute('''
  CREATE TABLE sales_order_header (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_date TEXT,
  required_date TEXT,
  shipped_date TEXT,
  sales_type TEXT CHECK(length(sales_type) <= 45),
  payment_method TEXT CHECK(length(payment_method) <= 45),
  payment_instrument INTEGER,
  discount TEXT CHECK(length(discount) <= 1),
  add_on TEXT CHECK(length(add_on) <= 1),
  tax REAL,
  with_hold_apply TEXT CHECK(length(with_hold_apply) <= 1),
  withhold_amount REAL,
  discount_amount REAL,
  discount_in_percent REAL,
  reference_note1 TEXT CHECK(length(reference_note1) <= 45),
  reference_note_2 TEXT CHECK(length(reference_note_2) <= 45),
  reference_note3 TEXT CHECK(length(reference_note3) <= 45),
  reference_note4 TEXT CHECK(length(reference_note4) <= 45),
  proforma_flag TEXT CHECK(length(proforma_flag) <= 1),
  proforma_reference TEXT CHECK(length(proforma_reference) <= 100),
  credit_date_topay TEXT,
  fs_number TEXT CHECK(length(fs_number) <= 45),
  void_indicator TEXT CHECK(length(void_indicator) <= 1),
  customer_bill_to INTEGER NOT NULL,
  customer_table_id INTEGER NOT NULL,
  employees_id INTEGER NOT NULL,
  amount_total REAL,
  company INTEGER,
  payment_term INTEGER,
  payment_status INTEGER,
  order_number INTEGER,
  amount_open REAL,
  order_type INTEGER,
  unit_cost REAL,
  amount_cost REAL,
  sales_represent TEXT CHECK(length(sales_represent) <= 150),
  comments_so TEXT,
  comment_ifVoid TEXT,
  return_date TEXT,
  invoice_number TEXT CHECK(length(invoice_number) <= 45),
  branch_value INTEGER,
  sync_key TEXT CHECK(length(sync_key) <= 36),
  FOREIGN KEY (customer_bill_to) REFERENCES customer_table (id),
  FOREIGN KEY (customer_table_id) REFERENCES customer_table (id),
  FOREIGN KEY (employees_id) REFERENCES employees (id),
  FOREIGN KEY (company) REFERENCES company_table (id),
  FOREIGN KEY (payment_instrument) REFERENCES udc_details (id),
  FOREIGN KEY (payment_status) REFERENCES udc_details (id),
  FOREIGN KEY (order_type) REFERENCES udc_details (id),
  FOREIGN KEY (branch_value) REFERENCES branch_table (id)
);
CREATE INDEX fk_sales_order_header_customer_bill_to_idx ON sales_order_header(customer_bill_to);
CREATE INDEX fk_sales_order_header_customer_table_id_idx ON sales_order_header(customer_table_id);
CREATE INDEX fk_sales_order_header_employees_id_idx ON sales_order_header(employees_id);
CREATE INDEX fk_sales_order_header_company_idx ON sales_order_header(company);
CREATE INDEX fk_sales_order_header_payment_instrument_idx ON sales_order_header(payment_instrument);
CREATE INDEX fk_sales_order_header_payment_status_idx ON sales_order_header(payment_status);
CREATE INDEX fk_soh_order_type_idx ON sales_order_header(order_type);
CREATE INDEX fk_soh_branchvalue_idx ON sales_order_header(branch_value);
''');
    developer.log('Created table: sales_order_header');
    //27. create sales_order_details table
    await db.execute('''
  CREATE TABLE sales_order_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unit_price REAL,
    quantity REAL,
    extended_price REAL,
    taxable TEXT CHECK(length(taxable) <= 1),
    reference1 TEXT CHECK(length(reference1) <= 45),
    reference2 TEXT CHECK(length(reference2) <= 45),
    sales_order_header_id INTEGER NOT NULL,
    items_table_id INTEGER NOT NULL,
    item_in_branch INTEGER,
    company INTEGER,
    lot_number INTEGER,
    unit_cost REAL,
    amount_cost REAL,
    unit_of_measure INTEGER,
    sync_key TEXT CHECK(length(sync_key) <= 36),
    UNIQUE (id, items_table_id),
    CONSTRAINT fk_sales_order_details_soh FOREIGN KEY (sales_order_header_id) REFERENCES sales_order_header (id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_order_details_items FOREIGN KEY (items_table_id) REFERENCES items_table (id),
    CONSTRAINT fk_sales_order_details_branch FOREIGN KEY (item_in_branch) REFERENCES items_in_branch (id),
    CONSTRAINT fk_sales_order_details_company FOREIGN KEY (company) REFERENCES company_table (id),
    CONSTRAINT fk_sales_order_details_lot FOREIGN KEY (lot_number) REFERENCES lot_master (id),
    CONSTRAINT fk_sales_order_details_uom FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );
  CREATE INDEX fk_sales_order_details_soh_idx ON sales_order_details(sales_order_header_id);
  CREATE INDEX fk_sales_order_details_items_idx ON sales_order_details(items_table_id);
  CREATE INDEX fk_sales_order_details_branch_idx ON sales_order_details(item_in_branch);
  CREATE INDEX fk_sales_order_details_company_idx ON sales_order_details(company);
  CREATE INDEX fk_sales_order_details_lot_idx ON sales_order_details(lot_number);
  CREATE INDEX fk_sales_order_details_uom_idx ON sales_order_details(unit_of_measure);
''');
    developer.log('Created table: sales_order_details');

    //invoice header table
    await db.execute('''
CREATE TABLE invoice_history_header (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fs_number TEXT CHECK(length(fs_number) <= 12),
  customer_name TEXT CHECK(length(customer_name) <= 45),
  tin_number TEXT CHECK(length(tin_number) <= 45),
  phone_number TEXT CHECK(length(phone_number) <= 45),
  country TEXT CHECK(length(country) <= 45),
  city TEXT CHECK(length(city) <= 45),
  region TEXT CHECK(length(region) <= 45),
  tax_amount REAL,
  withhold_amount REAL,
  total_amount REAL,
  date_transaction TEXT, -- store as ISO8601 string (e.g., "2025-11-13")
  sales_person TEXT CHECK(length(sales_person) <= 255),
  mrc_number TEXT CHECK(length(mrc_number) <= 45),
  discount_amount REAL,
  amount_beforeTax REAL,
  company INTEGER,
  quot_number INTEGER,
  sales_number INTEGER,
  invoice_number TEXT CHECK(length(invoice_number) <= 45),
  sync_key TEXT CHECK(length(sync_key) <= 36),
  CONSTRAINT fk_invoice_history_header_company FOREIGN KEY (company) REFERENCES company_table(id)
);
CREATE INDEX fk_invoice_history_header_company_idx ON invoice_history_header(company);
''');
    developer.log('Created table: invoice_history_header');
    //invoice for detail
    await db.execute('''
CREATE TABLE invoice_history_detail (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_history INTEGER,
  item TEXT CHECK(length(item) <= 45),
  unit_of_measure TEXT CHECK(length(unit_of_measure) <= 45),
  quantity_transaction REAL,
  amount_unit_price REAL,
  amount_extended_price REAL,
  company INTEGER,
  date_experied TEXT CHECK(length(date_experied) <= 45),
  batch_number TEXT CHECK(length(batch_number) <= 50),
  sync_key TEXT CHECK(length(sync_key) <= 36),
  CONSTRAINT fk_invc_hstry_dtl_invc_hstry FOREIGN KEY (invoice_history) REFERENCES invoice_history_header(id),
  CONSTRAINT fk_invoice_history_dtl_company FOREIGN KEY (company) REFERENCES company_table(id)
);
CREATE INDEX fk_invc_hstry_dtl_invc_hstry_idx ON invoice_history_detail(invoice_history);
CREATE INDEX fk_invoice_history_dtl_company_idx ON invoice_history_detail(company);
''');
    developer.log('Created table: invoice_history_detail');

    //sales person table
    await db.execute('''
CREATE TABLE salespersons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  referral_code TEXT NOT NULL,
  parent_salesperson_id INTEGER,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  UNIQUE (uuid),
  UNIQUE (email),
  UNIQUE (phone_number),
  UNIQUE (referral_code),

  FOREIGN KEY (parent_salesperson_id) REFERENCES salespersons(id)
);
''');
    developer.log('Created table: salespersons');

    // create sales retrun header table
    await db.execute('''
  CREATE TABLE sales_return_header (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  order_date TEXT,
  required_date TEXT,
  shipped_date TEXT,
  return_date TEXT,

  sales_type TEXT CHECK(length(sales_type) <= 45),
  payment_method TEXT CHECK(length(payment_method) <= 45),
  payment_instrument INTEGER,
  discount TEXT CHECK(length(discount) <= 1),
  add_on TEXT CHECK(length(add_on) <= 1),
  tax REAL,
  with_hold_apply TEXT CHECK(length(with_hold_apply) <= 1),
  withhold_amount REAL,
  discount_amount REAL,
  discount_in_percent REAL,

  reference_note1 TEXT CHECK(length(reference_note1) <= 45),
  reference_note_2 TEXT CHECK(length(reference_note_2) <= 45),
  reference_note3 TEXT CHECK(length(reference_note3) <= 45),
  reference_note4 TEXT CHECK(length(reference_note4) <= 45),

  comments_sales TEXT,
  credit_date_topay TEXT,
  fs_number TEXT CHECK(length(fs_number) <= 45),
  void_indicator TEXT CHECK(length(void_indicator) <= 1),

  customer_bill_to INTEGER NOT NULL,
  customer_table_id INTEGER NOT NULL,
  employees_id INTEGER NOT NULL,

  amount_total REAL,
  company INTEGER,
  payment_term INTEGER,
  payment_status INTEGER,
  order_number INTEGER,
  amount_open REAL,
  order_type INTEGER,
  unit_cost REAL,
  amount_cost REAL,
  return_status INTEGER,
  sales_represent TEXT CHECK(length(sales_represent) <= 150),
  comment_for_return TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_sales_return_header_customer_table FOREIGN KEY (customer_bill_to) REFERENCES customer_table(id),
  CONSTRAINT fk_sales_return_header_customer_table1 FOREIGN KEY (customer_table_id) REFERENCES customer_table(id),
  CONSTRAINT fk_sales_return_header_employees1 FOREIGN KEY (employees_id) REFERENCES employees(id),
  CONSTRAINT fk_sales_return_header_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_sales_return_header_payment_inst FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  CONSTRAINT fk_sales_return_header_payment_sts FOREIGN KEY (payment_status) REFERENCES udc_details(id),
  CONSTRAINT fk_soh_return_status FOREIGN KEY (order_type) REFERENCES udc_details(id),
  CONSTRAINT fk_sales_return_header_payment_return_status FOREIGN KEY (return_status) REFERENCES udc_details(id)
);
CREATE UNIQUE INDEX idx_sales_return_header_id_unique
ON sales_return_header (id);

CREATE INDEX fk_sales_return_header_customer_table_idx
ON sales_return_header (customer_bill_to);

CREATE INDEX fk_sales_return_header_customer_table1_idx
ON sales_return_header (customer_table_id);

CREATE INDEX fk_sales_return_header_employees1_idx
ON sales_return_header (employees_id);

CREATE INDEX fk_sales_return_header_company_idx
ON sales_return_header (company);

CREATE INDEX fk_sales_return_header_payment_inst_idx
ON sales_return_header (payment_instrument);

CREATE INDEX fk_sales_return_header_payment_sts_idx
ON sales_return_header (payment_status);

CREATE INDEX fk_soh_order_type_idx
ON sales_return_header (order_type);

CREATE INDEX fk_soh_return_status_idx
ON sales_return_header (return_status);

''');
    developer.log('Created table: sales_return_header');
    //sales return detail table
    await db.execute('''
CREATE TABLE sales_return_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  unit_price REAL,
  quantity REAL,
  extended_price REAL,
  taxable TEXT CHECK(length(taxable) <= 1),
  reference1 TEXT CHECK(length(reference1) <= 45),
  reference2 TEXT CHECK(length(reference2) <= 45),
  sales_return_header_id INTEGER NOT NULL,
  items_table_id INTEGER NOT NULL,
  item_in_branch INTEGER,
  company INTEGER,
  lot_number INTEGER,
  unit_cost REAL,
  return_quantity REAL,
  return_amount_cost REAL,
  return_amount_price REAL,
  return_extended_price REAL,
  amount_cost REAL,
  unit_of_measure INTEGER,
  return_status INTEGER,
  return_reason INTEGER,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_sales_return_details_sales_return_header1 FOREIGN KEY (sales_return_header_id) REFERENCES sales_return_header(id),
  CONSTRAINT fk_sales_return_details_items_table1 FOREIGN KEY (items_table_id) REFERENCES items_table(id),
  CONSTRAINT fk_sales_return_details_item_in_branch FOREIGN KEY (item_in_branch) REFERENCES items_in_branch(id),
  CONSTRAINT fk_sales_return_details_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_sales_return_details_lot_number FOREIGN KEY (lot_number) REFERENCES lot_master(id),
  CONSTRAINT fk_sales_return_details_UOM FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id),
  CONSTRAINT fk_sales_return_details_return_status FOREIGN KEY (return_status) REFERENCES udc_details(id),
  CONSTRAINT fk_sales_return_details_return_reason FOREIGN KEY (return_reason) REFERENCES udc_details(id)
);

CREATE UNIQUE INDEX id_UNIQUE ON sales_return_details (id);
CREATE UNIQUE INDEX id_item_UNIQUE ON sales_return_details (id, items_table_id);

CREATE INDEX fk_sales_return_details_items_table1_idx
ON sales_return_details (items_table_id);

CREATE INDEX fk_sales_return_details_sales_return_header1_idx
ON sales_return_details (sales_return_header_id);

CREATE INDEX fk_sales_return_details_item_in_branch_idx
ON sales_return_details (item_in_branch);

CREATE INDEX fk_sales_return_details_company_idx
ON sales_return_details (company);

CREATE INDEX fk_sales_return_details_lot_number_idx
ON sales_return_details (lot_number);

CREATE INDEX fk_sales_return_details_UOM_idx
ON sales_return_details (unit_of_measure);

CREATE INDEX fk_sales_return_details_return_status_idx
ON sales_return_details (return_status);

CREATE INDEX fk_sales_return_details_return_reason_idx
ON sales_return_details (return_reason);

''');
    developer.log('Created table: sales_return_detail');

    //crete proforma header table
    await db.execute('''
CREATE TABLE quote_order_header (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number INTEGER NOT NULL,
  order_date TEXT,
  conversion_date TEXT,
  required_date TEXT,
  shipped_date TEXT,
  sales_type TEXT CHECK(length(sales_type) <= 45),
  quotation_validation_in_days INTEGER DEFAULT 30,
  payment_method TEXT CHECK(length(payment_method) <= 45),
  payment_instrument INTEGER,
  payment_term INTEGER,
  payment_status INTEGER,
  credit_date_topay TEXT,
  currency_code TEXT DEFAULT 'ETB' CHECK(length(currency_code) <= 10),
  exchange_rate REAL DEFAULT 1,
  discount TEXT CHECK(length(discount) <= 1),
  discount_amount REAL,
  discount_in_percent REAL,
  add_on TEXT CHECK(length(add_on) <= 1),
  tax REAL,
  with_hold_apply TEXT CHECK(length(with_hold_apply) <= 1),
  withhold_amount REAL,
  amount_total REAL,
  amount_open REAL,
  unit_cost REAL,
  amount_cost REAL,
  order_type INTEGER,
  order_status TEXT DEFAULT 'Draft' CHECK(length(order_status) <= 50),
  conversion_status TEXT CHECK(length(conversion_status) <= 150),
  prforma_status TEXT CHECK(length(prforma_status) <= 150),
  void_indicator TEXT CHECK(length(void_indicator) <= 1),
  reference_note1 TEXT CHECK(length(reference_note1) <= 45),
  reference_note_2 TEXT CHECK(length(reference_note_2) <= 45),
  reference_note3 TEXT CHECK(length(reference_note3) <= 45),
  reference_note4 TEXT CHECK(length(reference_note4) <= 45),
  external_ref_number TEXT CHECK(length(external_ref_number) <= 100),
  fs_number TEXT CHECK(length(fs_number) <= 45),
  sales_represent TEXT CHECK(length(sales_represent) <= 150),
  converted_items TEXT CHECK(length(converted_items) <= 150),
  customer_bill_to INTEGER NOT NULL,
  customer_table_id INTEGER NOT NULL,
  employees_id INTEGER NOT NULL,
  company INTEGER,
  branch_id INTEGER,
  created_at TEXT,
  updated_at TEXT,
  created_by INTEGER,
  updated_by INTEGER,
  comments_reason TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  CONSTRAINT id_UNIQUE UNIQUE (id),
  CONSTRAINT order_number_UNIQUE UNIQUE (order_number),

  -- FOREIGN KEYS
  CONSTRAINT fk_quote_order_header_customer_table FOREIGN KEY (customer_bill_to) REFERENCES customer_table(id),
  CONSTRAINT fk_quote_order_header_customer_table1 FOREIGN KEY (customer_table_id) REFERENCES customer_table(id),
  CONSTRAINT fk_quote_order_header_employees1 FOREIGN KEY (employees_id) REFERENCES employees(id),
  CONSTRAINT fk_quote_order_header_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_quote_order_header_branch FOREIGN KEY (branch_id) REFERENCES branch_table(id),
  CONSTRAINT fk_quote_order_header_payment_inst FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  CONSTRAINT fk_quote_order_header_payment_sts FOREIGN KEY (payment_status) REFERENCES udc_details(id),
  CONSTRAINT fk_soh_order_type1 FOREIGN KEY (order_type) REFERENCES udc_details(id),
  CONSTRAINT fk_quote_order_header_prforma_sts FOREIGN KEY (prforma_status) REFERENCES udc_details(id)
);

CREATE INDEX fk_quote_order_header_customer_table_idx
ON quote_order_header (customer_bill_to);

CREATE INDEX fk_quote_order_header_customer_table1_idx
ON quote_order_header (customer_table_id);

CREATE INDEX fk_quote_order_header_employees1_idx
ON quote_order_header (employees_id);

CREATE INDEX fk_quote_order_header_company_idx
ON quote_order_header (company);

CREATE INDEX fk_quote_order_header_payment_inst_idx
ON quote_order_header (payment_instrument);

CREATE INDEX fk_quote_order_header_payment_sts_idx
ON quote_order_header (payment_status);

CREATE INDEX fk_soh_order_type1_idx
ON quote_order_header (order_type);

CREATE INDEX fk_quote_order_header_branch_idx
ON quote_order_header (branch_id);
    ''');
    developer.log('Created table: quote_order_header');

    //create quote order detail table
    await db.execute('''
CREATE TABLE quote_order_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quote_order_header_id INTEGER NOT NULL,
  items_table_id INTEGER NOT NULL,
  item_in_branch INTEGER,
  company INTEGER,
  unit_price REAL,
  quantity REAL,
  extended_price REAL,
  unit_cost REAL,
  amount_cost REAL,
  taxable TEXT CHECK(length(taxable) <= 1),
  discount_percent REAL,
  discount_amount REAL,
  unit_of_measure INTEGER,
  line_status TEXT DEFAULT 'Open' CHECK(length(line_status) <= 50),
  reference1 TEXT CHECK(length(reference1) <= 45),
  reference2 TEXT CHECK(length(reference2) <= 45),
  prforma_status INTEGER,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER,
  updated_by INTEGER,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  CONSTRAINT id_UNIQUE UNIQUE (id),
  CONSTRAINT id_item_UNIQUE UNIQUE (id, items_table_id),

  -- FOREIGN KEYS
  CONSTRAINT fk_quote_order_details_quote_order_header1 FOREIGN KEY (quote_order_header_id) REFERENCES quote_order_header(id),
  CONSTRAINT fk_quote_order_details_items_table1 FOREIGN KEY (items_table_id) REFERENCES items_table(id),
  CONSTRAINT fk_quote_order_details_item_in_branch FOREIGN KEY (item_in_branch) REFERENCES items_in_branch(id),
  CONSTRAINT fk_quote_order_details_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_quote_order_details_UOM FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id),
  CONSTRAINT fk_quote_order_details_prforma_status FOREIGN KEY (prforma_status) REFERENCES udc_details(id)
);

CREATE INDEX fk_quote_order_details_quote_order_header1_idx
ON quote_order_details (quote_order_header_id);

CREATE INDEX fk_quote_order_details_item_in_branch_idx
ON quote_order_details (item_in_branch);

CREATE INDEX fk_quote_order_details_company_idx
ON quote_order_details (company);

CREATE INDEX fk_quote_order_details_UOM_idx
ON quote_order_details (unit_of_measure);

CREATE INDEX fk_quote_order_details_prforma_status_idx
ON quote_order_details (prforma_status);

CREATE INDEX fk_quote_order_details_items_table1_idx
ON quote_order_details (items_table_id);
    ''');
    developer.log('Created table: quote_order_details');

    //create credit payment(on purchase)
    await db.execute('''
CREATE TABLE credit_payment_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  po_header INTEGER,
  payment_amount REAL,
  date_payment TEXT,
  payment_instrument INTEGER,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_credit_payment_table_po_header FOREIGN KEY (po_header) REFERENCES purchase_order_header(id),
  CONSTRAINT fk_credit_payment_table_pymnt_instrmnt FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  CONSTRAINT fk_credit_payment_table_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_credit_payment_table_user_id FOREIGN KEY (user_id) REFERENCES user_table(id)
);

CREATE INDEX fk_credit_payment_table_company_idx ON credit_payment_table (company);
CREATE INDEX fk_credit_payment_table_po_header_idx ON credit_payment_table (po_header);
CREATE INDEX fk_credit_payment_table_user_id_idx ON credit_payment_table (user_id);
CREATE INDEX fk_credit_payment_table_pymnt_instrmnt_idx ON credit_payment_table (payment_instrument);
    ''');
    developer.log('Created table: credit_payment_table');

    //create sales credit receipt
    await db.execute('''
CREATE TABLE credit_receipt_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  so_header INTEGER,
  receipt_amount REAL,
  date_receipt TEXT,
  payment_instrument INTEGER,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_credit_receipt_table_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_credit_receipt_table_pymnt_instrmnt FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  CONSTRAINT fk_credit_receipt_table_so_header FOREIGN KEY (so_header) REFERENCES sales_order_header(id),
  CONSTRAINT fk_credit_receipt_table_user_id FOREIGN KEY (user_id) REFERENCES user_table(id)
);

CREATE INDEX fk_credit_receipt_table_company_idx ON credit_receipt_table (company);
CREATE INDEX fk_credit_receipt_table_so_header_idx ON credit_receipt_table (so_header);
CREATE INDEX fk_credit_receipt_table_user_id_idx ON credit_receipt_table (user_id);
CREATE INDEX fk_credit_receipt_table_pymnt_instrmnt_idx ON credit_receipt_table (payment_instrument);
    ''');
    developer.log('Created table: credit_receipt_table');

    //create other expense table
    await db.execute('''
CREATE TABLE other_expense_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_amount REAL,
  date_payment TEXT,
  reason_description TEXT CHECK (length(reason_description) <= 50),
  payment_instrument INTEGER,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_other_expense_table_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_other_expense_table_pymnt_instrmnt FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  CONSTRAINT fk_other_expense_table_user_id FOREIGN KEY (user_id) REFERENCES user_table(id)
);

CREATE INDEX fk_other_expense_table_company_idx ON other_expense_table (company);
CREATE INDEX fk_other_expense_table_user_id_idx ON other_expense_table (user_id);
CREATE INDEX fk_other_expense_table_pymnt_instrmnt_idx ON other_expense_table (payment_instrument);
''');
    developer.log('Created table: other_expense_table');

    //create other income table
    await db.execute('''
CREATE TABLE other_income_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  income_amount REAL,
  date_income TEXT,
  reason_description TEXT CHECK (length(reason_description) <= 50),
  payment_instrument INTEGER,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_other_income_table_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_other_income_table_pymnt_instrmnt FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  CONSTRAINT fk_other_income_table_user_id FOREIGN KEY (user_id) REFERENCES user_table(id)
);

CREATE INDEX fk_other_income_table_company_idx ON other_income_table (company);
CREATE INDEX fk_other_income_table_user_id_idx ON other_income_table (user_id);
CREATE INDEX fk_other_income_table_pymnt_instrmnt_idx ON other_income_table (payment_instrument);
''');
    developer.log('Created table: other_income_table');

    //create fast_slow_nonmoving_rule_table
    await db.execute('''
CREATE TABLE fast_slow_nonmoving_rule_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  report_frequency TEXT CHECK (length(report_frequency) <= 100),
  period_in_days INTEGER,
  fast_movement_rule_unit REAL,
  slow_movement_rule_unit REAL,
  non_movement_rule_unit REAL,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  company INTEGER,
  unit_of_meansure_default INTEGER,
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fast_slow_nonmoving_rule_table_ibfk_1 FOREIGN KEY (user_id) REFERENCES user_table(id),
  CONSTRAINT fk_fast_slow_nonmoving_rule_table_company FOREIGN KEY (company) REFERENCES company_table(id),
  CONSTRAINT fk_fast_slow_nonmoving_rule_table_unit_of_meansure_default FOREIGN KEY (unit_of_meansure_default) REFERENCES udc_details(id)
);

CREATE INDEX idx_audit_user ON fast_slow_nonmoving_rule_table (user_id);
CREATE INDEX fk_fast_slow_nonmoving_rule_table_company_idx ON fast_slow_nonmoving_rule_table (company);
CREATE INDEX fk_fast_slow_nonmoving_rule_table_unit_of_meansure_default_idx ON fast_slow_nonmoving_rule_table (unit_of_meansure_default);
''');
    developer.log('Created table: fast_slow_nonmoving_rule_table');

    //subscription management table
    await db.execute('''
CREATE TABLE subscription_management (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  initial_subscription_branches INTEGER,
  initial_subscription_users INTEGER,
  initial_payment REAL,
  initial_subscription_days INTEGER,
  updated_by INTEGER,
  date_updated TEXT,
  status TEXT CHECK (length(status) <= 12),
  name TEXT CHECK (length(name) <= 20),
  description TEXT CHECK (length(description) <= 60),
  max_storage INTEGER,
  popular TEXT CHECK (length(popular) <= 1),
  features TEXT CHECK (length(features) <= 200),
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_sm_updated_by FOREIGN KEY (updated_by) REFERENCES user_table(id)
);

CREATE INDEX fk_sm_updated_by_idx ON subscription_management (updated_by);
''');
    developer.log('Created table: subscription_management');

    //company subscription table
    await db.execute('''
CREATE TABLE company_subscription (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  company_id INTEGER,
  subscription_id INTEGER,
  date_subscribed TEXT,
  date_effective TEXT,
  date_expire TEXT,
  status TEXT CHECK (length(status) <= 12),
  sync_key TEXT CHECK(length(sync_key) <= 36),

  -- FOREIGN KEYS
  CONSTRAINT fk_cs_company_id FOREIGN KEY (company_id) REFERENCES company_table(id),
  CONSTRAINT fk_cs_subscription_id FOREIGN KEY (subscription_id) REFERENCES subscription_management(id)
);

CREATE INDEX fk_cs_company_id_idx ON company_subscription (company_id);
CREATE INDEX fk_cs_subscription_id_idx ON company_subscription (subscription_id);
''');
    developer.log('Created table: company_subscription');

    //fs table
    await db.execute('''
  CREATE TABLE fs_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fs_number INTEGER,
    branch INTEGER,
    mrc_number TEXT CHECK(length(mrc_number) <= 50),
    company INTEGER,
    machine_model TEXT CHECK(length(machine_model) <= 100),
    table_number TEXT CHECK(length(table_number) <= 45),
    postfix_up_to_four TEXT CHECK(length(postfix_up_to_four) <= 4),
    prefix_up_to_three TEXT CHECK(length(prefix_up_to_three) <= 3),
    sync_key TEXT CHECK(length(sync_key) <= 36),

    CONSTRAINT fk_fs_table_branch FOREIGN KEY (branch)
      REFERENCES branch_table(id)
      ON DELETE SET NULL
      ON UPDATE CASCADE,

    CONSTRAINT fk_fs_table_company FOREIGN KEY (company)
      REFERENCES company_table(id)
      ON DELETE SET NULL
      ON UPDATE CASCADE
);

CREATE INDEX fk_fs_table_branch_idx ON fs_table (branch);
CREATE INDEX fk_fs_table_company_idx ON fs_table (company);
''');
    developer.log('Created table: fs_table');

    //. Create sync_queue table
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

    // Company table indexes
    await db.execute(
      'CREATE INDEX idx_company_name ON company_table(company_name)',
    );
    await db.execute(
      'CREATE INDEX idx_company_tin ON company_table(tin_number)',
    );
    await db.execute('CREATE INDEX idx_company_city ON company_table(city)');
    await db.execute(
      'CREATE INDEX idx_company_category ON company_table(category_code)',
    );
    await db.execute(
      'CREATE INDEX idx_company_inventory_planner ON company_table(inventory_planner)',
    );

    // Branch table indexes
    await db.execute(
      'CREATE INDEX idx_branch_company ON branch_table(company)',
    );
    await db.execute('CREATE INDEX idx_branch_city ON branch_table(city)');
    await db.execute(
      'CREATE INDEX idx_branch_reference ON branch_table(reference_id)',
    );

    // Insert default data for LOT types
    await DefaultDataSeeder(databaseService: this).insertDefaultData();

    // Insert default system constant
    await DefaultDataSeeder(databaseService: this).insertDefaultSystemConstant();
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

  Future<bool> hasAnyCompany() async {
    final db = await database;
    try {
      final results = await db.rawQuery(
        'SELECT COUNT(*) as count FROM company_table',
      );
      if (results.isNotEmpty) {
        final count = results.first['count'] as int;
        return count > 0;
      }
      return false;
    } catch (e) {
      developer.log('Error checking if company exists: $e');
      return false;
    }
  }
}

// Example usage and testing
void testDatabase() async {
  final dbService = LocalDatabaseService();

  // Initialize database
  final db = await dbService.database;

  // Debug all tables
  //await dbService._debugPrintTablesAndData(db);

  // Debug specific table
  await dbService.debugTable('system_constant');
  await dbService.debugTable('udc_details');

  // Example: Insert a test system constant
  final testSystemConstant = {
    'apply_lot_mgm': 'N',
    'apply_overhead_cost': 'N',
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

Future<List<UdcDetails>> getUdcDetailsByHeaderCode(String headerCode) async {
  final db = await LocalDatabaseService().database;
  try {
    final results = await db.query(
      'udc_details',
      where: 'record_header = ?',
      whereArgs: [headerCode],
    );

    developer.log(
      'Found ${results.length} UDC details for header: $headerCode',
    );
    return results.map((e) => UdcDetails.fromJson(e)).toList();
  } catch (e) {
    developer.log('Error getting UDC details by header: $e');
    return [];
  }
}
