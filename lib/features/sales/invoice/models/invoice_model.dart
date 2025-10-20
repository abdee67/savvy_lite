import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class InvoiceModel extends Equatable {
  final String id;
  final DateTime date;
  final CustomerInfo customer;
  final List<ConfirmedItem> items;
  final PaymentInfo payment;

  const InvoiceModel({
    required this.id,
    required this.date,
    required this.customer,
    required this.items,
    required this.payment,
  });

  factory InvoiceModel.fromOrderAndPayment({
    required String orderId,
    required DateTime orderDate,
    required Customer customer,
    required List<ConfirmedItem> confirmedItems,
    required PaymentModel paymentModel,
  }) {
    return InvoiceModel(
      id: orderId,
      date: orderDate,
      customer: CustomerInfo.fromCustomer(customer),
      items: confirmedItems,
      payment: PaymentInfo.fromPaymentModel(paymentModel, confirmedItems),
    );
  }

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  List<Object?> get props => [id, date, customer, items, payment];
}

class CustomerInfo extends Equatable {
  final String name;
  final String tin;
  final String address;
  final String phone;

  const CustomerInfo({
    required this.name,
    required this.tin,
    required this.address,
    required this.phone,
  });

  factory CustomerInfo.fromCustomer(Customer customer) {
    // Build address from available fields
    String address = customer.country!;
    if (customer.city != null && customer.city!.isNotEmpty) {
      address = '${customer.city}, $address';
    }
    if (customer.address1 != null && customer.address1!.isNotEmpty) {
      address = '${customer.address1}, $address';
    }
    if (customer.state != null && customer.state!.isNotEmpty) {
      address = '${customer.state}, $address';
    }

    return CustomerInfo(
      name: customer.customerName!,
      tin: customer.tinNumber!,
      address: address,
      phone: customer.phoneNumber!,
    );
  }

  @override
  List<Object?> get props => [name, tin, address, phone];
}

class PaymentInfo extends Equatable {
  final String paymentType;
  final String paymentMethod;
  final String paymentInstrument;
  final String paymentTerm;
  final double subtotal;
  final double discountAmount;
  final double withholdingAmount;
  final double taxAmount;
  final double totalAmount;

  const PaymentInfo({
    required this.paymentType,
    required this.paymentMethod,
    required this.paymentInstrument,
    required this.paymentTerm,
    required this.subtotal,
    required this.discountAmount,
    required this.withholdingAmount,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory PaymentInfo.fromPaymentModel(
    PaymentModel paymentModel,
    List<ConfirmedItem> confirmedItems,
  ) {
    final subtotal = confirmedItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    return PaymentInfo(
      paymentType: paymentModel.paymentType,
      paymentMethod: paymentModel.paymentMethod,
      paymentInstrument: paymentModel.paymentInstrument,
      paymentTerm: paymentModel.paymentTerm,
      subtotal: subtotal,
      discountAmount: paymentModel.discountAmount,
      withholdingAmount: paymentModel.withholdingAmount,
      taxAmount: paymentModel.taxAmount,
      totalAmount:
          subtotal - paymentModel.discountAmount + paymentModel.taxAmount,
    );
  }

  @override
  List<Object?> get props => [
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
    subtotal,
    discountAmount,
    withholdingAmount,
    taxAmount,
    totalAmount,
  ];
}
