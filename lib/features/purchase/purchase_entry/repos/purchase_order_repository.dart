// features/purchase_order/repositories/purchase_order_repository.dart
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/credit_payment_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';

class PurchaseOrderRepository {
  final LocalDatabaseService _databaseService;
  final UdcRepository _udcRepository;

  PurchaseOrderRepository({
    required LocalDatabaseService databaseService,
    required UdcRepository udcRepository,
  }) : _databaseService = databaseService,
       _udcRepository = udcRepository;

  Future<Database> get _db async => _databaseService.database;

  // ============ HEADER CRUD OPERATIONS ============

  Future<int> createPurchaseOrderHeader(PurchaseOrderHeader header) async {
    final db = await _db;
    try {
      return await db.insert('purchase_order_header', header.toMap());
    } catch (e) {
      throw Exception('Failed to create purchase order header: $e');
    }
  }

  Future<void> updatePurchaseOrderHeader(PurchaseOrderHeader header) async {
    final db = await _db;
    try {
      await db.update(
        'purchase_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
    } catch (e) {
      throw Exception('Failed to update purchase order header: $e');
    }
  }

  Future<void> deletePurchaseOrderHeader(int id) async {
    final db = await _db;
    try {
      // First delete all details
      await db.delete(
        'purchase_order_detail',
        where: 'po_header = ?',
        whereArgs: [id],
      );

      // Then delete the header
      await db.delete(
        'purchase_order_header',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order header: $e');
    }
  }

  Future<PurchaseOrderHeader?> getHeaderById(int id) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          poh.*,
          st.supplier_name,
          st.tin_number as supplier_tin,
          st.phone_no_1 as supplier_phone,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          ps.description_1 as payment_status_description,
          ps.detail_code as payment_status_code,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code,
          u.user_name as user_name,
          ct.company_name
        FROM purchase_order_header poh
        LEFT JOIN supplier_table st ON poh.supplier_id = st.id
        LEFT JOIN udc_details pr ON poh.po_receive_status = pr.id
        LEFT JOIN udc_details ps ON poh.payment_status = ps.id
        LEFT JOIN udc_details pi ON poh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON poh.order_type = ot.id
        LEFT JOIN user_table u ON poh.user_id = u.id
        LEFT JOIN company_table ct ON poh.company = ct.id
        WHERE poh.id = ?
        ''',
        [id],
      );

      if (maps.isNotEmpty) {
        return PurchaseOrderHeader.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get purchase order header: $e');
    }
  }

  Future<List<PurchaseOrderHeader>> getPurchaseOrderHeaders({
    required int companyId,
    bool? isCredit,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    final db = await _db;

    try {
      String where = 'poh.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (isCredit != null) {
        if (isCredit) {
          where += ' AND poh.payment_term IS NOT NULL';
        } else {
          where += ' AND poh.payment_term IS NULL';
        }
      }

      if (startDate != null) {
        where += ' AND poh.date_transaction >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND poh.date_transaction <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (purchaseType != null && purchaseType.isNotEmpty) {
        where +=
            ' AND poh.order_type IN (SELECT id FROM udc_details WHERE detail_code = ?)';
        whereArgs.add(purchaseType);
      }

      final query =
          '''
        SELECT 
          poh.*,
     st.supplier_name,
          st.tin_number as supplier_tin,
          st.phone_no_1 as supplier_phone,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          ps.description_1 as payment_status_description,
          ps.detail_code as payment_status_code,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code,
          u.user_name as user_name,
          ct.company_name
        FROM purchase_order_header poh
        LEFT JOIN supplier_table st ON poh.supplier_id = st.id
        LEFT JOIN udc_details pr ON poh.po_receive_status = pr.id
        LEFT JOIN udc_details ps ON poh.payment_status = ps.id
        LEFT JOIN udc_details pi ON poh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON poh.order_type = ot.id
        LEFT JOIN user_table u ON poh.user_id = u.id
        LEFT JOIN company_table ct ON poh.company = ct.id
        WHERE $where
        ORDER BY poh.date_transaction DESC, poh.order_number DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => PurchaseOrderHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order headers: $e');
    }
  }

  //get purchase by details
  Future<List<PurchaseOrderDetail>> getPurchaseOrderDetails({
    required int companyId,
    DateTime? dateEffective,
    DateTime? dateExpiration,
    String? purchaseType,
  }) async {
    final db = await _db;

    try {
      String where = 'pod.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (dateEffective != null) {
        where += ' AND pod.date_effective >= ?';
        whereArgs.add(dateEffective.toIso8601String());
      }

      if (dateExpiration != null) {
        where += ' AND pod.date_expiration <= ?';
        whereArgs.add(dateExpiration.toIso8601String());
      }

      final query =
          '''
     SELECT 
          pod.*,
           it.item_description as item_description,
           it.barcode as item_code,
           it.taxable as taxable,
          poh.order_number as order_number,
          poh.invoice_number as invoice_number,
          poh.date_transaction as date_transaction,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
          
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN items_table it ON pod.item_number = it.id
        LEFT JOIN udc_details pr ON pod.po_receive_status = pr.id
        LEFT JOIN udc_details uom ON pod.unit_of_measure = uom.id
        WHERE $where
        ORDER BY pod.date_transaction DESC, pod.order_number DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => PurchaseOrderDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order headers: $e');
    }
  }

  Future<List<PurchaseOrderHeader>> filterPurchaseOrders({
    required int companyId,
    int? supplierId,
    String? invoiceNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    final db = await _db;

    try {
      String where = 'poh.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (supplierId != null) {
        where += ' AND poh.supplier_id = ?';
        whereArgs.add(supplierId);
      }

      if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
        where += ' AND poh.invoice_number LIKE ?';
        whereArgs.add('%$invoiceNumber%');
      }

      if (startDate != null) {
        where += ' AND poh.date_transaction >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND poh.date_transaction <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (purchaseType != null && purchaseType.isNotEmpty) {
        where +=
            ' AND poh.order_type IN (SELECT id FROM udc_details WHERE detail_code = ?)';
        whereArgs.add(purchaseType);
      }

      final query =
          '''
        SELECT 
          poh.*,
       st.supplier_name,
          st.tin_number as supplier_tin,
          st.phone_no_1 as supplier_phone,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          ps.description_1 as payment_status_description,
          ps.detail_code as payment_status_code,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code,
          u.user_name as user_name,
          ct.company_name
        FROM purchase_order_header poh
        LEFT JOIN supplier_table st ON poh.supplier_id = st.id
        LEFT JOIN udc_details pr ON poh.po_receive_status = pr.id
        LEFT JOIN udc_details ps ON poh.payment_status = ps.id
        LEFT JOIN udc_details pi ON poh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON poh.order_type = ot.id
        LEFT JOIN user_table u ON poh.user_id = u.id
        LEFT JOIN company_table ct ON poh.company = ct.id
        WHERE $where
        ORDER BY poh.id DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => PurchaseOrderHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to filter purchase orders: $e');
    }
  }

  Future<int> getNextOrderNumber(int companyId) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        'SELECT MAX(order_number) as max_order FROM purchase_order_header WHERE company = ?',
        [companyId],
      );

      final maxOrder = result.first['max_order'] as int?;
      return (maxOrder ?? 0) + 1;
    } catch (e) {
      throw Exception('Failed to get next order number: $e');
    }
  }

  Future<PurchaseOrderHeader?> getPurchaseOrderByOrderNumberAndType(
    int orderNumber,
    int orderTypeId,
    int companyId,
  ) async {
    final db = await _db;

    try {
      final maps = await db.rawQuery(
        '''
        SELECT * FROM purchase_order_header 
        WHERE order_number = ? 
          AND order_type = ? 
          AND company = ?
        ''',
        [orderNumber, orderTypeId, companyId],
      );

      if (maps.isNotEmpty) {
        return PurchaseOrderHeader.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get purchase order by order number: $e');
    }
  }

  Future<double> getTotalAmountForHeader(int headerId) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT SUM(amount_extended_cost) as total 
        FROM purchase_order_detail 
        WHERE po_header = ?
        ''',
        [headerId],
      );

      final total = result.first['total'] as double?;
      return total ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total amount for header: $e');
    }
  }

  Future<void> updateHeaderAmounts(int headerId) async {
    final db = await _db;

    try {
      final total = await getTotalAmountForHeader(headerId);
      final header = await getHeaderById(headerId);

      if (header != null) {
        final discount = header.amountDiscount ?? 0;
        final otherCosts = header.amountOtherCosts ?? 0;
        final grossAmount = total - discount;
        final grandTotal = grossAmount + otherCosts;

        await db.update(
          'purchase_order_header',
          {
            'amount_gross': grossAmount,
            'amount_grand_total_cost': grandTotal,
            'amount_open_credit': header.paymentTerm != null
                ? grandTotal
                : null,
          },
          where: 'id = ?',
          whereArgs: [headerId],
        );
      }
    } catch (e) {
      throw Exception('Failed to update header amounts: $e');
    }
  }

  // ============ DETAIL CRUD OPERATIONS ============

  Future<int> createPurchaseOrderDetail(PurchaseOrderDetail detail) async {
    final db = await _db;
    try {
      return await db.insert('purchase_order_detail', detail.toMap());
    } catch (e) {
      throw Exception('Failed to create purchase order detail: $e');
    }
  }

  Future<void> updatePurchaseOrderDetail(PurchaseOrderDetail detail) async {
    final db = await _db;
    try {
      await db.update(
        'purchase_order_detail',
        detail.toMap(),
        where: 'id = ?',
        whereArgs: [detail.id],
      );
    } catch (e) {
      throw Exception('Failed to update purchase order detail: $e');
    }
  }

  Future<void> deletePurchaseOrderDetail(int id) async {
    final db = await _db;
    try {
      await db.delete(
        'purchase_order_detail',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order detail: $e');
    }
  }

  Future<void> deletePurchaseOrderDetailBatch(List<int> ids) async {
    if (ids.isEmpty) return;

    final db = await _db;
    try {
      final placeholders = List.generate(ids.length, (_) => '?').join(',');
      await db.delete(
        'purchase_order_detail',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order detail batch: $e');
    }
  }

  Future<PurchaseOrderDetail?> getDetailById(int id) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          pod.*,
           it.item_description as item_description,
           it.barcode as item_code,
           it.taxable as taxable,
          poh.order_number as order_number,
          poh.invoice_number as invoice_number,
          poh.date_transaction as date_transaction,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
          
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN items_table it ON pod.item_number = it.id
        LEFT JOIN udc_details pr ON pod.po_receive_status = pr.id
        LEFT JOIN udc_details uom ON pod.unit_of_measure = uom.id
        WHERE pod.id = ?
        ''',
        [id],
      );

      if (maps.isNotEmpty) {
        return PurchaseOrderDetail.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get purchase order detail: $e');
    }
  }

  Future<List<PurchaseOrderDetail>> getDetailsByHeaderId(
    int headerId,
    int companyId,
  ) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          pod.*,
           it.item_description as item_description,
           it.barcode as item_code,
           it.taxable as taxable,
          poh.order_number as order_number,
          poh.invoice_number as invoice_number,
          poh.date_transaction as date_transaction,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
          
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN items_table it ON pod.item_number = it.id
        LEFT JOIN udc_details pr ON pod.po_receive_status = pr.id
        LEFT JOIN udc_details uom ON pod.unit_of_measure = uom.id
        WHERE pod.po_header = ? AND pod.company = ?
        ORDER BY pod.id
        ''',
        [headerId, companyId],
      );

      return maps.map((map) => PurchaseOrderDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order details by header: $e');
    }
  }

  Future<List<PurchaseOrderDetail>> filterPurchaseOrderDetails({
    required int companyId,
    int? orderNumber,
    int? supplierId,
    int? itemNumber,
    String? invoiceNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      String where = 'pod.company = ? AND pod.quantity_open <> 0.0';
      List<dynamic> whereArgs = [companyId];

      if (orderNumber != null) {
        where += ' AND poh.order_number = ?';
        whereArgs.add(orderNumber);
      }

      if (supplierId != null) {
        where += ' AND poh.supplier_id = ?';
        whereArgs.add(supplierId);
      }

      if (itemNumber != null) {
        where += ' AND pod.item_number = ?';
        whereArgs.add(itemNumber);
      }

      if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
        where += ' AND poh.invoice_number LIKE ?';
        whereArgs.add('%$invoiceNumber%');
      }

      if (startDate != null) {
        where += ' AND poh.date_transaction >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND poh.date_transaction <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final query =
          '''
        SELECT 
          pod.*,
          it.item_description as item_description,
          poh.order_number as order_number,
          poh.invoice_number as invoice_number,
          poh.date_transaction as date_transaction,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
          
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN items_table it ON pod.item_number = it.id
        LEFT JOIN udc_details pr ON pod.po_receive_status = pr.id
        LEFT JOIN udc_details uom ON pod.unit_of_measure = uom.id
        WHERE $where
        ORDER BY pod.id DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => PurchaseOrderDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to filter purchase order details: $e');
    }
  }

  Future<int> getDetailCountByHeaderId(int headerId) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM purchase_order_detail WHERE po_header = ?',
        [headerId],
      );

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get detail count: $e');
    }
  }

  Future<List<PurchaseOrderDetail>> getOpenPurchaseOrderDetails({
    required int companyId,
    int? supplierId,
    int? itemNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      String where = 'pod.company = ? AND pod.quantity_open > 0';
      List<dynamic> whereArgs = [companyId];

      if (supplierId != null) {
        where += ' AND poh.supplier_id = ?';
        whereArgs.add(supplierId);
      }

      if (itemNumber != null) {
        where += ' AND pod.item_number = ?';
        whereArgs.add(itemNumber);
      }

      if (startDate != null) {
        where += ' AND poh.date_transaction >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND poh.date_transaction <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final query =
          '''
        SELECT 
          pod.*,
          it.item_description as item_description,
          poh.order_number as order_number,
          poh.date_transaction as date_transaction,
          pr.description_1 as po_receive_status_description,
          pr.detail_code as po_receive_status_code
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN items_table it ON pod.item_number = it.id
        LEFT JOIN udc_details pr ON pod.po_receive_status = pr.id
        WHERE $where
        ORDER BY poh.date_transaction ASC, pod.id
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => PurchaseOrderDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get open purchase order details: $e');
    }
  }

  Future<void> updatePurchaseOrderDetailStatus(
    int detailId,
    String statusCode,
  ) async {
    final db = await _db;
    int? recordHeaderId = await _udcRepository.getRecordHeaderId('PR');

    try {
      // Get UDC id for the status
      final udcResult = await db.query(
        'udc_details',
        where: 'detail_code = ? AND record_header = ?',
        whereArgs: [statusCode, recordHeaderId], // PR = Purchase Receive status
      );

      if (udcResult.isNotEmpty) {
        final udcId = udcResult.first['id'] as int;

        await db.update(
          'purchase_order_detail',
          {'po_receive_status': udcId},
          where: 'id = ?',
          whereArgs: [detailId],
        );
      }
    } catch (e) {
      throw Exception('Failed to update purchase order detail status: $e');
    }
  }

  // ============ RECEIVER CRUD OPERATIONS ============

  Future<int> createPurchaseOrderReceiver(
    PurchaseOrderReceiver receiver,
  ) async {
    final db = await _db;
    try {
      return await db.insert('purchase_order_receiver', receiver.toMap());
    } catch (e) {
      throw Exception('Failed to create purchase order receiver: $e');
    }
  }

  Future<void> updatePurchaseOrderReceiver(
    PurchaseOrderReceiver receiver,
  ) async {
    final db = await _db;
    try {
      await db.update(
        'purchase_order_receiver',
        receiver.toMap(),
        where: 'id = ?',
        whereArgs: [receiver.id],
      );
    } catch (e) {
      throw Exception('Failed to update purchase order receiver: $e');
    }
  }

  Future<void> deletePurchaseOrderReceiver(int id) async {
    final db = await _db;
    try {
      await db.delete(
        'purchase_order_receiver',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order receiver: $e');
    }
  }

  Future<void> deletePurchaseOrderReceiverBatch(List<int> ids) async {
    if (ids.isEmpty) return;

    final db = await _db;
    try {
      final placeholders = List.generate(ids.length, (_) => '?').join(',');
      await db.delete(
        'purchase_order_receiver',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order receiver batch: $e');
    }
  }

  Future<PurchaseOrderReceiver?> getReceiverById(int id) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          por.*,
            it.item_description as item_description,
          it.barcode as item_code,
          pod.quantity_transaction as quantity_transaction,
          pod.unit_cost as unit_cost,
          pod.amount_extended_cost as amount_extended_cost,
          br.description as branch_recieved_description,
          lm.location_description as location_description,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
        FROM purchase_order_receiver por
        LEFT JOIN items_table it ON por.item_number = it.id
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN branch_table br ON por.branch_recieved = br.id
        LEFT JOIN location_master lm ON por.location = lm.id
        LEFT JOIN udc_details uom ON por.unit_of_measure = uom.id
        WHERE por.id = ?
        ''',
        [id],
      );

      if (maps.isNotEmpty) {
        return PurchaseOrderReceiver.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get purchase order receiver: $e');
    }
  }

  Future<List<PurchaseOrderReceiver>> getReceiversByDetailId(
    int detailId,
    int companyId,
  ) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          por.*,
          it.item_description as item_description,
          it.barcode as item_code,
          pod.quantity_transaction as quantity_transaction,
          pod.unit_cost as unit_cost,
          pod.amount_extended_cost as amount_extended_cost,
          br.description as branch_recieved_description,
          lm.location_description as location_description,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
        FROM purchase_order_receiver por
        LEFT JOIN items_table it ON por.item_number = it.id
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN branch_table br ON por.branch_recieved = br.id
        LEFT JOIN location_master lm ON por.location = lm.id
        LEFT JOIN udc_details uom ON por.unit_of_measure = uom.id
        WHERE por.po_detail = ? AND por.company = ?
        ORDER BY por.date_received DESC
        ''',
        [detailId, companyId],
      );

      return maps.map((map) => PurchaseOrderReceiver.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order receivers by detail: $e');
    }
  }

  Future<List<PurchaseOrderReceiver>> getReceiversByItemAndDetail({
    required int itemNumber,
    required int detailId,
    required int companyId,
  }) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          por.*,
          it.item_description as item_description,
          it.barcode as item_code,
        FROM purchase_order_receiver por
        LEFT JOIN items_table it ON por.item_number = it.id
        WHERE por.item_number = ? 
          AND por.po_detail = ? 
          AND por.company = ?
        ORDER BY por.date_received DESC
        ''',
        [itemNumber, detailId, companyId],
      );

      return maps.map((map) => PurchaseOrderReceiver.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order receivers by item: $e');
    }
  }

  Future<List<PurchaseOrderReceiver>> getReceiversByHeaderId(
    int headerId,
    int companyId,
  ) async {
    final db = await _db;
    try {
      final maps = await db.rawQuery(
        '''
        SELECT 
          por.*,
          it.item_description as item_description,
          it.barcode as item_code,
          pod.quantity_transaction as quantity_transaction,
          pod.unit_cost as unit_cost,
          pod.amount_extended_cost as amount_extended_cost,
          br.description as branch_recieved_description,
          lm.location_description as location_description,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code
        FROM purchase_order_receiver por
        LEFT JOIN items_table it ON por.item_number = it.id
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN branch_table br ON por.branch_recieved = br.id
        LEFT JOIN location_master lm ON por.location = lm.id
        LEFT JOIN udc_details uom ON por.unit_of_measure = uom.id
        WHERE pod.po_header = ? AND por.company = ?
        ORDER BY por.date_received DESC
        ''',
        [headerId, companyId],
      );

      return maps.map((map) => PurchaseOrderReceiver.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order receivers by header: $e');
    }
  }

  Future<double> getTotalReceivedQuantityByDetail(int detailId) async {
    final db = await _db;
    try {
      final result = await db.rawQuery(
        '''
        SELECT SUM(quantity_recieved) as total_received 
        FROM purchase_order_receiver 
        WHERE po_detail = ?
        ''',
        [detailId],
      );

      final total = result.first['total_received'] as double?;
      return total ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total received quantity: $e');
    }
  }

  // ============ COMPLEX BUSINESS LOGIC OPERATIONS ============

  Future<void> updateHeaderReceiptStatus(int headerId) async {
    final db = await _db;

    try {
      // Get all details for the header with their status
      final details = await db.rawQuery(
        '''
        SELECT 
          pod.id,
          pod.quantity_open,
          pod.po_receive_status,
          pr.detail_code as status_code
        FROM purchase_order_detail pod
        LEFT JOIN udc_details pr ON pod.po_receive_status = pr.id
        WHERE pod.po_header = ?
        ''',
        [headerId],
      );

      if (details.isEmpty) return;

      // Count statuses
      int totalDetails = details.length;
      int partiallyReceived = 0;
      int fullyReceived = 0;

      for (final detail in details) {
        final statusCode = detail['status_code'] as String?;
        final quantityOpen = detail['quantity_open'] as double? ?? 0.0;

        if (statusCode == 'P') {
          // Partially received
          partiallyReceived++;
        } else if (statusCode == 'C' || quantityOpen == 0.0) {
          // Fully received
          fullyReceived++;
        }
      }

      // Determine new header status
      String? newStatusCode;
      if (partiallyReceived > 0) {
        newStatusCode = 'P'; // Partially received
      } else if (fullyReceived == totalDetails) {
        newStatusCode = 'C'; // Fully received
      } else if (fullyReceived == 0 && partiallyReceived == 0) {
        newStatusCode = 'N'; // Not received
      }
      int? recordHeaderId = await _udcRepository.getRecordHeaderId('PR');

      if (newStatusCode != null && recordHeaderId != null) {
        // Get UDC id for the new status
        final udcResult = await db.query(
          'udc_details',
          where: 'detail_code = ? AND record_header = ?',
          whereArgs: [newStatusCode, recordHeaderId],
        );

        if (udcResult.isNotEmpty) {
          final udcId = udcResult.first['id'] as int;

          await db.update(
            'purchase_order_header',
            {
              'po_receive_status': udcId,
              'date_updated': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [headerId],
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update header receipt status: $e');
    }
  }

  Future<void> updateItemCostsForHeader(int headerId) async {
    final db = await _db;

    try {
      // Get all receivers for this header
      final receivers = await db.rawQuery(
        '''
        SELECT 
          por.item_number,
          por.unit_cost,
          por.quantity_recieved,
          por.date_received,
          por.company
        FROM purchase_order_receiver por
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        WHERE pod.po_header = ? AND por.quantity_recieved > 0
        ORDER BY por.date_received DESC
        ''',
        [headerId],
      );

      // Update item costs table for each unique item
      final itemCostsMap = <int, List<Map<String, dynamic>>>{};

      for (final receiver in receivers) {
        final itemNumber = receiver['item_number'] as int?;
        if (itemNumber == null) continue;

        final unitCost = receiver['unit_cost'] as double? ?? 0.0;
        final quantity = receiver['quantity_recieved'] as double? ?? 0.0;
        final dateReceived = receiver['date_received'] as String?;

        if (!itemCostsMap.containsKey(itemNumber)) {
          itemCostsMap[itemNumber] = [];
        }

        itemCostsMap[itemNumber]!.add({
          'unit_cost': unitCost,
          'quantity': quantity,
          'date_received': dateReceived,
          'company': receiver['company'],
        });
      }

      // Calculate weighted average cost for each item
      for (final itemNumber in itemCostsMap.keys) {
        final transactions = itemCostsMap[itemNumber]!;

        double totalCost = 0.0;
        double totalQuantity = 0.0;

        for (final transaction in transactions) {
          final unitCost = transaction['unit_cost'] as double;
          final quantity = transaction['quantity'] as double;

          totalCost += unitCost * quantity;
          totalQuantity += quantity;
        }

        if (totalQuantity > 0) {
          final weightedAverageCost = totalCost / totalQuantity;

          // Update or insert in item_cost table
          final existingCost = await db.query(
            'item_cost',
            where: 'item_number = ?',
            whereArgs: [itemNumber],
          );

          if (existingCost.isNotEmpty) {
            await db.update(
              'item_cost',
              {
                'amount_unit_cost': weightedAverageCost,
                'date_updated': DateTime.now().toIso8601String(),
              },
              where: 'item_number = ?',
              whereArgs: [itemNumber],
            );
          } else {
            await db.insert('item_cost', {
              'item_number': itemNumber,
              'amount_unit_cost': weightedAverageCost,
              'company': transactions.first['company'],
              'date_updated': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update item costs: $e');
    }
  }

  Future<void> updateStockItemAvailability(
    PurchaseOrderReceiver receiver,
  ) async {
    final db = await _db;

    try {
      final itemNumber = receiver.itemNumber;
      final branchRecieved = receiver.branchRecieved;
      final quantityRecieved = receiver.quantityRecieved ?? 0.0;

      if (itemNumber == null ||
          branchRecieved == null ||
          quantityRecieved <= 0) {
        return;
      }

      // Find items_in_branch record
      final itemsInBranch = await db.query(
        'items_in_branch',
        where: 'item_number = ? AND branch = ?',
        whereArgs: [itemNumber, branchRecieved],
      );

      if (itemsInBranch.isNotEmpty) {
        final currentQuantity =
            itemsInBranch.first['quantity_available'] as double? ?? 0.0;
        final newQuantity = currentQuantity + quantityRecieved;

        await db.update(
          'items_in_branch',
          {
            'quantity_available': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [itemsInBranch.first['id']],
        );
      } else {
        // Create new items_in_branch record
        await db.insert('items_in_branch', {
          'item_number': itemNumber,
          'branch': branchRecieved,
          'quantity_available': quantityRecieved,
          'unit_of_measure': receiver.unitOfMeasure,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Update items_table total quantity
      final itemsTable = await db.query(
        'items_table',
        where: 'id = ?',
        whereArgs: [itemNumber],
      );

      if (itemsTable.isNotEmpty) {
        final currentTotal =
            itemsTable.first['quantity_total'] as double? ?? 0.0;
        final newTotal = currentTotal + quantityRecieved;

        await db.update(
          'items_table',
          {
            'quantity_total': newTotal,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [itemNumber],
        );
      }
    } catch (e) {
      throw Exception('Failed to update stock item availability: $e');
    }
  }

  Future<Map<String, dynamic>> getPurchaseOrderStatistics({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_orders,
          SUM(amount_grand_total_cost) as total_amount,
          AVG(amount_grand_total_cost) as average_order,
          COUNT(CASE WHEN po_receive_status IN (SELECT id FROM udc_details WHERE detail_code = 'C') THEN 1 END) as fully_received,
          COUNT(CASE WHEN po_receive_status IN (SELECT id FROM udc_details WHERE detail_code = 'P') THEN 1 END) as partially_received,
          COUNT(CASE WHEN po_receive_status IN (SELECT id FROM udc_details WHERE detail_code = 'N') THEN 1 END) as not_received,
          COUNT(CASE WHEN payment_term IS NOT NULL THEN 1 END) as credit_orders,
          COUNT(CASE WHEN payment_term IS NULL THEN 1 END) as cash_orders
        FROM purchase_order_header 
        WHERE company = ? 
          AND date_transaction BETWEEN ? AND ?
        ''',
        [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      final detailStats = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_items,
          SUM(quantity_transaction) as total_quantity,
          SUM(amount_extended_cost) as total_cost,
          AVG(unit_cost) as average_unit_cost
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        WHERE poh.company = ? 
          AND poh.date_transaction BETWEEN ? AND ?
        ''',
        [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      final receiverStats = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_receipts,
          SUM(quantity_recieved) as total_received_quantity,
          SUM(amount_received) as total_received_cost
        FROM purchase_order_receiver por
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        WHERE poh.company = ? 
          AND por.date_received BETWEEN ? AND ?
        ''',
        [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return {
        'header_stats': result.isNotEmpty
            ? result.first.cast<String, dynamic>()
            : {},
        'detail_stats': detailStats.isNotEmpty
            ? detailStats.first.cast<String, dynamic>()
            : {},
        'receiver_stats': receiverStats.isNotEmpty
            ? receiverStats.first.cast<String, dynamic>()
            : {},
      };
    } catch (e) {
      throw Exception('Failed to get purchase order statistics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrderAgingReport({
    required int companyId,
    DateTime? asOfDate,
  }) async {
    final db = await _db;

    try {
      final effectiveDate = asOfDate ?? DateTime.now();

      final result = await db.rawQuery(
        '''
        SELECT 
          poh.order_number,
          poh.date_transaction,
          poh.credit_due_date,
          poh.amount_open_credit,
          DATEDAY(?, poh.credit_due_date) as days_overdue,
          st.supplier_name,
          st.phone_no_1 as supplier_phone,
          ps.description_1 as payment_status_desc
        FROM purchase_order_header poh
        LEFT JOIN supplier_table st ON poh.supplier_id = st.id
        LEFT JOIN udc_details ps ON poh.payment_status = ps.id
        WHERE poh.company = ? 
          AND poh.payment_term IS NOT NULL 
          AND poh.amount_open_credit > 0
          AND poh.credit_due_date IS NOT NULL
        ORDER BY poh.credit_due_date ASC
        ''',
        [effectiveDate.toIso8601String(), companyId],
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to get purchase order aging report: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierPurchaseSummary({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          st.supplier_name,
          COUNT(poh.id) as order_count,
          SUM(poh.amount_grand_total_cost) as total_purchases,
          SUM(CASE WHEN poh.payment_term IS NOT NULL THEN poh.amount_grand_total_cost ELSE 0 END) as credit_purchases,
          SUM(CASE WHEN poh.payment_term IS NULL THEN poh.amount_grand_total_cost ELSE 0 END) as cash_purchases,
          AVG(poh.amount_grand_total_cost) as average_order_value
        FROM purchase_order_header poh
        LEFT JOIN supplier_table st ON poh.supplier_id = st.id
        WHERE poh.company = ? 
          AND poh.date_transaction BETWEEN ? AND ?
        GROUP BY poh.supplier_id
        ORDER BY total_purchases DESC
        ''',
        [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to get supplier purchase summary: $e');
    }
  }

  // ============ BATCH OPERATIONS ============

  Future<void> createPurchaseOrderHeadersBatch(
    List<PurchaseOrderHeader> headers,
  ) async {
    final db = await _db;
    final batch = db.batch();

    try {
      for (final header in headers) {
        batch.insert('purchase_order_header', header.toMap());
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to create purchase order headers batch: $e');
    }
  }

  Future<void> updatePurchaseOrderHeadersBatch(
    List<PurchaseOrderHeader> headers,
  ) async {
    final db = await _db;
    final batch = db.batch();

    try {
      for (final header in headers) {
        batch.update(
          'purchase_order_header',
          header.toMap(),
          where: 'id = ?',
          whereArgs: [header.id],
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to update purchase order headers batch: $e');
    }
  }

  Future<void> deletePurchaseOrderHeadersBatch(List<int> ids) async {
    if (ids.isEmpty) return;

    final db = await _db;

    try {
      // Delete details first
      final detailPlaceholders = List.generate(
        ids.length,
        (_) => '?',
      ).join(',');
      await db.delete(
        'purchase_order_detail',
        where: 'po_header IN ($detailPlaceholders)',
        whereArgs: ids,
      );

      // Delete receivers for those details
      await db.rawDelete('''
        DELETE FROM purchase_order_receiver 
        WHERE po_detail IN (
          SELECT id FROM purchase_order_detail 
          WHERE po_header IN ($detailPlaceholders)
        )
        ''', ids);

      // Finally delete headers
      await db.delete(
        'purchase_order_header',
        where: 'id IN ($detailPlaceholders)',
        whereArgs: ids,
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order headers batch: $e');
    }
  }

  Future<void> createPurchaseOrderDetailsBatch(
    List<PurchaseOrderDetail> details,
  ) async {
    final db = await _db;
    final batch = db.batch();

    try {
      for (final detail in details) {
        batch.insert('purchase_order_detail', detail.toMap());
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to create purchase order details batch: $e');
    }
  }

  Future<void> updatePurchaseOrderDetailsBatch(
    List<PurchaseOrderDetail> details,
  ) async {
    final db = await _db;
    final batch = db.batch();

    try {
      for (final detail in details) {
        batch.update(
          'purchase_order_detail',
          detail.toMap(),
          where: 'id = ?',
          whereArgs: [detail.id],
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to update purchase order details batch: $e');
    }
  }

  Future<void> createPurchaseOrderReceiversBatch(
    List<PurchaseOrderReceiver> receivers,
  ) async {
    final db = await _db;
    final batch = db.batch();

    try {
      for (final receiver in receivers) {
        batch.insert('purchase_order_receiver', receiver.toMap());
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to create purchase order receivers batch: $e');
    }
  }

  // ============ VALIDATION METHODS ============

  Future<bool> isOrderNumberExists(int orderNumber, int companyId) async {
    final db = await _db;

    try {
      final result = await db.query(
        'purchase_order_header',
        where: 'order_number = ? AND company = ?',
        whereArgs: [orderNumber, companyId],
      );

      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check order number existence: $e');
    }
  }

  Future<bool> canCreateReceipt(PurchaseOrderReceiver receiver) async {
    try {
      if (receiver.quantityOpen == null || receiver.quantityOpen == 0.0) {
        return false;
      }

      if (receiver.quantityRecieved == null ||
          receiver.quantityRecieved == 0.0) {
        return false;
      }

      if (receiver.quantityRecieved! > receiver.quantityOpen!) {
        return false;
      }

      // Check date validity
      if (receiver.dateEffective != null && receiver.dateExpiration != null) {
        if (receiver.dateEffective!.isAfter(receiver.dateExpiration!)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateSupplierHasOpenCredit(
    int supplierId,
    int companyId,
  ) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT SUM(amount_open_credit) as total_open_credit
        FROM purchase_order_header
        WHERE supplier_id = ? 
          AND company = ? 
          AND payment_term IS NOT NULL
          AND amount_open_credit > 0
        ''',
        [supplierId, companyId],
      );

      final totalOpenCredit =
          result.first['total_open_credit'] as double? ?? 0.0;
      return totalOpenCredit > 0;
    } catch (e) {
      throw Exception('Failed to validate supplier credit: $e');
    }
  }

  // ============ UTILITY METHODS ============

  Future<void> executeCustomQuery(String query, List<dynamic> params) async {
    final db = await _db;

    try {
      await db.rawQuery(query, params);
    } catch (e) {
      throw Exception('Failed to execute custom query: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomQueryResults(
    String query,
    List<dynamic> params,
  ) async {
    final db = await _db;

    try {
      return await db.rawQuery(query, params);
    } catch (e) {
      throw Exception('Failed to get custom query results: $e');
    }
  }

  Future<void> clearAllPurchaseOrderData(int companyId) async {
    final db = await _db;

    try {
      // Delete in correct order to respect foreign keys
      await db.delete(
        'purchase_order_receiver',
        where: 'company = ?',
        whereArgs: [companyId],
      );

      await db.delete(
        'purchase_order_detail',
        where: 'company = ?',
        whereArgs: [companyId],
      );

      await db.delete(
        'purchase_order_header',
        where: 'company = ?',
        whereArgs: [companyId],
      );
    } catch (e) {
      throw Exception('Failed to clear purchase order data: $e');
    }
  }
  // Add these methods to your PurchaseOrderRepository class:

  // ============ CREDIT PAYMENT OPERATIONS ============

  /// Get credit payments with optional filters
  Future<List<CreditPayment>> getCreditPayments({
    required int companyId,
    int? poHeaderId,
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
  }) async {
    final db = await _db;

    try {
      String where = 'cp.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (poHeaderId != null) {
        where += ' AND cp.po_header = ?';
        whereArgs.add(poHeaderId);
      }

      if (startDate != null) {
        where += ' AND cp.date_payment >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND cp.date_payment <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (supplierId != null) {
        where += ' AND poh.supplier_id = ?';
        whereArgs.add(supplierId);
      }

      final query =
          '''
      SELECT 
        cp.*,
        poh.order_number as order_number,
        poh.invoice_number as invoice_number,
        pm.description_1 as payment_instrument_description,
        pm.detail_code as payment_instrument_code
      FROM credit_payment_table cp
      LEFT JOIN purchase_order_header poh ON cp.po_header = poh.id
      LEFT JOIN udc_details pm ON cp.payment_instrument = pm.id
      WHERE $where
      ORDER BY cp.date_payment DESC, cp.id DESC
    ''';

      final maps = await db.rawQuery(query, whereArgs);

      // Map to CreditPayment objects (you need to create fromMap method in CreditPayment model)
      return maps.map((map) => CreditPayment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get credit payments: $e');
    }
  }

  /// Create a new credit payment
  Future<int> createCreditPayment(CreditPayment payment) async {
    final db = await _db;
    try {
      return await db.insert('credit_payment_table', payment.toMap());
    } catch (e) {
      throw Exception('Failed to create credit payment: $e');
    }
  }

  /// Update an existing credit payment
  Future<void> updateCreditPayment(CreditPayment payment) async {
    final db = await _db;
    try {
      await db.update(
        'credit_payment_table',
        payment.toMap(),
        where: 'id = ?',
        whereArgs: [payment.id],
      );
    } catch (e) {
      throw Exception('Failed to update credit payment: $e');
    }
  }

  /// Delete a credit payment
  Future<void> deleteCreditPayment(int id) async {
    final db = await _db;
    try {
      await db.delete('credit_payment_table', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete credit payment: $e');
    }
  }

  /// Filter credit payments with various criteria
  Future<List<CreditPayment>> filterCreditPayments({
    required int companyId,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? referenceNumber,
  }) async {
    final db = await _db;

    try {
      String where = 'cp.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (supplierId != null) {
        where += ' AND poh.supplier_id = ?';
        whereArgs.add(supplierId);
      }

      if (startDate != null) {
        where += ' AND cp.date_payment >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND cp.date_payment <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final query =
          '''
      SELECT 
        cp.*,
          poh.order_number as order_number,
        poh.invoice_number as invoice_number,
        pm.description_1 as payment_instrument_description,
        pm.detail_code as payment_instrument_code
      FROM credit_payment_table cp
      LEFT JOIN purchase_order_header poh ON cp.po_header = poh.id
      LEFT JOIN udc_details pm ON cp.payment_instrument = pm.id
      WHERE $where
      ORDER BY cp.date_payment DESC
    ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => CreditPayment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to filter credit payments: $e');
    }
  }

  /// Get total credit payments for a purchase order header
  Future<double> getTotalCreditPaymentsForHeader(int poHeaderId) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        '''
      SELECT SUM(payment_amount) as total_paid
      FROM credit_payment_table
      WHERE po_header = ?
      ''',
        [poHeaderId],
      );

      final total = result.first['total_paid'] as double?;
      return total ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total credit payments for header: $e');
    }
  }

  /// Get credit payment by ID
  Future<CreditPayment?> getCreditPaymentById(int id) async {
    final db = await _db;

    try {
      final maps = await db.rawQuery(
        '''
      SELECT 
        cp.*,
          poh.order_number as order_number,
        poh.invoice_number as invoice_number,
        pm.description_1 as payment_instrument_description,
        pm.detail_code as payment_instrument_code
      FROM credit_payment_table cp
      LEFT JOIN purchase_order_header poh ON cp.po_header = poh.id
      LEFT JOIN udc_details pm ON cp.payment_instrument = pm.id
      WHERE cp.id = ?
      ''',
        [id],
      );

      if (maps.isNotEmpty) {
        return CreditPayment.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get credit payment by ID: $e');
    }
  }

  /// Get credit payments summary by supplier
  Future<List<Map<String, dynamic>>> getCreditPaymentsSummaryBySupplier({
    required int companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      String where = 'cp.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (startDate != null) {
        where += ' AND cp.date_payment >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND cp.date_payment <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final query =
          '''
      SELECT 
        poh.supplier_id,
        st.supplier_name,
        COUNT(cp.id) as payment_count,
        SUM(cp.payment_amount) as total_paid,
        MIN(cp.date_payment) as first_date_payment,
        MAX(cp.date_payment) as last_date_payment
      FROM credit_payment_table cp
      LEFT JOIN purchase_order_header poh ON cp.po_header = poh.id
      LEFT JOIN supplier_table st ON poh.supplier_id = st.id
      WHERE $where
      GROUP BY poh.supplier_id
      ORDER BY total_paid DESC
    ''';

      final result = await db.rawQuery(query, whereArgs);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to get credit payments summary by supplier: $e');
    }
  }

  /// Batch delete credit payments
  Future<void> deleteCreditPaymentBatch(List<int> ids) async {
    if (ids.isEmpty) return;

    final db = await _db;
    try {
      final placeholders = List.generate(ids.length, (_) => '?').join(',');
      await db.delete(
        'credit_payment_table',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e) {
      throw Exception('Failed to delete credit payment batch: $e');
    }
  }

  /// Get credit payment aging report (similar to purchase order aging)
  Future<List<Map<String, dynamic>>> getCreditPaymentAgingReport({
    required int companyId,
    DateTime? asOfDate,
  }) async {
    final db = await _db;

    try {
      final effectiveDate = asOfDate ?? DateTime.now();

      final result = await db.rawQuery(
        '''
      SELECT 
        poh.order_number,
        poh.invoice_number,
        poh.date_transaction as po_date,
        poh.credit_due_date,
        poh.amount_open_credit as remaining_credit,
        cp.date_payment,
        cp.payment_amount,
        DATEDAY(?, poh.credit_due_date) as days_overdue_at_payment,
        st.supplier_name,
        ps.description_1 as payment_status_desc
      FROM credit_payment_table cp
      LEFT JOIN purchase_order_header poh ON cp.po_header = poh.id
      LEFT JOIN supplier_table st ON poh.supplier_id = st.id
      LEFT JOIN udc_details ps ON poh.payment_status = ps.id
      WHERE cp.company = ? 
        AND poh.credit_due_date IS NOT NULL
        AND cp.date_payment <= poh.credit_due_date
      ORDER BY cp.date_payment DESC
      ''',
        [effectiveDate.toIso8601String(), companyId],
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to get credit payment aging report: $e');
    }
  }
}
