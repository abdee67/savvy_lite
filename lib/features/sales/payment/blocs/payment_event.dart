import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

@immutable
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class LoadPayment extends PaymentEvent {
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;
  final Customer customer;

  const LoadPayment({
    required this.confirmedItems,
    required this.totalAmount,
    required this.customer,
  });

  @override
  List<Object> get props => [confirmedItems, totalAmount, customer];
}

class LoadFeeSystemConstants extends PaymentEvent {
  const LoadFeeSystemConstants();

  @override
  List<Object> get props => [];
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
  final double subtotal;
  final double discountAmount;
  final bool isWithholdingEnabled;

  const UpdateTaxAndFees({
    required this.subtotal,
    required this.discountAmount,
    this.isWithholdingEnabled = false,
  });

  @override
  List<Object> get props => [subtotal, discountAmount, isWithholdingEnabled];
}

class PaymentSuccess extends PaymentEvent {
  final String transactionID;

  const PaymentSuccess({required this.transactionID});

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
  const CancelPayment();

  @override
  List<Object> get props => [];
}

class ResetPayment extends PaymentEvent {
  const ResetPayment();

  @override
  List<Object> get props => [];
}

class WaitForSystemConstants extends PaymentEvent {
  const WaitForSystemConstants();

  @override
  List<Object> get props => [];
}
