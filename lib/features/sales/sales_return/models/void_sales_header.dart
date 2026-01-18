// =============================
// Sales Return Header Model
// =============================

import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SalesReturnHeader {
  final int? id;

  final DateTime? orderDate;
  final DateTime? requiredDate;
  final DateTime? shippedDate;
  final DateTime? returnDate;

  final String? salesType;
  final String? paymentMethod;
  final int? paymentInstrument;

  final String? discount;
  final String? addOn;

  final double? tax;
  final String? withHoldApply;
  final double? withholdAmount;

  final double? discountAmount;
  final double? discountInPercent;

  final String? referenceNote1;
  final String? referenceNote2;
  final String? referenceNote3;
  final String? referenceNote4;

  final String? commentsSales;
  final DateTime? creditDateToPay;

  final String? fsNumber;
  final String? voidIndicator;

  final int customerBillTo;
  final int customerTableId;
  final int employeesId;

  final double? amountTotal;
  final int? company;
  final int? paymentTerm;
  final int? paymentStatus;

  final int? orderNumber;
  final double? amountOpen;
  final int? orderType;

  final double? unitCost;
  final double? amountCost;
  final int? returnStatus;

  final String? salesRepresent;
  final String? commentForReturn;

  final int? tempId;
  //joins from sales order headr table
  final Customer? customerBillToRef;
  final Employee? employeeRef;
  final Customer? customerTableIdRef;
  final UdcDetails? paymentTermRef;
  final UdcDetails? paymentStatusRef;
  final UdcDetails? paymentInstrumentRef;
  final UdcDetails? returnStatusRef;
  final Company? companyRef;

  // ================
  // Constructor
  // ================
  SalesReturnHeader({
    this.id,
    this.orderDate,
    this.requiredDate,
    this.shippedDate,
    this.returnDate,
    this.salesType,
    this.paymentMethod,
    this.paymentInstrument,
    this.discount,
    this.addOn,
    this.tax,
    this.withHoldApply,
    this.withholdAmount,
    this.discountAmount,
    this.discountInPercent,
    this.referenceNote1,
    this.referenceNote2,
    this.referenceNote3,
    this.referenceNote4,
    this.commentsSales,
    this.creditDateToPay,
    this.fsNumber,
    this.voidIndicator,
    required this.customerBillTo,
    required this.customerTableId,
    required this.employeesId,
    this.amountTotal,
    this.company,
    this.paymentTerm,
    this.paymentStatus,
    this.orderNumber,
    this.amountOpen,
    this.orderType,
    this.unitCost,
    this.amountCost,
    this.returnStatus,
    this.salesRepresent,
    this.commentForReturn,
    this.tempId,
    this.customerBillToRef,
    this.employeeRef,
    this.customerTableIdRef,
    this.paymentTermRef,
    this.paymentStatusRef,
    this.returnStatusRef,
    this.paymentInstrumentRef,
    this.companyRef,
  });

  // ============================
  // Map Conversion Helpers
  // ============================
  factory SalesReturnHeader.fromMap(Map<String, dynamic> map) {
    return SalesReturnHeader(
      id: map['id'] as int?,
      orderDate: _toDate(map['order_date']),
      requiredDate: _toDate(map['required_date']),
      shippedDate: _toDate(map['shipped_date']),
      returnDate: _toDate(map['return_date']),
      salesType: map['sales_type']?.toString(),
      paymentMethod: map['payment_method']?.toString(),
      paymentInstrument: map['payment_instrument'],
      discount: map['discount']?.toString(),
      addOn: map['add_on']?.toString(),
      tax: _toDouble(map['tax']),
      withHoldApply: map['with_hold_apply']?.toString(),
      withholdAmount: _toDouble(map['withhold_amount']),
      discountAmount: _toDouble(map['discount_amount']),
      discountInPercent: _toDouble(map['discount_in_percent']),
      referenceNote1: map['reference_note1']?.toString(),
      referenceNote2: map['reference_note_2']?.toString(),
      referenceNote3: map['reference_note3']?.toString(),
      referenceNote4: map['reference_note4']?.toString(),
      commentsSales: map['comments_sales']?.toString(),
      creditDateToPay: _toDate(map['credit_date_topay']),
      fsNumber: map['fs_number']?.toString(),
      voidIndicator: map['void_indicator']?.toString(),
      customerBillTo: map['customer_bill_to'],
      customerTableId: map['customer_table_id'],
      employeesId: map['employees_id'],
      amountTotal: _toDouble(map['amount_total']),
      company: map['company'],
      paymentTerm: map['payment_term'],
      paymentStatus: map['payment_status'],
      orderNumber: map['order_number'],
      amountOpen: _toDouble(map['amount_open']),
      orderType: map['order_type'],
      unitCost: _toDouble(map['unit_cost']),
      amountCost: _toDouble(map['amount_cost']),
      returnStatus: map['return_status'],
      salesRepresent: map['sales_represent']?.toString(),
      commentForReturn: map['comment_for_return']?.toString(),
      tempId: map['temp_id'],
      customerBillToRef: map['customer_bill_to_ref'] != null
          ? Customer(
              id: map['customer_bill_to'],
              contactName: map['customer_bill_to_ref']?.toString(),
            )
          : null,
      employeeRef: map['employees_id'] != null
          ? Employee(
              id: map['employees_id'],
              nameFirst: map['first_name']?.toString() ?? '',
              nameLast: map['last_name']?.toString() ?? '',
              nameMiddle: map['middle_name']?.toString() ?? '',
              email: map['email']?.toString() ?? '',
              phone: map['phone']?.toString() ?? '',
              address: map['address']?.toString(),
            )
          : null,
      customerTableIdRef: map['customer_table_id'] != null
          ? Customer(
              id: map['customer_table_id'],
              contactName: map['customer_name_ref']?.toString(),
            )
          : null,
      paymentTermRef: map['payment_term'] != null
          ? UdcDetails(
              id: map['payment_term'],
              detailCode: map['payment_term_code']?.toString() ?? '',
              description1: map['payment_term_ref']?.toString() ?? '',
            )
          : null,
      paymentStatusRef: map['payment_status'] != null
          ? UdcDetails(
              id: map['payment_status'],
              detailCode: map['payment_status_code']?.toString() ?? '',
              description1: map['payment_status_ref']?.toString() ?? '',
            )
          : null,
      paymentInstrumentRef: map['payment_instrument'] != null
          ? UdcDetails(
              id: map['payment_instrument'],
              detailCode: map['payment_instrument_code']?.toString() ?? '',
              description1: map['payment_instrument_ref']?.toString() ?? '',
            )
          : null,
      returnStatusRef: map['return_status'] != null
          ? UdcDetails(
              id: map['return_status'],
              detailCode: map['return_status_code']?.toString() ?? '',
              description1: map['return_status_ref']?.toString() ?? '',
            )
          : null,
      companyRef: map['company'] != null
          ? Company(
              id: map['company'],
              companyName: map['company_name']?.toString() ?? '',
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_date': _fromDate(orderDate),
      'required_date': _fromDate(requiredDate),
      'shipped_date': _fromDate(shippedDate),
      'return_date': _fromDate(returnDate),
      'sales_type': salesType,
      'payment_method': paymentMethod,
      'payment_instrument': paymentInstrument,
      'discount': discount,
      'add_on': addOn,
      'tax': tax,
      'with_hold_apply': withHoldApply,
      'withhold_amount': withholdAmount,
      'discount_amount': discountAmount,
      'discount_in_percent': discountInPercent,
      'reference_note1': referenceNote1,
      'reference_note_2': referenceNote2,
      'reference_note3': referenceNote3,
      'reference_note4': referenceNote4,
      'comments_sales': commentsSales,
      'credit_date_topay': _fromDate(creditDateToPay),
      'fs_number': fsNumber,
      'void_indicator': voidIndicator,
      'customer_bill_to': customerBillTo,
      'customer_table_id': customerTableId,
      'employees_id': employeesId,
      'amount_total': amountTotal,
      'company': company,
      'payment_term': paymentTerm,
      'payment_status': paymentStatus,
      'order_number': orderNumber,
      'amount_open': amountOpen,
      'order_type': orderType,
      'unit_cost': unitCost,
      'amount_cost': amountCost,
      'return_status': returnStatus,
      'sales_represent': salesRepresent,
      'comment_for_return': commentForReturn,
    };
  }

  // ====================
  // Copy With
  // ====================
  SalesReturnHeader copyWith({
    int? id,
    DateTime? orderDate,
    DateTime? requiredDate,
    DateTime? shippedDate,
    DateTime? returnDate,
    String? salesType,
    String? paymentMethod,
    int? paymentInstrument,
    String? discount,
    String? addOn,
    double? tax,
    String? withHoldApply,
    double? withholdAmount,
    double? discountAmount,
    double? discountInPercent,
    String? referenceNote1,
    String? referenceNote2,
    String? referenceNote3,
    String? referenceNote4,
    String? commentsSales,
    DateTime? creditDateToPay,
    String? fsNumber,
    String? voidIndicator,
    int? customerBillTo,
    int? customerTableId,
    int? employeesId,
    double? amountTotal,
    int? company,
    int? paymentTerm,
    int? paymentStatus,
    int? orderNumber,
    double? amountOpen,
    int? orderType,
    double? unitCost,
    double? amountCost,
    int? returnStatus,
    String? salesRepresent,
    String? commentForReturn,
    int? tempId,
    Customer? customerBillToRef,
    Customer? customerTableIdRef,
    Employee? employeeRef,
    UdcDetails? paymentTermRef,
    UdcDetails? paymentStatusRef,
    UdcDetails? paymentInstrumentRef,
    UdcDetails? returnStatusRef,
    Company? companyRef,
  }) {
    return SalesReturnHeader(
      id: id ?? this.id,
      orderDate: orderDate ?? this.orderDate,
      requiredDate: requiredDate ?? this.requiredDate,
      shippedDate: shippedDate ?? this.shippedDate,
      returnDate: returnDate ?? this.returnDate,
      salesType: salesType ?? this.salesType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      discount: discount ?? this.discount,
      addOn: addOn ?? this.addOn,
      tax: tax ?? this.tax,
      withHoldApply: withHoldApply ?? this.withHoldApply,
      withholdAmount: withholdAmount ?? this.withholdAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountInPercent: discountInPercent ?? this.discountInPercent,
      referenceNote1: referenceNote1 ?? this.referenceNote1,
      referenceNote2: referenceNote2 ?? this.referenceNote2,
      referenceNote3: referenceNote3 ?? this.referenceNote3,
      referenceNote4: referenceNote4 ?? this.referenceNote4,
      commentsSales: commentsSales ?? this.commentsSales,
      creditDateToPay: creditDateToPay ?? this.creditDateToPay,
      fsNumber: fsNumber ?? this.fsNumber,
      voidIndicator: voidIndicator ?? this.voidIndicator,
      customerBillTo: customerBillTo ?? this.customerBillTo,
      customerTableId: customerTableId ?? this.customerTableId,
      employeesId: employeesId ?? this.employeesId,
      amountTotal: amountTotal ?? this.amountTotal,
      company: company ?? this.company,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderNumber: orderNumber ?? this.orderNumber,
      amountOpen: amountOpen ?? this.amountOpen,
      orderType: orderType ?? this.orderType,
      unitCost: unitCost ?? this.unitCost,
      amountCost: amountCost ?? this.amountCost,
      returnStatus: returnStatus ?? this.returnStatus,
      salesRepresent: salesRepresent ?? this.salesRepresent,
      commentForReturn: commentForReturn ?? this.commentForReturn,
      tempId: tempId ?? this.tempId,
      customerBillToRef: customerBillToRef ?? this.customerBillToRef,
      customerTableIdRef: customerTableIdRef ?? this.customerTableIdRef,
      employeeRef: employeeRef ?? this.employeeRef,
      paymentTermRef: paymentTermRef ?? this.paymentTermRef,
      paymentStatusRef: paymentStatusRef ?? this.paymentStatusRef,
      paymentInstrumentRef: paymentInstrumentRef ?? this.paymentInstrumentRef,
      returnStatusRef: returnStatusRef ?? this.returnStatusRef,
      companyRef: companyRef ?? this.companyRef,
    );
  }
}

//
// Helpers
//
DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String? _fromDate(DateTime? d) {
  return d?.toIso8601String();
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  return double.tryParse(v.toString());
}
