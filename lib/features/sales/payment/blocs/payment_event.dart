import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';

@immutable
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class LoadPayment extends PaymentEvent {
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;

  const LoadPayment({required this.confirmedItems, required this.totalAmount});

  @override
  List<Object> get props => [confirmedItems, totalAmount];
}

class ProcessPayment extends PaymentEvent {
  const ProcessPayment();

  @override
  List<Object> get props => [];
}

class UpdatePaymentDetails extends PaymentEvent {
  final String paymentType;
  final String paymentMethod;
  final String paymentInstrument;
  final String paymentTerm;

  const UpdatePaymentDetails({
    required this.paymentType,
    required this.paymentMethod,
    required this.paymentInstrument,
    required this.paymentTerm,
  });

  @override
  List<Object> get props => [
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
  ];
}

class UpdateTaxAndFees extends PaymentEvent {
  final double taxAmount;
  final double withholdingAmount;
  final double discountAmount;

  const UpdateTaxAndFees({
    required this.taxAmount,
    required this.withholdingAmount,
    required this.discountAmount,
  });

  @override
  List<Object> get props => [taxAmount, withholdingAmount, discountAmount];
}

class PaymentSucess extends PaymentEvent {
  final String transactionID;

  const PaymentSucess({required this.transactionID});

  @override
  List<Object> get props => [transactionID];
}

class PaymentFailure extends PaymentEvent {
  final String errorMessage;

  const PaymentFailure({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

class CancelPayment extends PaymentEvent {
  final PaymentModel payment;
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;

  const CancelPayment({
    required this.payment,
    required this.confirmedItems,
    required this.totalAmount,
  });

  @override
  List<Object> get props => [payment, confirmedItems, totalAmount];
}

class ResetPayment extends PaymentEvent {
  const ResetPayment();

  @override
  List<Object> get props => [];
}
