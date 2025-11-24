import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SalesOrderHeader extends Equatable {
  final int? id;
  final DateTime? orderDate;
  final DateTime? requiredDate;
  final DateTime? shippedDate;
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
  final DateTime? creditDateToPay;
  final String? fsNumber;
  final String? voidIndicator;
  final int? customerBillTo;
  final int? customerTableId;
  final int? employeesId;
  final double? amountTotal;
  final int? company;
  final int? paymentTerm;
  final int? paymentStatus;
  final int? orderNumber;
  final double? amountOpen;
  final int? orderType;
  final double? unitCost;
  final double? amountCost;
  final int? tempId;

  // 🔗 Optional joined entities
  final Customer? customerBillToRef;
  final Customer? customerTableRef;
  final Employee? employee;
  final Company? companyRef;
  final UdcDetails? paymentInstrumentRef;
  final UdcDetails? paymentStatusRef;
  final UdcDetails? orderTypeRef;

  const SalesOrderHeader({
    this.id,
    this.orderDate,
    this.requiredDate,
    this.shippedDate,
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
    this.creditDateToPay,
    this.fsNumber,
    this.voidIndicator,
    this.customerBillTo,
    this.customerTableId,
    this.employeesId,
    this.amountTotal,
    this.company,
    this.paymentTerm,
    this.paymentStatus,
    this.orderNumber,
    this.amountOpen,
    this.orderType,
    this.unitCost,
    this.amountCost,
    this.customerBillToRef,
    this.customerTableRef,
    this.employee,
    this.companyRef,
    this.paymentInstrumentRef,
    this.paymentStatusRef,
    this.orderTypeRef,
    this.tempId,
  });

  factory SalesOrderHeader.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return SalesOrderHeader(
      id: map['id'] as int?,
      orderDate: parseDate(map['order_date']),
      requiredDate: parseDate(map['required_date']),
      shippedDate: parseDate(map['shipped_date']),
      salesType: map['sales_type']?.toString(),
      paymentMethod: map['payment_method']?.toString(),
      paymentInstrument: map['payment_instrument'] as int?,
      discount: map['discount']?.toString(),
      addOn: map['add_on']?.toString(),
      tax: (map['tax'] as num?)?.toDouble(),
      withHoldApply: map['with_hold_apply']?.toString(),
      withholdAmount: (map['withhold_amount'] as num?)?.toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble(),
      discountInPercent: (map['discount_in_percent'] as num?)?.toDouble(),
      referenceNote1: map['reference_note1']?.toString(),
      referenceNote2: map['reference_note_2']?.toString(),
      referenceNote3: map['reference_note3']?.toString(),
      referenceNote4: map['reference_note4']?.toString(),
      creditDateToPay: parseDate(map['credit_date_topay']),
      fsNumber: map['fs_number']?.toString(),
      voidIndicator: map['void_indicator']?.toString(),
      customerBillTo: map['customer_bill_to'] as int?,
      customerTableId: map['customer_table_id'] as int?,
      employeesId: map['employees_id'] as int?,
      amountTotal: (map['amount_total'] as num?)?.toDouble(),
      company: map['company'] as int?,
      paymentTerm: map['payment_term'] as int?,
      paymentStatus: map['payment_status'] as int?,
      orderNumber: map['order_number'] as int?,
      amountOpen: (map['amount_open'] as num?)?.toDouble(),
      orderType: map['order_type'] as int?,
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      amountCost: (map['amount_cost'] as num?)?.toDouble(),
      tempId: map['temp_id'] as int?,

      // 👇 Handle joined fields (if joined SELECT is used)
      customerBillToRef: map['customer_bill_to_name'] != null
          ? Customer.fromMap({
              'id': map['customer_bill_to'],
              'name': map['customer_bill_to_name'],
              'email': map['customer_bill_to_email'],
            })
          : null,
      employee: map['employee_name'] != null
          ? Employee.fromMap({
              'id': map['employees_id'],
              'name': map['employee_name'],
              'nameFirst': map['employee_name_first'],
              'nameLast': map['employee_name_last'],
            })
          : null,
      paymentStatusRef: map['payment_status_code'] != null
          ? UdcDetails.fromJson({
              'id': map['payment_status'],
              'code': map['payment_status_code'],
              'description': map['payment_status_description'],
            })
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_date': orderDate?.toIso8601String(),
      'required_date': requiredDate?.toIso8601String(),
      'shipped_date': shippedDate?.toIso8601String(),
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
      'credit_date_topay': creditDateToPay?.toIso8601String(),
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
    };
  }

  SalesOrderHeader copyWith({
    int? id,
    DateTime? orderDate,
    DateTime? requiredDate,
    DateTime? shippedDate,
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
    Customer? customerBillToRef,
    Customer? customerTableRef,
    Employee? employee,
    Company? companyRef,
    UdcDetails? paymentInstrumentRef,
    UdcDetails? paymentStatusRef,
    UdcDetails? orderTypeRef,
    int? tempId,
  }) {
    return SalesOrderHeader(
      id: id ?? this.id,
      orderDate: orderDate ?? this.orderDate,
      requiredDate: requiredDate ?? this.requiredDate,
      shippedDate: shippedDate ?? this.shippedDate,
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
      customerBillToRef: customerBillToRef ?? this.customerBillToRef,
      customerTableRef: customerTableRef ?? this.customerTableRef,
      employee: employee ?? this.employee,
      companyRef: companyRef ?? this.companyRef,
      paymentInstrumentRef: paymentInstrumentRef ?? this.paymentInstrumentRef,
      paymentStatusRef: paymentStatusRef ?? this.paymentStatusRef,
      orderTypeRef: orderTypeRef ?? this.orderTypeRef,
      tempId: tempId ?? this.tempId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderDate,
    requiredDate,
    shippedDate,
    salesType,
    paymentMethod,
    paymentInstrument,
    discount,
    addOn,
    tax,
    withHoldApply,
    withholdAmount,
    discountAmount,
    discountInPercent,
    referenceNote1,
    referenceNote2,
    referenceNote3,
    referenceNote4,
    creditDateToPay,
    fsNumber,
    voidIndicator,
    customerBillTo,
    customerTableId,
    employeesId,
    amountTotal,
    company,
    paymentTerm,
    paymentStatus,
    orderNumber,
    amountOpen,
    orderType,
    unitCost,
    amountCost,
    customerBillToRef,
    customerTableRef,
    employee,
    companyRef,
    paymentInstrumentRef,
    paymentStatusRef,
    orderTypeRef,
    employee,
    customerBillTo,
    customerTableId,
    customerBillToRef,
    customerTableRef,
    employee,
    companyRef,
    paymentInstrumentRef,
    paymentStatusRef,
    orderTypeRef,
    tempId,
  ];
}
