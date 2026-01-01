import 'dart:convert';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/services/database/seeders/privilege_seeder.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
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
      version: 2, // Incremented for proforma fields migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add upgrade handler
      onOpen: (db) async {
        // await _debugPrintTablesAndData(db);
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      await db.execute('''

      
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
        udc_description TEXT NOT NULL
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
        date_created TEXT,
        date_updated TEXT,
        margin_rate REAL,
        margin_type TEXT,
        reorder_point INTEGER,
        inventory_planner INTEGER,
        FOREIGN KEY (category_code) REFERENCES udc_details (detail_code) ON DELETE NO ACTION ON UPDATE NO ACTION
      )
    ''');
    developer.log('Created table: company_table');

    //4. Create branch table
    await db.execute('''
  CREATE TABLE branch_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reference_id TEXT,
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

    //11.Create items table
    await db.execute('''
CREATE TABLE items_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  items_id TEXT,
  item_description TEXT,
  unit_of_measure INTEGER,
  unit_price REAL,
  taxable TEXT,               -- store 'Y' or 'N'
  barcode TEXT,
  company INTEGER,
  margin_rate REAL,
  margin_type TEXT,           -- e.g. '%' or 'N'
  reorder_point REAL,
  reference_id TEXT,
  FOREIGN KEY (company) REFERENCES company_table(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id)
);
''');
    developer.log('Created table: items_table');

    // Indexes for faster lookup
    await db.execute('''
CREATE INDEX idx_items_company ON items_table(company);
CREATE INDEX idx_items_uom ON items_table(unit_of_measure);
CREATE INDEX idx_items_barcode ON items_table(barcode);
CREATE INDEX idx_items_id ON items_table(items_id);
''');
    developer.log('Created indexes for items_table');
    //12. Create item unit conversions
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
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (from_uom) REFERENCES udc_details(id),
  FOREIGN KEY (to_uom) REFERENCES udc_details(id)
);

CREATE INDEX idx_item_uom_conversions_branch ON item_uom_conversions(branch);
CREATE INDEX idx_item_uom_conversions_item_number ON item_uom_conversions(item_number);
CREATE INDEX idx_item_uom_conversions_company ON item_uom_conversions(company);
''');
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
  margin_type TEXT,

  -- Indexes for performance
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id)
);

-- Useful indexes
CREATE INDEX idx_items_in_branch_item_number ON items_in_branch(item_number);
CREATE INDEX idx_items_in_branch_branch ON items_in_branch(branch);
CREATE INDEX idx_items_in_branch_company ON items_in_branch(company);
CREATE INDEX idx_items_in_branch_uom ON items_in_branch(unit_of_measure);

);
''');
    developer.log('Created table: items_in_branch');

    // 14. Create system_constant table
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
        discount_display TEXT DEFAULT 'N',
        tax_info_display TEXT DEFAULT 'N',
        days_left INTEGER,
        currency_code TEXT DEFAULT 'Birr',
        reorder_point_uom_type TEXT DEFAULT 'I',
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

    //15.create location master
    await db.execute('''
CREATE TABLE location_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  branch INTEGER,
  code_01 TEXT,
  code_02 TEXT,
  code_03 TEXT,
  code_04 TEXT,
  code_05 TEXT,
  code_06 TEXT,
  code_07 TEXT,
  code_08 TEXT,
  code_09 TEXT,
  code_10 TEXT,
  margin_type TEXT,
  margin_rate REAL,
  created_by INTEGER,
  date_created TEXT,
  updated_by INTEGER,
  date_updated TEXT,
  company INTEGER,
  location_description TEXT,
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (created_by) REFERENCES user_table(id),
  FOREIGN KEY (updated_by) REFERENCES user_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id)
);

CREATE INDEX idx_location_master_branch ON location_master(branch);
CREATE INDEX idx_location_master_company ON location_master(company);
''');
    developer.log('Created table: location_master');

    //16.create item location
    await db.execute('''
CREATE TABLE item_location (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_number INTEGER,
  branch INTEGER,
  location INTEGER,
  quantity_on_hand  REAL,
  date_updated INTEGER,
  date_created INTEGER,
  updated_by INTEGER,
  created_by INTEGER,
  company INTEGER,
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (location) REFERENCES location_master(id),
  FOREIGN KEY (updated_by) REFERENCES user_table(id),
  FOREIGN KEY (created_by) REFERENCES user_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id)
);

CREATE INDEX idx_item_location_item_number ON item_location(item_number);
CREATE INDEX idx_item_location_branch ON item_location(branch);
CREATE INDEX idx_item_location_location ON item_location(location);
CREATE INDEX idx_item_location_company ON item_location(company);
''');
    developer.log('Created table: item_location');

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
  batch_number_supplier TEXT,
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (branch) REFERENCES branch_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (location) REFERENCES item_location(id),
  FOREIGN KEY (lot_status) REFERENCES udc_details(id)
);

CREATE INDEX idx_lot_master_item_number ON lot_master(item_number);
CREATE INDEX idx_lot_master_branch ON lot_master(branch);
CREATE INDEX idx_lot_master_company ON lot_master(company);
CREATE INDEX idx_lot_master_location ON lot_master(location);
CREATE INDEX idx_lot_master_lot_status ON lot_master(lot_status);
''');
    developer.log('Created table: lot_master');

    //18.create item_cost_table
    await db.execute('''
CREATE TABLE item_cost (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_number INTEGER,
  amount_unit_cost REAL,
  company INTEGER,
  user_id INTEGER,
  date_updated INTEGER,
  FOREIGN KEY (item_number) REFERENCES items_table(id),
  FOREIGN KEY (user_id) REFERENCES user_table(id),
  FOREIGN KEY (company) REFERENCES company_table(id)
);

CREATE INDEX idx_item_cost_item_number ON item_cost(item_number);
CREATE INDEX idx_item_cost_company ON item_cost(company);
''');
    developer.log('Created table: item_cost');

    //19.create supplier table
    await db.execute('''
  CREATE TABLE supplier_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_name TEXT,
    city TEXT,
    region TEXT,
    state TEXT,
    country TEXT,
    phone_no_1 TEXT,
    phone_no_2 TEXT,
    address_line TEXT,
    email TEXT,
    company INTEGER,
    created_by INTEGER,
    date_created TEXT,
    user_id INTEGER,
    date_updated TEXT,
    tin_number TEXT,
    contact_person TEXT,
    contact_title TEXT,
    FOREIGN KEY (company) REFERENCES company_table (id),
    FOREIGN KEY (created_by) REFERENCES user_table (id),
    FOREIGN KEY (user_id) REFERENCES user_table (id)
  );

CREATE INDEX idx_supplier_table_company ON supplier_table(company);
CREATE INDEX idx_supplier_table_created_by ON supplier_table(created_by);
CREATE INDEX idx_supplier_table_user_id ON supplier_table(user_id);
''');

    developer.log('Created table: supplier_table');

    //20.create purchase_order_header table
    await db.execute('''
  CREATE TABLE purchase_order_header (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_id INTEGER,
    date_transaction TEXT,
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
    invoice_number TEXT,
    FOREIGN KEY (supplier_id) REFERENCES supplier_table (id),
    FOREIGN KEY (company) REFERENCES company_table (id),
    FOREIGN KEY (po_receive_status) REFERENCES udc_details (id),
    FOREIGN KEY (payment_status) REFERENCES udc_details (id),
    FOREIGN KEY (payment_instrument) REFERENCES udc_details (id),
    FOREIGN KEY (order_type) REFERENCES udc_details (id),
    FOREIGN KEY (user_id) REFERENCES user_table (id)
  );

CREATE INDEX idx_purchase_order_header_supplier_id ON purchase_order_header(supplier_id);
CREATE INDEX idx_purchase_order_header_company ON purchase_order_header(company);
CREATE INDEX idx_purchase_order_header_po_receive_status ON purchase_order_header(po_receive_status);
CREATE INDEX idx_purchase_order_header_payment_status ON purchase_order_header(payment_status);
CREATE INDEX idx_purchase_order_header_payment_instrument ON purchase_order_header(payment_instrument);
CREATE INDEX idx_purchase_order_header_order_type ON purchase_order_header(order_type);
CREATE INDEX idx_purchase_order_header_user_id ON purchase_order_header(user_id);
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
    batch_number_supplier TEXT,
    FOREIGN KEY (po_header) REFERENCES purchase_order_header (id),
    FOREIGN KEY (company) REFERENCES company_table (id),
    FOREIGN KEY (item_number) REFERENCES items_table (id),
    FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );

CREATE INDEX idx_purchase_order_detail_po_header ON purchase_order_detail(po_header);
CREATE INDEX idx_purchase_order_detail_item_number ON purchase_order_detail(item_number);
CREATE INDEX idx_purchase_order_detail_unit_of_measure ON purchase_order_detail(unit_of_measure);
''');

    developer.log('Created table: purchase_order_detail');

    //22.create purchase_order_reciever table
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
    batch_number_supplier TEXT,
    FOREIGN KEY (po_detail) REFERENCES purchase_order_detail (id),
    FOREIGN KEY (branch_recieved) REFERENCES branch_table (id),
    FOREIGN KEY (company) REFERENCES company_table (id),
    FOREIGN KEY (item_number) REFERENCES items_table (id),
    FOREIGN KEY (location) REFERENCES item_location (id),
    FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );

CREATE INDEX idx_purchase_order_receiver_po_detail ON purchase_order_receiver(po_detail);
CREATE INDEX idx_purchase_order_receiver_item_number ON purchase_order_receiver(item_number);
CREATE INDEX idx_purchase_order_receiver_unit_of_measure ON purchase_order_receiver(unit_of_measure);
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
    remark TEXT,
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

CREATE INDEX idx_item_transactions_item_location ON item_transactions(item_location);
CREATE INDEX idx_item_transactions_created_by ON item_transactions(created_by);
CREATE INDEX idx_item_transactions_company ON item_transactions(company);
CREATE INDEX idx_item_transactions_lot_number ON item_transactions(lot_number);
CREATE INDEX idx_item_transactions_transaction_type ON item_transactions(transaction_type);
CREATE INDEX idx_item_transactions_item_branch ON item_transactions(item_branch);
CREATE INDEX idx_item_transactions_item_number ON item_transactions(item_number);
CREATE INDEX idx_item_transactions_lot_status ON item_transactions(lot_status);
CREATE INDEX idx_item_transactions_branch ON item_transactions(branch);
CREATE INDEX idx_item_transactions_supplier ON item_transactions(supplier);
CREATE INDEX idx_item_transactions_customer ON item_transactions(customer);
CREATE INDEX idx_item_transactions_order_type ON item_transactions(order_type);
CREATE INDEX idx_item_transactions_unit_of_measure ON item_transactions(unit_of_measure);
''');
    developer.log('Created table: item_transactions');

    //24. create next number table
    await db.execute('''
  CREATE TABLE next_number (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    next_number_code TEXT NOT NULL,
    next_number_description TEXT NOT NULL,
    next_number INTEGER NOT NULL DEFAULT 1,
    company INTEGER,
    FOREIGN KEY (company) REFERENCES company_table (id)
  );

CREATE INDEX idx_next_number_company ON next_number(company);
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
    description TEXT,
    days_minimum INTEGER,
    active_for_sales_flag TEXT DEFAULT 'Y',
    lot_exp_level TEXT,
    FOREIGN KEY (item_number) REFERENCES items_table (id),
    FOREIGN KEY (branch) REFERENCES branch_table (id),
    FOREIGN KEY (color_type) REFERENCES udc_details (id),
    FOREIGN KEY (company) REFERENCES company_table (id)
  );
  CREATE INDEX idx_lot_expiration_colors_company ON lot_expiration_colors(company);
''');
    developer.log('Created table: lot_expiration_colors');

    //26. create sales_order_header table
    await db.execute('''
  CREATE TABLE sales_order_header (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_date TEXT,
  required_date TEXT,
  shipped_date TEXT,
  sales_type TEXT,
  payment_method TEXT,
  payment_instrument INTEGER,
  discount TEXT,
  add_on TEXT,
  tax REAL,
  with_hold_apply TEXT,
  withhold_amount REAL,
  discount_amount REAL,
  discount_in_percent REAL,
  reference_note1 TEXT,
  reference_note_2 TEXT,
  reference_note3 TEXT,
  reference_note4 TEXT,
  proforma_flag TEXT,
  proforma_reference TEXT,
  credit_date_topay TEXT,
  fs_number TEXT,
  void_indicator TEXT,
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
  FOREIGN KEY (customer_bill_to) REFERENCES customer_table (id),
  FOREIGN KEY (customer_table_id) REFERENCES customer_table (id),
  FOREIGN KEY (employees_id) REFERENCES employees (id),
  FOREIGN KEY (company) REFERENCES company_table (id),
  FOREIGN KEY (payment_instrument) REFERENCES udc_details (id),
  FOREIGN KEY (payment_status) REFERENCES udc_details (id),
  FOREIGN KEY (order_type) REFERENCES udc_details (id)
);
CREATE INDEX idx_sales_order_header_customer_bill_to ON sales_order_header(customer_bill_to);
CREATE INDEX idx_sales_order_header_customer_table_id ON sales_order_header(customer_table_id);
CREATE INDEX idx_sales_order_header_employees_id ON sales_order_header(employees_id);
CREATE INDEX idx_sales_order_header_company ON sales_order_header(company);
CREATE INDEX idx_sales_order_header_payment_instrument ON sales_order_header(payment_instrument);
CREATE INDEX idx_sales_order_header_payment_status ON sales_order_header(payment_status);
CREATE INDEX idx_sales_order_header_order_type ON sales_order_header(order_type);
''');
    developer.log('Created table: sales_order_header');
    //27. create sales_order_details table
    await db.execute('''
  CREATE TABLE sales_order_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unit_price REAL,
    quantity REAL,
    extended_price REAL,
    taxable TEXT,
    reference1 TEXT,
    reference2 TEXT,
    sales_order_header_id INTEGER NOT NULL,
    items_table_id INTEGER NOT NULL,
    item_in_branch INTEGER,
    company INTEGER,
    lot_number INTEGER,
    unit_cost REAL,
    amount_cost REAL,
    unit_of_measure INTEGER,
    FOREIGN KEY (sales_order_header_id) REFERENCES sales_order_header (id) ON DELETE CASCADE,
    FOREIGN KEY (items_table_id) REFERENCES items_table (id),
    FOREIGN KEY (item_in_branch) REFERENCES items_in_branch (id),
    FOREIGN KEY (company) REFERENCES company_table (id),
    FOREIGN KEY (lot_number) REFERENCES lot_master (id),
    FOREIGN KEY (unit_of_measure) REFERENCES udc_details (id)
  );
  CREATE INDEX idx_sales_order_details_sales_order_header_id ON sales_order_details(sales_order_header_id);
  CREATE INDEX idx_sales_order_details_items_table_id ON sales_order_details(items_table_id);
  CREATE INDEX idx_sales_order_details_item_in_branch ON sales_order_details(item_in_branch);
  CREATE INDEX idx_sales_order_details_company ON sales_order_details(company);
  CREATE INDEX idx_sales_order_details_lot_number ON sales_order_details(lot_number);
  CREATE INDEX idx_sales_order_details_unit_of_measure ON sales_order_details(unit_of_measure);
''');
    developer.log('Created table: sales_order_details');

    //create item master table
    await db.execute('''
    CREATE TABLE item_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_description TEXT NOT NULL,
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
  created_by_flag TEXT DEFAULT 'Y',
  defualt_uom INTEGER,
  taxable_flag TEXT DEFAULT 'Y',
  UNIQUE (item_description, company_category),
  FOREIGN KEY (company_category) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_01) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_02) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_03) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_04) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_05) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_06) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_07) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_08) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_09) REFERENCES udc_details (id),
  FOREIGN KEY (category_code_10) REFERENCES udc_details (id),
  FOREIGN KEY (defualt_uom) REFERENCES udc_details (id)
);
CREATE INDEX idx_item_master_company ON item_master(company);
CREATE INDEX idx_item_master_category_code_01 ON item_master(category_code_01);
CREATE INDEX idx_item_master_category_code_02 ON item_master(category_code_02);
CREATE INDEX idx_item_master_category_code_03 ON item_master(category_code_03);
CREATE INDEX idx_item_master_category_code_04 ON item_master(category_code_04);
CREATE INDEX idx_item_master_category_code_05 ON item_master(category_code_05);
CREATE INDEX idx_item_master_category_code_06 ON item_master(category_code_06);
CREATE INDEX idx_item_master_category_code_07 ON item_master(category_code_07);
CREATE INDEX idx_item_master_category_code_08 ON item_master(category_code_08);
CREATE INDEX idx_item_master_category_code_09 ON item_master(category_code_09);
CREATE INDEX idx_item_master_category_code_10 ON item_master(category_code_10);
CREATE INDEX idx_item_master_defualt_uom ON item_master(defualt_uom);
''');
    developer.log('Created table: item_master');

    //invoice header table
    await db.execute('''
CREATE TABLE invoice_history_header (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fs_number TEXT,
  customer_name TEXT,
  tin_number TEXT,
  phone_number TEXT,
  country TEXT,
  city TEXT,
  region TEXT,
  tax_amount REAL,
  withhold_amount REAL,
  total_amount REAL,
  date_transaction TEXT, -- store as ISO8601 string (e.g., "2025-11-13")
  sales_person TEXT,
  mrc_number TEXT,
  discount_amount REAL,
  amount_beforeTax REAL,
  company INTEGER,
  FOREIGN KEY (company) REFERENCES company_table(id)
);
CREATE INDEX idx_invoice_history_header_company ON invoice_history_header(company);

''');
    developer.log('Created table: invoice_history_header');
    //invoice for detail
    await db.execute('''
CREATE TABLE invoice_history_detail (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_history INTEGER,
  item TEXT,
  unit_of_measure TEXT,
  quantity_transaction REAL,
  amount_unit_price REAL,
  amount_extended_price REAL,
  company INTEGER,
  FOREIGN KEY (invoice_history) REFERENCES invoice_history_header(id),
  FOREIGN KEY (company) REFERENCES company_table(id)
);
CREATE INDEX idx_invoice_history_detail_invoice_history ON invoice_history_detail(invoice_history);
CREATE INDEX idx_invoice_history_detail_company ON invoice_history_detail(company);
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

  UNIQUE (uuid),
  UNIQUE (email),
  UNIQUE (phone_number),
  UNIQUE (referral_code),

  FOREIGN KEY (parent_salesperson_id) REFERENCES salespersons(id)
);

CREATE INDEX idx_sales_person_company ON salespersons(company);
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

  sales_type TEXT,
  payment_method TEXT,
  payment_instrument INTEGER,
  discount TEXT,
  add_on TEXT,
  tax REAL,
  with_hold_apply TEXT,
  withhold_amount REAL,
  discount_amount REAL,
  discount_in_percent REAL,

  reference_note1 TEXT,
  reference_note_2 TEXT,
  reference_note3 TEXT,
  reference_note4 TEXT,

  comments_sales TEXT,
  credit_date_topay TEXT,
  fs_number TEXT,
  void_indicator TEXT,

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
  sales_represent TEXT,
  comment_for_return TEXT,

  -- FOREIGN KEYS
  FOREIGN KEY (customer_bill_to) REFERENCES customer_table(id),
  FOREIGN KEY (customer_table_id) REFERENCES customer_table(id),
  FOREIGN KEY (employees_id) REFERENCES employees(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  FOREIGN KEY (payment_status) REFERENCES udc_details(id),
  FOREIGN KEY (order_type) REFERENCES udc_details(id),
  FOREIGN KEY (return_status) REFERENCES udc_details(id)
);
CREATE UNIQUE INDEX idx_sales_return_header_id_unique
ON sales_return_header (id);

CREATE INDEX idx_srh_customer_bill_to
ON sales_return_header (customer_bill_to);

CREATE INDEX idx_srh_customer_table_id
ON sales_return_header (customer_table_id);

CREATE INDEX idx_srh_employees_id
ON sales_return_header (employees_id);

CREATE INDEX idx_srh_company
ON sales_return_header (company);

CREATE INDEX idx_srh_payment_instrument
ON sales_return_header (payment_instrument);

CREATE INDEX idx_srh_payment_status
ON sales_return_header (payment_status);

CREATE INDEX idx_srh_order_type
ON sales_return_header (order_type);

CREATE INDEX idx_srh_return_status
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
  taxable TEXT,
  reference1 TEXT,
  reference2 TEXT,
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

  -- FOREIGN KEYS
  FOREIGN KEY (sales_return_header_id) REFERENCES sales_return_header(id),
  FOREIGN KEY (items_table_id) REFERENCES items_table(id),
  FOREIGN KEY (item_in_branch) REFERENCES items_in_branch(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (lot_number) REFERENCES lot_master(id),
  FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id),
  FOREIGN KEY (return_status) REFERENCES udc_details(id),
  FOREIGN KEY (return_reason) REFERENCES udc_details(id)
);


CREATE INDEX idx_srd_sales_return_header_id
ON sales_return_detail (sales_return_header_id);

CREATE INDEX idx_srd_item_id
ON sales_return_detail (item_id);

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
  sales_type TEXT,
  quotation_validation_in_days INTEGER DEFAULT 30,
  payment_method TEXT,
  payment_instrument INTEGER,
  payment_term INTEGER,
  payment_status INTEGER,
  credit_date_topay TEXT,
  currency_code TEXT DEFAULT 'ETB',
  exchange_rate REAL DEFAULT 1,
  discount TEXT,
  discount_amount REAL,
  discount_in_percent REAL,
  add_on TEXT,
  tax REAL,
  with_hold_apply TEXT,
  withhold_amount REAL,
  amount_total REAL,
  amount_open REAL,
  unit_cost REAL,
  amount_cost REAL,
  order_type INTEGER,
  order_status TEXT DEFAULT 'Draft',
  conversion_status TEXT,
  prforma_status TEXT,
  void_indicator TEXT,
  reference_note1 TEXT,
  reference_note_2 TEXT,
  reference_note3 TEXT,
  reference_note4 TEXT,
  external_ref_number TEXT,
  fs_number TEXT,
  sales_represent TEXT,
  converted_items TEXT,
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

  -- FOREIGN KEYS
  FOREIGN KEY (customer_bill_to) REFERENCES customer_table(id),
  FOREIGN KEY (customer_table_id) REFERENCES customer_table(id),
  FOREIGN KEY (employees_id) REFERENCES employees(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (branch_id) REFERENCES branch(id),
  FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  FOREIGN KEY (payment_status) REFERENCES udc_details(id),
  FOREIGN KEY (order_type) REFERENCES udc_details(id),
  FOREIGN KEY (prforma_status) REFERENCES udc_details(id)
);
CREATE UNIQUE INDEX idx_proforma_header_id_unique
ON proforma_header (id);

CREATE INDEX idx_ph_customer_bill_to
ON proforma_header (customer_bill_to);

CREATE INDEX idx_ph_customer_table_id
ON proforma_header (customer_table_id);

CREATE INDEX idx_ph_employees_id
ON proforma_header (employees_id);

CREATE INDEX idx_ph_company
ON proforma_header (company);

CREATE INDEX idx_ph_payment_instrument
ON proforma_header (payment_instrument);

CREATE INDEX idx_ph_payment_status
ON proforma_header (payment_status);

CREATE INDEX idx_ph_order_type
ON proforma_header (order_type);

CREATE INDEX idx_ph_prforma_status
ON proforma_header (prforma_status);
    ''');
    developer.log('Created table: proforma_header');

    //create quote order detail table
    await db.execute('''
CREATE TABLE quote_order_detail (
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
  taxable TEXT,
  discount_percent REAL,
  discount_amount REAL,
  unit_of_measure INTEGER,
  line_status TEXT DEFAULT 'Open',
  reference1 TEXT,
  reference2 TEXT,
  prforma_status INTEGER,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER,
  updated_by INTEGER,

  -- FOREIGN KEYS
  FOREIGN KEY (quote_order_header_id) REFERENCES quote_order_header(id),
  FOREIGN KEY (items_table_id) REFERENCES items_table(id),
  FOREIGN KEY (item_in_branch) REFERENCES items_in_branch(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (unit_of_measure) REFERENCES udc_details(id),
  FOREIGN KEY (prforma_status) REFERENCES udc_details(id)
);

CREATE INDEX idx_qod_quote_order_header_id
ON quote_order_detail (quote_order_header_id);

CREATE INDEX idx_qod_item_id
ON quote_order_detail (item_in_branch);

CREATE INDEX idx_qod_company
ON quote_order_detail (company);

CREATE INDEX idx_qod_unit_of_measure
ON quote_order_detail (unit_of_measure);

CREATE INDEX idx_qod_prforma_status
ON quote_order_detail (prforma_status);
    ''');
    developer.log('Created table: quote_order_detail');

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

  -- FOREIGN KEYS
  FOREIGN KEY (po_header) REFERENCES purchase_order_header(id),
  FOREIGN KEY (payment_instrument) REFERENCES udc_details(id),
  FOREIGN KEY (company) REFERENCES company_table(id),
  FOREIGN KEY (user_id) REFERENCES user_table(id)
);

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

  FOREIGN KEY (company) REFERENCES company_table(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (payment_instrument) REFERENCES udc_details(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (so_header) REFERENCES sales_order_header(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user_table(id) ON DELETE SET NULL ON UPDATE CASCADE
);


    ''');
    developer.log('Created table: credit_receipt_table');

    //create other expense table
    await db.execute('''
CREATE TABLE other_expense_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_amount REAL,
  date_payment TEXT,
  reason_description TEXT,
  payment_instrument INTEGER,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,

  FOREIGN KEY (company)
    REFERENCES company_table(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  FOREIGN KEY (payment_instrument)
    REFERENCES udc_details(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  FOREIGN KEY (user_id)
    REFERENCES user_table(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

CREATE INDEX idx_oet_company
ON other_expense_table (company);

CREATE INDEX idx_oet_payment_instrument
ON other_expense_table (payment_instrument);

CREATE INDEX idx_oet_user_id
ON other_expense_table (user_id);
''');
    developer.log('Created table: other_expense_table');

    //create other income table
    await db.execute('''
CREATE TABLE other_income_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  income_amount REAL,
  date_income TEXT,
  reason_description TEXT,
  payment_instrument INTEGER,
  company INTEGER,
  user_id INTEGER,
  date_updated TEXT,

  FOREIGN KEY (company)
    REFERENCES company_table(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  FOREIGN KEY (payment_instrument)
    REFERENCES udc_details(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  FOREIGN KEY (user_id)
    REFERENCES user_table(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

CREATE INDEX idx_oit_company
ON other_income_table (company);

CREATE INDEX idx_oit_payment_instrument
ON other_income_table (payment_instrument);

CREATE INDEX idx_oit_user_id
ON other_income_table (user_id);
''');
    developer.log('Created table: other_income_table');

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
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    developer.log('Inserting default data...');

    final List<Map<String, dynamic>> udcHeaderSeedData = [
      {'id': 1, 'header_code': 'UM', 'udc_description': 'Unit of Measure'},
      {'id': 2, 'header_code': 'PI', 'udc_description': 'Payment Instrument'},
      {
        'id': 3,
        'header_code': 'PR',
        'udc_description': 'Purchased Receive Status',
      },
      {'id': 4, 'header_code': 'CN', 'udc_description': 'Countries'},
      {'id': 5, 'header_code': 'PS', 'udc_description': 'Payment Status'},
      {'id': 6, 'header_code': 'CT', 'udc_description': 'Color Types'},
      {'id': 7, 'header_code': 'LS', 'udc_description': 'Lot Status'},
      {'id': 8, 'header_code': 'TT', 'udc_description': 'Transaction Type'},
      {'id': 9, 'header_code': 'OT', 'udc_description': 'Order Type'},
      {'id': 10, 'header_code': 'CC', 'udc_description': 'Company Category'},
      {'id': 11, 'header_code': 'C1', 'udc_description': 'Item Category 1'},
      {'id': 12, 'header_code': 'C2', 'udc_description': 'Item Category 2'},
      {'id': 13, 'header_code': 'C3', 'udc_description': 'Item Category 3'},
      {'id': 14, 'header_code': 'C4', 'udc_description': 'Item Category 4'},
      {'id': 15, 'header_code': 'C5', 'udc_description': 'Item Category 5'},
      {'id': 16, 'header_code': 'C6', 'udc_description': 'Item Category 6'},
      {'id': 17, 'header_code': 'C7', 'udc_description': 'Item Category 7'},
      {'id': 18, 'header_code': 'C8', 'udc_description': 'Item Category 8'},
      {'id': 19, 'header_code': 'C9', 'udc_description': 'Item Category 9'},
      {'id': 20, 'header_code': 'C10', 'udc_description': 'Item Category 10'},
      {'id': 21, 'header_code': 'LT', 'udc_description': 'Lot Type'},
      {'id': 22, 'header_code': 'SR', 'udc_description': 'Sales Return Status'},
    ];

    for (final udcHeader in udcHeaderSeedData) {
      await db.insert('udc_header', udcHeader);
    }
    developer.log('udc header data inserted');

    final List<Map<String, dynamic>> udcDetailsSeedData = [
      // --- Unit of Measure (UM) ---
      {
        'id': 1,
        'detail_code': 'PCS',
        'description_1': 'Pieces',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'id': 2,
        'detail_code': 'KG',
        'description_1': 'Kilogram',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'id': 3,
        'detail_code': 'L',
        'description_1': 'Litre',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'id': 4,
        'detail_code': 'BOX',
        'description_1': 'Box',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'id': 5,
        'detail_code': 'M',
        'description_1': 'Meter',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },

      // --- Payment Instrument (PI) ---
      {
        'id': 6,
        'detail_code': 'CASH',
        'description_1': 'Cash',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },
      {
        'id': 7,
        'detail_code': 'CARD',
        'description_1': 'Card Payment',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },
      {
        'id': 8,
        'detail_code': 'BANK',
        'description_1': 'Bank Transfer',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },
      {
        'id': 9,
        'detail_code': 'MOBILE',
        'description_1': 'Mobile Payment',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },

      // --- Purchased Receive Status (PR) ---
      {
        'id': 10,
        'detail_code': 'N',
        'description_1': 'New',
        'description_2': null,
        'record_header': 3,
        'udc_group': 'PR',
      },
      {
        'id': 11,
        'detail_code': 'P',
        'description_1': 'Partially Received',
        'description_2': null,
        'record_header': 3,
        'udc_group': 'PR',
      },
      {
        'id': 12,
        'detail_code': 'C',
        'description_1': 'Completely Received',
        'description_2': null,
        'record_header': 3,
        'udc_group': 'PR',
      },

      // --- Countries (CN) ---
      {
        'id': 13,
        'detail_code': 'ET',
        'description_1': 'Ethiopia',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },
      {
        'id': 14,
        'detail_code': 'KE',
        'description_1': 'Kenya',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },
      {
        'id': 15,
        'detail_code': 'US',
        'description_1': 'United States',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },
      {
        'id': 16,
        'detail_code': 'IN',
        'description_1': 'India',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },

      // --- Payment Status (PS) ---
      {
        'id': 17,
        'detail_code': 'N',
        'description_1': 'Not paid',
        'description_2': null,
        'record_header': 5,
        'udc_group': 'PS',
      },
      {
        'id': 18,
        'detail_code': 'P',
        'description_1': 'Paid',
        'description_2': null,
        'record_header': 5,
        'udc_group': 'PS',
      },
      {
        'id': 19,
        'detail_code': 'S',
        'description_1': 'Partially paid',
        'description_2': null,
        'record_header': 5,
        'udc_group': 'PS',
      },

      // --- Color Types (CT) ---
      {
        'id': 20,
        'detail_code': 'RED',
        'description_1': 'Red',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 21,
        'detail_code': 'BLU',
        'description_1': 'Blue',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 22,
        'detail_code': 'GRN',
        'description_1': 'Green',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 23,
        'detail_code': 'BLK',
        'description_1': 'Black',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 371,
        'detail_code': 'ORG',
        'description_1': 'Orange',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 372,
        'detail_code': 'GRY',
        'description_1': 'Gray',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 374,
        'detail_code': 'LM',
        'description_1': 'Lime',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 375,
        'detail_code': 'OV',
        'description_1': 'Olive',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 376,
        'detail_code': 'YL',
        'description_1': 'Yellow',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 377,
        'detail_code': 'PRPL',
        'description_1': 'Purple',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 378,
        'detail_code': 'FC',
        'description_1': 'Fuchsia',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 379,
        'detail_code': 'NV',
        'description_1': 'Navy',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 381,
        'detail_code': 'TL',
        'description_1': 'Teal',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 382,
        'detail_code': 'AQUA',
        'description_1': 'Aqua',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 383,
        'detail_code': 'BRW',
        'description_1': 'Brown',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'id': 384,
        'detail_code': 'CH',
        'description_1': 'Chartreuse',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },

      // --- Lot Status (LS) ---
      {
        'id': 24,
        'detail_code': 'A',
        'description_1': 'Active Lot',
        'description_2': null,
        'record_header': 7,
        'udc_group': 'LS',
      },
      {
        'id': 25,
        'detail_code': 'D',
        'description_1': 'Damaged Lot',
        'description_2': null,
        'record_header': 7,
        'udc_group': 'LS',
      },

      {
        'id': 26,
        'detail_code': 'E',
        'description_1': 'Expired Lot',
        'description_2': null,
        'record_header': 7,
        'udc_group': 'LS',
      },

      // --- Transaction Type (TT) ---
      {
        'id': 27,
        'detail_code': 'T',
        'description_1': ' Inventory transfer',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },
      {
        'id': 28,
        'detail_code': 'I',
        'description_1': 'Inventory issue',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },
      {
        'id': 29,
        'detail_code': 'A',
        'description_1': 'Inventory adjustment',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },

      // --- Order Type (OT) ---
      {
        'id': 30,
        'detail_code': 'SO',
        'description_1': 'Sales Order',
        'description_2': null,
        'record_header': 9,
        'udc_group': 'OT',
      },
      {
        'id': 31,
        'detail_code': 'PO',
        'description_1': 'Purchase Order',
        'description_2': null,
        'record_header': 9,
        'udc_group': 'OT',
      },

      // --- Company Category (CC) ---
      {
        'id': 32,
        'detail_code': 'SUP',
        'description_1': 'Supplier',
        'description_2': null,
        'record_header': 10,
        'udc_group': 'CC',
      },
      {
        'id': 33,
        'detail_code': 'CUS',
        'description_1': 'Customer',
        'description_2': null,
        'record_header': 10,
        'udc_group': 'CC',
      },
      {
        'id': 34,
        'detail_code': 'EMP',
        'description_1': 'Employee',
        'description_2': null,
        'record_header': 10,
        'udc_group': 'CC',
      },

      //---- Category 1 (CT1) ----
      {
        'id': 35,
        'detail_code': 'CT1',
        'description_1': 'Category 1',
        'description_2': null,
        'record_header': 11,
        'udc_group': 'CT1',
      },
      {
        'id': 36,
        'detail_code': 'CT1pro',
        'description_1': 'Category 1 pro ',
        'description_2': null,
        'record_header': 11,
        'udc_group': 'CT1',
      },

      //---Category 2 (CT2)---
      {
        'id': 37,
        'detail_code': 'CT2',
        'description_1': 'Category 2',
        'description_2': null,
        'record_header': 12,
        'udc_group': 'CT2',
      },
      {
        'id': 38,
        'detail_code': 'CT2pro',
        'description_1': 'Category 2 pro',
        'description_2': null,
        'record_header': 12,
        'udc_group': 'CT2',
      },

      //---Category 3 (CT3)---
      {
        'id': 39,
        'detail_code': 'CT3',
        'description_1': 'Category 3',
        'description_2': null,
        'record_header': 13,
        'udc_group': 'CT3',
      },
      {
        'id': 40,
        'detail_code': 'CT3pro',
        'description_1': 'Category 3 pro',
        'description_2': null,
        'record_header': 13,
        'udc_group': 'CT3',
      },

      // --- Lot Type (LT) ---
      {
        'id': 41,
        'detail_code': 'X',
        'description_1': 'Expiration Date',
        'description_2': 'Select items by expiration date',
        'record_header': 21,
        'udc_group': 'LT',
      },
      {
        'id': 42,
        'detail_code': 'F',
        'description_1': 'Effective Date',
        'description_2': 'Select items by effective date',
        'record_header': 21,
        'udc_group': 'LT',
      },
      {
        'id': 43,
        'detail_code': 'R',
        'description_1': 'Receipt Date',
        'description_2': 'Select items by receipt date',
        'record_header': 21,
        'udc_group': 'LT',
      },
      {
        'id': 44,
        'detail_code': 'DG',
        'description_1': 'Damaged Goods',
        'description_2': 'Product arrived broken or defective',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 45,
        'detail_code': 'EG',
        'description_1': 'Expired Goods',
        'description_2': 'Expired items (pharmacy, food, etc.)',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 46,
        'detail_code': 'WI',
        'description_1': 'Wrong Item Supplied',
        'description_2': 'Item mismatch compared to customer order',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 47,
        'detail_code': 'WQ',
        'description_1': 'Wrong Quantity Supplied',
        'description_2': 'More or fewer units supplied than ordered',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 48,
        'detail_code': 'QI',
        'description_1': 'Quality Issues',
        'description_2': 'Customer not satisfied with product quality',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 49,
        'detail_code': 'PR',
        'description_1': 'Product Recall',
        'description_2': 'Manufacturer recall due to safety/defect issues',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 50,
        'detail_code': 'CM',
        'description_1': 'Customer Changed Mind',
        'description_2': 'Return allowed within grace period',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 51,
        'detail_code': 'OC',
        'description_1': 'Order Cancellation',
        'description_2': 'Customer canceled after invoicing but before usage',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 52,
        'detail_code': 'LD',
        'description_1': 'Late Delivery',
        'description_2': 'Goods delivered outside agreed time',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 53,
        'detail_code': 'PI',
        'description_1': 'Packaging Issues',
        'description_2': 'Leaking, tampered, or opened package',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 54,
        'detail_code': 'WC',
        'description_1': 'Warranty / Guarantee Claim',
        'description_2': 'Returned within warranty terms',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 55,
        'detail_code': 'ND',
        'description_1': 'Not as Described',
        'description_2': 'Product specs don’t match description',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 56,
        'detail_code': 'DS',
        'description_1': 'Duplicate Sale',
        'description_2': 'Mistaken duplicate invoice/order',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 57,
        'detail_code': 'W1',
        'description_1': 'Wrong Customer Selected',
        'description_2': 'Sale recorded under wrong customer',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 58,
        'detail_code': 'W2',
        'description_1': 'Wrong Item Selected',
        'description_2': 'Wrong product/service chosen before finalizing sale',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 59,
        'detail_code': 'W3',
        'description_1': 'Wrong Price Applied',
        'description_2': 'Pricing error discovered immediately',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 60,
        'detail_code': 'D1',
        'description_1': 'Discount Mistake',
        'description_2': 'Wrong discount percentage applied',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 61,
        'detail_code': 'P2',
        'description_1': 'Payment Error',
        'description_2':
            'Customer payment failed or incorrect payment recorded',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 62,
        'detail_code': 'C3',
        'description_1': 'Cashier Mistake',
        'description_2': 'Accidental entry (e.g., double billing)',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 63,
        'detail_code': 'T4',
        'description_1': 'Training/Test Transaction',
        'description_2': 'Dummy transactions during training/testing',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 64,
        'detail_code': 'S5',
        'description_1': 'System Error / Power Failure',
        'description_2': 'Technical issue during transaction',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 65,
        'detail_code': 'C6',
        'description_1': 'Customer Walked Away / No Payment',
        'description_2': 'Customer didn’t complete purchase',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 66,
        'detail_code': 'FP',
        'description_1': 'Fraud Prevention',
        'description_2': 'Suspicious sale identified and canceled',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 67,
        'detail_code': 'DI',
        'description_1': 'Duplicate Invoice',
        'description_2': 'Accidentally issued two invoices for same order',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 68,
        'detail_code': 'O7',
        'description_1': 'Order Cancelled Before Fulfillment',
        'description_2': 'Sale voided before goods delivered',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 69,
        'detail_code': 'S1',
        'description_1': 'Incorrect Size/Variant',
        'description_2':
            'Product returned due to wrong size, color, or variant selection',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 70,
        'detail_code': 'S2',
        'description_1': 'Late Defect Discovery',
        'description_2': 'Customer discovers a defect after initial inspection',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 71,
        'detail_code': 'S3',
        'description_1': 'Allergic Reaction / Health Issue',
        'description_2':
            'Returned due to personal health issues (pharma, food, etc.)',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 72,
        'detail_code': 'S4',
        'description_1': 'Price/Offer Mismatch',
        'description_2':
            'Customer returns because of price difference or promotion mismatch',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 73,
        'detail_code': 'S8',
        'description_1': 'Gift Return',
        'description_2':
            'Returned because it was gifted, not wanted by recipient',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 74,
        'detail_code': 'S6',
        'description_1': 'Shipping Damage (Carrier Fault)',
        'description_2':
            'Product damaged during transit, not manufacturer fault',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 75,
        'detail_code': 'S7',
        'description_1': 'Seasonal / Promotional Return',
        'description_2': 'Customer returns a promotional or seasonal item',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 76,
        'detail_code': 'V1',
        'description_1': 'Customer Changed Mind Before Payment',
        'description_2': 'Sale canceled before payment attempt',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 77,
        'detail_code': 'V2',
        'description_1': 'System Timeout / Session Expiry',
        'description_2': 'Transaction aborted due to system timeout',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 78,
        'detail_code': 'V3',
        'description_1': 'Inventory Not Available',
        'description_2': 'Sale voided because stock was not actually available',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 79,
        'detail_code': 'V4',
        'description_1': 'Duplicate Entry Detected Before Invoice',
        'description_2': 'Mistaken entry detected before invoicing',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 80,
        'detail_code': 'V5',
        'description_1': 'Promotional / Discount Override Error',
        'description_2':
            'Sale voided because a promotion or discount was misapplied',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'id': 81,
        'detail_code': 'OT',
        'description_1': 'Others',
        'description_2': 'Other Reason',
        'record_header': 23,
        'udc_group': 'SR',
      },
    ];

    for (final lotType in udcDetailsSeedData) {
      await db.insert('udc_details', lotType);
    }
    developer.log('Inserted default udc headers and details');

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
        'reorder_point': 20,
        'logo_company': 'assets/images/onboarding_background.png',
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
        'reference_id': 'M1001',
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
        'reference_id': 'M1002',
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
      AppRoutes.salesReview,
      AppRoutes.salesReturn,
      AppRoutes.quotationOrder,
      AppRoutes.quotationItemEntry,
      AppRoutes.quotationOrderPayment,
      AppRoutes.quotationInvoiceReview,
      AppRoutes.quotationOrderReview,
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
    final argon2Hash = await generateArgon2Hash('a');
    final users = [
      {
        'password': argon2Hash,
        'employees_id': 1,
        'created_by': 1,
        'branch': 1,
        'company': 1,
        'user_name': 'a',
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
    //insert sales persons
    final salesPersons = [
      {
        'full_name': 'Sales1',
        'uuid': '1',
        'email': 'john.doe@gmail.com',
        'phone_number': '12345678900',
        'password_hash': argon2Hash,
        'referral_code': 'ref001',
        'parent_salesperson_id': 1,
        'status': 'ACTIVE',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'full_name': 'Sales2',
        'uuid': '2',
        'email': 'jane.doe@gmail.com',
        'phone_number': '12345678901',
        'password_hash': argon2Hash,
        'referral_code': 'ref002',
        'parent_salesperson_id': 1,
        'status': 'ACTIVE',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final salesPerson in salesPersons) {
      await db.insert('salespersons', salesPerson);
    }
    developer.log('Inserted sales persons');

    await db.execute('''
  CREATE TABLE customer_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER,
    customer_name TEXT,
    phone_number TEXT,
    address TEXT,
    country TEXT,
    state TEXT,
    region TEXT,
    city TEXT,
    tin_number TEXT,
    defaults_value TEXT,
    address1 TEXT,
    address2 TEXT,
    address3 TEXT,
    address4 TEXT,
    fax TEXT,
    phone_2 TEXT,
    contact_name TEXT,
    contact_title TEXT,
    company INTEGER,
    FOREIGN KEY (company) REFERENCES company_table (id) ON DELETE NO ACTION ON UPDATE NO ACTION
  )
''');
    developer.log('created customer table');

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
  //await dbService._debugPrintTablesAndData(db);

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
