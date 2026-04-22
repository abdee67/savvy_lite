import 'dart:developer' as developer;

import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/database/seeders/privilege_seeder.dart';
import 'package:sqflite/sqflite.dart';

class DefaultDataSeeder extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  DefaultDataSeeder({required this.databaseService});

  Future<void> insertDefaultData(Database db) async {
    developer.log('Inserting default data...');

    final List<Map<String, dynamic>> udcHeaderSeedData = [
      {'id': 1, 'udc_code': 'UM', 'udc_description': 'Unit of Measure'},
      {'id': 2, 'udc_code': 'PI', 'udc_description': 'Payment Instrument'},
      {
        'id': 3,
        'udc_code': 'PR',
        'udc_description': 'Purchased Receive Status',
      },
      {'id': 4, 'udc_code': 'CN', 'udc_description': 'Countries'},
      {'id': 5, 'udc_code': 'PS', 'udc_description': 'Payment Status'},
      {'id': 6, 'udc_code': 'CT', 'udc_description': 'Color Types'},
      {'id': 7, 'udc_code': 'LS', 'udc_description': 'Lot Status'},
      {'id': 8, 'udc_code': 'TT', 'udc_description': 'Transaction Type'},
      {'id': 9, 'udc_code': 'OT', 'udc_description': 'Order Type'},
      {'id': 10, 'udc_code': 'CC', 'udc_description': 'Company Category'},
      {'id': 11, 'udc_code': 'C1', 'udc_description': 'Item Category 1'},
      {'id': 12, 'udc_code': 'C2', 'udc_description': 'Item Category 2'},
      {'id': 13, 'udc_code': 'C3', 'udc_description': 'Item Category 3'},
      {'id': 14, 'udc_code': 'C4', 'udc_description': 'Item Category 4'},
      {'id': 15, 'udc_code': 'C5', 'udc_description': 'Item Category 5'},
      {'id': 16, 'udc_code': 'C6', 'udc_description': 'Item Category 6'},
      {'id': 17, 'udc_code': 'C7', 'udc_description': 'Item Category 7'},
      {'id': 18, 'udc_code': 'C8', 'udc_description': 'Item Category 8'},
      {'id': 19, 'udc_code': 'C9', 'udc_description': 'Item Category 9'},
      {'id': 20, 'udc_code': 'C0', 'udc_description': 'Item Category 10'},
      {'id': 21, 'udc_code': 'LT', 'udc_description': 'Lot Type'},
      {'id': 22, 'udc_code': 'FQ', 'udc_description': 'Report Frequency'},
      {'id': 23, 'udc_code': 'SR', 'udc_description': 'Sales Return Status'},
    ];

    for (final udcHeader in udcHeaderSeedData) {
      final payload = withSyncKey(udcHeader);
      await db.insert('udc_header', payload);
      /*captureSync(
        tableName: 'udc_header',
        entityMap: payload,
        entityId: udcHeader['id'].toString(),
        operation: 'INSERT',
      );*/ //default data is not upposed to sync cuz there it is default data in the server already
    }
    developer.log('udc header data inserted');

    final List<Map<String, dynamic>> udcDetailsSeedData = [
      // --- Unit of Measure (UM) ---
      {
        'detail_code': 'PC',
        'description_1': 'Pieces',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'detail_code': 'KG',
        'description_1': 'Kilogram',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'detail_code': 'L',
        'description_1': 'Litre',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'detail_code': 'BX',
        'description_1': 'Box',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },
      {
        'detail_code': 'M',
        'description_1': 'Meter',
        'description_2': null,
        'record_header': 1,
        'udc_group': 'UM',
      },

      // --- Payment Instrument (PI) ---
      {
        'detail_code': 'CS',
        'description_1': 'Cash',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },
      {
        'detail_code': 'CK',
        'description_1': 'Check Payment',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },
      {
        'detail_code': 'TR',
        'description_1': 'Transfer',
        'description_2': null,
        'record_header': 2,
        'udc_group': 'PI',
      },

      // --- Purchased Receive Status (PR) ---
      {
        'detail_code': 'N',
        'description_1': 'Ordered',
        'description_2': null,
        'record_header': 3,
        'udc_group': 'PR',
      },
      {
        'detail_code': 'P',
        'description_1': 'Partially Received',
        'description_2': null,
        'record_header': 3,
        'udc_group': 'PR',
      },
      {
        'detail_code': 'R',
        'description_1': 'Received',
        'description_2': null,
        'record_header': 3,
        'udc_group': 'PR',
      },

      // --- Countries (CN) ---
      {
        'detail_code': 'ET',
        'description_1': 'Ethiopia',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },
      {
        'detail_code': 'KE',
        'description_1': 'Kenya',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },
      {
        'detail_code': 'US',
        'description_1': 'United States',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },
      {
        'detail_code': 'IN',
        'description_1': 'India',
        'description_2': null,
        'record_header': 4,
        'udc_group': 'CN',
      },

      // --- Payment Status (PS) ---
      {
        'detail_code': 'N',
        'description_1': 'Not paid',
        'description_2': null,
        'record_header': 5,
        'udc_group': 'PS',
      },
      {
        'detail_code': 'P',
        'description_1': 'Paid',
        'description_2': null,
        'record_header': 5,
        'udc_group': 'PS',
      },
      {
        'detail_code': 'S',
        'description_1': 'Partially paid',
        'description_2': null,
        'record_header': 5,
        'udc_group': 'PS',
      },

      // --- Color Types (CT) ---
      {
        'detail_code': '01',
        'description_1': 'Red',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '02',
        'description_1': 'Orange',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '03',
        'description_1': 'Gray',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '04',
        'description_1': 'Green',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '05',
        'description_1': 'Lime',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '06',
        'description_1': 'Olive',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '07',
        'description_1': 'Yellow',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '08',
        'description_1': 'Purple',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '09',
        'description_1': 'Fuchsia',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '10',
        'description_1': 'Navy',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '11',
        'description_1': 'Blue',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '12',
        'description_1': 'Teal',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '13',
        'description_1': 'Aqua',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '14',
        'description_1': 'Brown',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '15',
        'description_1': 'Chartreuse',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      {
        'detail_code': '16',
        'description_1': 'Black',
        'description_2': null,
        'record_header': 6,
        'udc_group': 'CT',
      },
      // --- Lot Status (LS) ---
      {
        'detail_code': 'A',
        'description_1': 'Active Lot',
        'description_2': null,
        'record_header': 7,
        'udc_group': 'LS',
      },
      {
        'detail_code': 'D',
        'description_1': 'Damaged Lot',
        'description_2': null,
        'record_header': 7,
        'udc_group': 'LS',
      },

      {
        'detail_code': 'E',
        'description_1': 'Expired Lot',
        'description_2': null,
        'record_header': 7,
        'udc_group': 'LS',
      },

      // --- Transaction Type (TT) ---
      {
        'detail_code': 'T',
        'description_1': ' Inventory transfer',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },
      {
        'detail_code': 'I',
        'description_1': 'Inventory issue',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },
      {
        'detail_code': 'A',
        'description_1': 'Inventory adjustment',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },
      {
        'detail_code': 'R',
        'description_1': 'Inventory Receive',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },
      {
        'detail_code': 'M',
        'description_1': 'Migration',
        'description_2': null,
        'record_header': 8,
        'udc_group': 'TT',
      },

      // --- Order Type (OT) ---
      {
        'detail_code': 'SO',
        'description_1': 'Sales Order',
        'description_2': null,
        'record_header': 9,
        'udc_group': 'OT',
      },
      {
        'detail_code': 'PO',
        'description_1': 'Purchase Order',
        'description_2': null,
        'record_header': 9,
        'udc_group': 'OT',
      },
      /* // --- Company Category (CC) ---
      {
        'detail_code': 'SUP',
        'description_1': 'Supplier',
        'description_2': null,
        'record_header': 10,
        'udc_group': 'CC',
      },
      {
        'detail_code': 'CUS',
        'description_1': 'Customer',
        'description_2': null,
        'record_header': 10,
        'udc_group': 'CC',
      },
      {
        'detail_code': 'EMP',
        'description_1': 'Employee',
        'description_2': null,
        'record_header': 10,
        'udc_group': 'CC',
      },

      //---- Category 1 (CT1) ----
      {
        'detail_code': 'CT1',
        'description_1': 'Category 1',
        'description_2': null,
        'record_header': 11,
        'udc_group': 'CT1',
      },
      {
        'detail_code': 'CT1pro',
        'description_1': 'Category 1 pro ',
        'description_2': null,
        'record_header': 11,
        'udc_group': 'CT1',
      },

      //---Category 2 (CT2)---
      {
        'detail_code': 'CT2',
        'description_1': 'Category 2',
        'description_2': null,
        'record_header': 12,
        'udc_group': 'CT2',
      },
      {
        'detail_code': 'CT2pro',
        'description_1': 'Category 2 pro',
        'description_2': null,
        'record_header': 12,
        'udc_group': 'CT2',
      },

      //---Category 3 (CT3)---
      {
        'detail_code': 'CT3',
        'description_1': 'Category 3',
        'description_2': null,
        'record_header': 13,
        'udc_group': 'CT3',
      },
      {
        'detail_code': 'CT3pro',
        'description_1': 'Category 3 pro',
        'description_2': null,
        'record_header': 13,
        'udc_group': 'CT3',
      },*/

      // --- Lot Type (LT) ---
      {
        'detail_code': 'X',
        'description_1': 'Expiration',
        'description_2': 'Expiration Date',
        'record_header': 21,
        'udc_group': 'LT',
      },
      {
        'detail_code': 'F',
        'description_1': 'Effective',
        'description_2': 'Effective Date',
        'record_header': 21,
        'udc_group': 'LT',
      },
      {
        'detail_code': 'R',
        'description_1': 'Receipt',
        'description_2': 'Receipt Date',
        'record_header': 21,
        'udc_group': 'LT',
      },
      {
        'detail_code': 'DG',
        'description_1': 'Damaged Goods',
        'description_2': 'Product arrived broken or defective',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'EG',
        'description_1': 'Expired Goods',
        'description_2': 'Expired items (pharmacy, food, etc.)',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'WI',
        'description_1': 'Wrong Item Supplied',
        'description_2': 'Item mismatch compared to customer order',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'WQ',
        'description_1': 'Wrong Quantity Supplied',
        'description_2': 'More or fewer units supplied than ordered',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'QI',
        'description_1': 'Quality Issues',
        'description_2': 'Customer not satisfied with product quality',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'PR',
        'description_1': 'Product Recall',
        'description_2': 'Manufacturer recall due to safety/defect issues',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'CM',
        'description_1': 'Customer Changed Mind',
        'description_2': 'Return allowed within grace period',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'OC',
        'description_1': 'Order Cancellation',
        'description_2': 'Customer canceled after invoicing but before usage',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'LD',
        'description_1': 'Late Delivery',
        'description_2': 'Goods delivered outside agreed time',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'PI',
        'description_1': 'Packaging Issues',
        'description_2': 'Leaking, tampered, or opened package',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'WC',
        'description_1': 'Warranty / Guarantee Claim',
        'description_2': 'Returned within warranty terms',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'ND',
        'description_1': 'Not as Described',
        'description_2': 'Product specs don’t match description',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'DS',
        'description_1': 'Duplicate Sale',
        'description_2': 'Mistaken duplicate invoice/order',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'W1',
        'description_1': 'Wrong Customer Selected',
        'description_2': 'Sale recorded under wrong customer',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'W2',
        'description_1': 'Wrong Item Selected',
        'description_2': 'Wrong product/service chosen before finalizing sale',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'W3',
        'description_1': 'Wrong Price Applied',
        'description_2': 'Pricing error discovered immediately',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'D1',
        'description_1': 'Discount Mistake',
        'description_2': 'Wrong discount percentage applied',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'P2',
        'description_1': 'Payment Error',
        'description_2':
            'Customer payment failed or incorrect payment recorded',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'C3',
        'description_1': 'Cashier Mistake',
        'description_2': 'Accidental entry (e.g., double billing)',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'T4',
        'description_1': 'Training/Test Transaction',
        'description_2': 'Dummy transactions during training/testing',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S5',
        'description_1': 'System Error / Power Failure',
        'description_2': 'Technical issue during transaction',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'C6',
        'description_1': 'Customer Walked Away / No Payment',
        'description_2': 'Customer didn’t complete purchase',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'FP',
        'description_1': 'Fraud Prevention',
        'description_2': 'Suspicious sale identified and canceled',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'DI',
        'description_1': 'Duplicate Invoice',
        'description_2': 'Accidentally issued two invoices for same order',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'O7',
        'description_1': 'Order Cancelled Before Fulfillment',
        'description_2': 'Sale voided before goods delivered',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S1',
        'description_1': 'Incorrect Size/Variant',
        'description_2':
            'Product returned due to wrong size, color, or variant selection',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S2',
        'description_1': 'Late Defect Discovery',
        'description_2': 'Customer discovers a defect after initial inspection',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S3',
        'description_1': 'Allergic Reaction / Health Issue',
        'description_2':
            'Returned due to personal health issues (pharma, food, etc.)',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S4',
        'description_1': 'Price/Offer Mismatch',
        'description_2':
            'Customer returns because of price difference or promotion mismatch',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S8',
        'description_1': 'Gift Return',
        'description_2':
            'Returned because it was gifted, not wanted by recipient',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S6',
        'description_1': 'Shipping Damage (Carrier Fault)',
        'description_2':
            'Product damaged during transit, not manufacturer fault',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'S7',
        'description_1': 'Seasonal / Promotional Return',
        'description_2': 'Customer returns a promotional or seasonal item',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'V1',
        'description_1': 'Customer Changed Mind Before Payment',
        'description_2': 'Sale canceled before payment attempt',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'V2',
        'description_1': 'System Timeout / Session Expiry',
        'description_2': 'Transaction aborted due to system timeout',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'V3',
        'description_1': 'Inventory Not Available',
        'description_2': 'Sale voided because stock was not actually available',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'V4',
        'description_1': 'Duplicate Entry Detected Before Invoice',
        'description_2': 'Mistaken entry detected before invoicing',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'V5',
        'description_1': 'Promotional / Discount Override Error',
        'description_2':
            'Sale voided because a promotion or discount was misapplied',
        'record_header': 23,
        'udc_group': 'SR',
      },
      {
        'detail_code': 'OT',
        'description_1': 'Others',
        'description_2': 'Other Reason',
        'record_header': 23,
        'udc_group': 'SR',
      },
      // --- Report Frequency (FQ) ---
      {
        'detail_code': 'M',
        'description_1': 'Monthly',
        'description_2': '30',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': '2M',
        'description_1': '2 Months',
        'description_2': '60',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': 'Q',
        'description_1': 'Quarterly',
        'description_2': '90',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': '4M',
        'description_1': '4 Months',
        'description_2': '120',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': '5M',
        'description_1': '5 Months',
        'description_2': '150',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': 'H',
        'description_1': 'Half-Yearly',
        'description_2': '180',
        'record_header': 21,
        'udc_group': 'FQ',
      },
      {
        'detail_code': '7M',
        'description_1': '7 Months',
        'description_2': '210',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': '8M',
        'description_1': '8 Months',
        'description_2': '240',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': '9M',
        'description_1': '9 Months',
        'description_2': '270',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': 'MM',
        'description_1': '10 Months',
        'description_2': '300',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': 'EM',
        'description_1': '11 Months',
        'description_2': '330',
        'record_header': 22,
        'udc_group': 'FQ',
      },
      {
        'detail_code': 'Y',
        'description_1': 'Yearly',
        'description_2': '365',
        'record_header': 22,
        'udc_group': 'FQ',
      },
    ];

    for (final udcDetail in udcDetailsSeedData) {
      // 1. Wrap with withSyncKey to generate the UUID
      final payload = withSyncKey(udcDetail);

      // 2. Await the insert, which returns the auto-incremented ID
      await db.insert('udc_details', payload);

      /*captureSync(
        tableName: 'udc_details',
        entityMap: payload,
        entityId: udcDetail['id'].toString(), // 3. Use the returned ID here
        operation: 'INSERT',
        company: null,
      );*/ //default data is not supposed to sync cuz there is default data in the server already
    }
    developer.log('Inserted default udc headers and details');

    // Seed privileges (system-wide definitions - not company specific)
    await PrivilegeSeeder(databaseService: databaseService).seedPrivileges(db);
    developer.log('Seeded privileges');

    // Seed default system_url_config
    final urlPayload = withSyncKey({
      'config_key': 'server_url', // The key you use to lookup the target URL
      'config_value': 'https://d412-102-218-51-141.ngrok-free.app/stock',
      'environment': 'development',
      'active': 'Y',
      'company': '1',
    });

    await db.insert('system_url_config', urlPayload);
    developer.log(
      'Seeded default system_url_config: ${urlPayload['config_value']}',
    );

    developer.log(
      '✅ Database initialized. User registration will create company data.',
    );
  }
}
