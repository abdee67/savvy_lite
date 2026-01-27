import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class QuotationOrderHeader {
  final int? id;
  final int orderNumber;

  final DateTime? orderDate;
  final DateTime? conversionDate;
  final DateTime? requiredDate;
  final DateTime? shippedDate;

  final String? salesType;
  final int quotationValidationInDays;

  final String? paymentMethod;
  final int? paymentInstrument;
  final int? paymentTerm;
  final int? paymentStatus;

  final DateTime? creditDateToPay;

  final String currencyCode;
  final double exchangeRate;

  final String? discount;
  final double? discountAmount;
  final double? discountInPercent;

  final String? addOn;
  final double? tax;

  final String? withHoldApply;
  final double? withholdAmount;

  final double? amountTotal;
  final double? amountOpen;

  final double? unitCost;
  final double? amountCost;

  final int? orderType;
  final String orderStatus;
  final String? conversionStatus;
  final String? proformaStatus;
  final String? voidIndicator;

  final String? referenceNote1;
  final String? referenceNote2;
  final String? referenceNote3;
  final String? referenceNote4;

  final String? externalRefNumber;
  final String? fsNumber;
  final String? salesRepresent;
  final String? convertedItems;

  final int customerBillTo;
  final int customerTableId;
  final int employeesId;

  final int? company;
  final int? branchId;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;

  final String? commentsReason;
  final int? tempId;

  //JOIN related entities
  final Customer? customerBillToRef;
  final Customer? customerTableRef;
  final Employee? employeeRef;
  final UdcDetails? paymentInstrumentRef;
  final UdcDetails? paymentTermRef;
  final UdcDetails? paymentStatusRef;
  final UdcDetails? paymentMethodRef;
  final UdcDetails? orderTypeRef;
  final Branch? branchRef;

  QuotationOrderHeader({
    this.id,
    required this.orderNumber,
    this.orderDate,
    this.conversionDate,
    this.requiredDate,
    this.shippedDate,
    this.salesType,
    this.quotationValidationInDays = 30,
    this.paymentMethod,
    this.paymentInstrument,
    this.paymentTerm,
    this.paymentStatus,
    this.creditDateToPay,
    this.currencyCode = 'ETB',
    this.exchangeRate = 1,
    this.discount,
    this.discountAmount,
    this.discountInPercent,
    this.addOn,
    this.tax,
    this.withHoldApply,
    this.withholdAmount,
    this.amountTotal,
    this.amountOpen,
    this.unitCost,
    this.amountCost,
    this.orderType,
    this.orderStatus = 'Draft',
    this.conversionStatus,
    this.proformaStatus,
    this.voidIndicator,
    this.referenceNote1,
    this.referenceNote2,
    this.referenceNote3,
    this.referenceNote4,
    this.externalRefNumber,
    this.fsNumber,
    this.salesRepresent,
    this.convertedItems,
    required this.customerBillTo,
    required this.customerTableId,
    required this.employeesId,
    this.company,
    this.branchId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.commentsReason,
    this.tempId,
    this.customerBillToRef,
    this.customerTableRef,
    this.employeeRef,
    this.paymentInstrumentRef,
    this.paymentTermRef,
    this.paymentStatusRef,
    this.paymentMethodRef,
    this.orderTypeRef,
    this.branchRef,
  });

  // --------------------
  //  JSON & DB MAPPING
  // --------------------

  factory QuotationOrderHeader.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(String? v) => v == null ? null : DateTime.tryParse(v);

    return QuotationOrderHeader(
      id: map['id'],
      orderNumber: map['order_number'],
      orderDate: parseDate(map['order_date']),
      conversionDate: parseDate(map['conversion_date']),
      requiredDate: parseDate(map['required_date']),
      shippedDate: parseDate(map['shipped_date']),
      salesType: map['sales_type'],
      quotationValidationInDays: map['quotation_validation_in_days'] ?? 30,
      paymentMethod: map['payment_method'],
      paymentInstrument: map['payment_instrument'],
      paymentTerm: map['payment_term'],
      paymentStatus: map['payment_status'],
      creditDateToPay: parseDate(map['credit_date_topay']),
      currencyCode: map['currency_code'] ?? 'ETB',
      exchangeRate: (map['exchange_rate'] ?? 1).toDouble(),
      discount: map['discount'],
      discountAmount: map['discount_amount']?.toDouble(),
      discountInPercent: map['discount_in_percent']?.toDouble(),
      addOn: map['add_on'],
      tax: map['tax']?.toDouble(),
      withHoldApply: map['with_hold_apply'],
      withholdAmount: map['withhold_amount']?.toDouble(),
      amountTotal: map['amount_total']?.toDouble(),
      amountOpen: map['amount_open']?.toDouble(),
      unitCost: map['unit_cost']?.toDouble(),
      amountCost: map['amount_cost']?.toDouble(),
      orderType: map['order_type'],
      orderStatus: map['order_status'] ?? 'Draft',
      conversionStatus: map['conversion_status'],
      proformaStatus: map['prforma_status'],
      voidIndicator: map['void_indicator'],
      referenceNote1: map['reference_note1'],
      referenceNote2: map['reference_note_2'],
      referenceNote3: map['reference_note3'],
      referenceNote4: map['reference_note4'],
      externalRefNumber: map['external_ref_number'],
      fsNumber: map['fs_number'],
      salesRepresent: map['sales_represent'],
      convertedItems: map['converted_items'],
      customerBillTo: map['customer_bill_to'],
      customerTableId: map['customer_table_id'],
      employeesId: map['employees_id'],
      company: map['company'],
      branchId: map['branch_id'],
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      commentsReason: map['comments_reason'],
      customerBillToRef: map['customer_bill_to_name'] != null
          ? Customer(
              id: map['customer_bill_to'],
              customerName: map['customer_bill_to_name'],
            )
          : null,
      customerTableRef: map['customer_table_name'] != null
          ? Customer(
              id: map['customer_table_id'],
              customerName: map['customer_table_name'],
            )
          : null,
      employeeRef: map['employee_first_name'] != null
          ? Employee(
              id: map['employees_id'],
              nameFirst: map['employee_first_name'],
              nameMiddle: map['employee_middle_name'],
              nameLast: map['employee_last_name'],
              email: map['employee_email'],
              phone: map['employee_phone'],
              address: map['employee_address'],
              city: map['employee_city'],
            )
          : null,
      paymentInstrumentRef: map['payment_instrument_description'] != null
          ? UdcDetails(
              id: map['payment_instrument'],
              description1: map['payment_instrument_description'],
              detailCode: map['payment_instrument_detail_code'],
            )
          : null,
      paymentTermRef: map['payment_term'] != null
          ? UdcDetails(
              id: map['payment_term'],
              description1: map['payment_term_description'],
              detailCode: map['payment_term_detail_code'],
            )
          : null,
      paymentStatusRef: map['payment_status_description'] != null
          ? UdcDetails(
              id: map['payment_status'],
              description1: map['payment_status_description'],
              detailCode: map['payment_status_detail_code'],
            )
          : null,
      paymentMethodRef: map['payment_method_description'] != null
          ? UdcDetails(
              id: map['payment_method'],
              description1: map['payment_method_description'],
              detailCode: map['payment_method_detail_code'],
            )
          : null,
      orderTypeRef: map['order_type_description'] != null
          ? UdcDetails(
              id: map['order_type'],
              description1: map['order_type_description'],
              detailCode: map['order_type_detail_code'],
            )
          : null,
      branchRef: map['branch_name'] != null
          ? Branch(id: map['branch_id'], description: map['branch_name'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    String? toDate(DateTime? dt) => dt?.toIso8601String();

    return {
      'id': id,
      'order_number': orderNumber,
      'order_date': toDate(orderDate),
      'conversion_date': toDate(conversionDate),
      'required_date': toDate(requiredDate),
      'shipped_date': toDate(shippedDate),
      'sales_type': salesType,
      'quotation_validation_in_days': quotationValidationInDays,
      'payment_method': paymentMethod,
      'payment_instrument': paymentInstrument,
      'payment_term': paymentTerm,
      'payment_status': paymentStatus,
      'credit_date_topay': toDate(creditDateToPay),
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'discount': discount,
      'discount_amount': discountAmount,
      'discount_in_percent': discountInPercent,
      'add_on': addOn,
      'tax': tax,
      'with_hold_apply': withHoldApply,
      'withhold_amount': withholdAmount,
      'amount_total': amountTotal,
      'amount_open': amountOpen,
      'unit_cost': unitCost,
      'amount_cost': amountCost,
      'order_type': orderType,
      'order_status': orderStatus,
      'conversion_status': conversionStatus,
      'prforma_status': proformaStatus,
      'void_indicator': voidIndicator,
      'reference_note1': referenceNote1,
      'reference_note_2': referenceNote2,
      'reference_note3': referenceNote3,
      'reference_note4': referenceNote4,
      'external_ref_number': externalRefNumber,
      'fs_number': fsNumber,
      'sales_represent': salesRepresent,
      'converted_items': convertedItems,
      'customer_bill_to': customerBillTo,
      'customer_table_id': customerTableId,
      'employees_id': employeesId,
      'company': company,
      'branch_id': branchId,
      'created_at': toDate(createdAt),
      'updated_at': toDate(updatedAt),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'comments_reason': commentsReason,
    };
  }

  QuotationOrderHeader copyWith({
    int? id,
    int? orderNumber,
    DateTime? orderDate,
    DateTime? conversionDate,
    DateTime? requiredDate,
    DateTime? shippedDate,
    String? salesType,
    int? quotationValidationInDays,
    String? paymentMethod,
    int? paymentInstrument,
    int? paymentTerm,
    int? paymentStatus,
    DateTime? creditDateToPay,
    String? currencyCode,
    double? exchangeRate,
    String? discount,
    double? discountAmount,
    double? discountInPercent,
    String? addOn,
    double? tax,
    String? withHoldApply,
    double? withholdAmount,
    double? amountTotal,
    double? amountOpen,
    double? unitCost,
    double? amountCost,
    int? orderType,
    String? orderStatus,
    String? conversionStatus,
    String? proformaStatus,
    String? voidIndicator,
    String? referenceNote1,
    String? referenceNote2,
    String? referenceNote3,
    String? referenceNote4,
    String? externalRefNumber,
    String? fsNumber,
    String? salesRepresent,
    String? convertedItems,
    int? customerBillTo,
    int? customerTableId,
    int? employeesId,
    int? company,
    int? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
    String? commentsReason,
    int? tempId,
    Customer? customerBillToRef,
    Customer? customerTableRef,
    Employee? employeeRef,
    Branch? branchRef,
    UdcDetails? paymentMethodRef,
    UdcDetails? paymentInstrumentRef,
    UdcDetails? paymentTermRef,
    UdcDetails? paymentStatusRef,
    UdcDetails? orderTypeRef,
  }) {
    return QuotationOrderHeader(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      conversionDate: conversionDate ?? this.conversionDate,
      requiredDate: requiredDate ?? this.requiredDate,
      shippedDate: shippedDate ?? this.shippedDate,
      salesType: salesType ?? this.salesType,
      quotationValidationInDays:
          quotationValidationInDays ?? this.quotationValidationInDays,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      creditDateToPay: creditDateToPay ?? this.creditDateToPay,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      discount: discount ?? this.discount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountInPercent: discountInPercent ?? this.discountInPercent,
      addOn: addOn ?? this.addOn,
      tax: tax ?? this.tax,
      withHoldApply: withHoldApply ?? this.withHoldApply,
      withholdAmount: withholdAmount ?? this.withholdAmount,
      amountTotal: amountTotal ?? this.amountTotal,
      amountOpen: amountOpen ?? this.amountOpen,
      unitCost: unitCost ?? this.unitCost,
      amountCost: amountCost ?? this.amountCost,
      orderType: orderType ?? this.orderType,
      orderStatus: orderStatus ?? this.orderStatus,
      conversionStatus: conversionStatus ?? this.conversionStatus,
      proformaStatus: proformaStatus ?? this.proformaStatus,
      voidIndicator: voidIndicator ?? this.voidIndicator,
      referenceNote1: referenceNote1 ?? this.referenceNote1,
      referenceNote2: referenceNote2 ?? this.referenceNote2,
      referenceNote3: referenceNote3 ?? this.referenceNote3,
      referenceNote4: referenceNote4 ?? this.referenceNote4,
      externalRefNumber: externalRefNumber ?? this.externalRefNumber,
      fsNumber: fsNumber ?? this.fsNumber,
      salesRepresent: salesRepresent ?? this.salesRepresent,
      convertedItems: convertedItems ?? this.convertedItems,
      customerBillTo: customerBillTo ?? this.customerBillTo,
      customerTableId: customerTableId ?? this.customerTableId,
      employeesId: employeesId ?? this.employeesId,
      company: company ?? this.company,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      commentsReason: commentsReason ?? this.commentsReason,
      tempId: tempId ?? this.tempId,
      customerBillToRef: customerBillToRef ?? this.customerBillToRef,
      customerTableRef: customerTableRef ?? this.customerTableRef,
      employeeRef: employeeRef ?? this.employeeRef,
      branchRef: branchRef ?? this.branchRef,
      paymentMethodRef: paymentMethodRef ?? this.paymentMethodRef,
      paymentInstrumentRef: paymentInstrumentRef ?? this.paymentInstrumentRef,
      paymentTermRef: paymentTermRef ?? this.paymentTermRef,
      paymentStatusRef: paymentStatusRef ?? this.paymentStatusRef,
      orderTypeRef: orderTypeRef ?? this.orderTypeRef,
    );
  }
}
