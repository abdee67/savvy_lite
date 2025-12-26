import 'package:flutter/material.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/repos/purchase_order_report_repo.dart';

Future<void> debugGRNQuery() async {
  final repo = PurchaseOrderReportRepository();
  print('--- Debugging GRN Report Query ---');
  try {
    // Assuming companyId 1 for testing
    final result = await repo.getPurchaseOrderReceiverReport(
      companyId: 1,
      page: 1,
      pageSize: 10,
    );
    print('Query Success!');
    print('Total Count: ${result['total_count']}');
    final receivers = result['receivers'] as List;
    print('Receivers found: ${receivers.length}');
    if (receivers.isNotEmpty) {
      print('First Receiver: ${receivers.first}');
    }
  } catch (e) {
    print('--- ERROR CAUGHT ---');
    print(e);
  }
  print('--- End Debug ---');
}
