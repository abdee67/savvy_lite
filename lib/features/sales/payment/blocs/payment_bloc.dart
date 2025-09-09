import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/constants/payment_constants.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(const PaymentState()) {
    on<LoadPayment>(_onLoadPayment);
    on<UpdatePaymentDetails>(_onUpdatePaymentDetails);
    on<UpdateTaxAndFees>(_onUpdateTaxAndFees);
    on<ProcessPayment>(_onProcessPayment);
    on<PaymentSuccess>(_onPaymentSuccess);
    on<PaymentFailure>(_onPaymentFailure);
    on<CancelPayment>(_onCancelPayment);
    on<ResetPayment>(_onResetPayment);
  }

  void _onLoadPayment(LoadPayment event, Emitter<PaymentState> emit) {
    try {
      final subtotal = event.confirmedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      final taxAmount = subtotal * PaymentConstants.taxRate;

      emit(
        state.copyWith(
          status: PaymentStatus.ready,
          confirmedItems: event.confirmedItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          totalAmount: event.totalAmount,
          withholdingAmount: 0, // Start with 0, will be set when user enables it
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: 'Failed to load payment: ${e.toString()}',
        ),
      );
    }
  }

  void _onUpdatePaymentDetails(
    UpdatePaymentDetails event,
    Emitter<PaymentState> emit,
  ) {
    emit(
      state.copyWith(
        paymentType: event.paymentType,
        paymentMethod: event.paymentMethod,
        paymentInstrument: event.paymentInstrument,
        paymentTerm: event.paymentTerm,
      ),
    );
  }

  void _onUpdateTaxAndFees(UpdateTaxAndFees event, Emitter<PaymentState> emit) {
    final taxAmount = event.subtotal * PaymentConstants.taxRate;
    
    // Calculate withholding only if it's enabled and subtotal meets minimum
    double newWithholdingAmount = 0;
    if (event.isWithholdingEnabled && 
        event.subtotal > PaymentConstants.minSubtotalForWithholding) {
      newWithholdingAmount = event.subtotal * PaymentConstants.withholdingRate;
    }

    emit(
      state.copyWith(
        subtotal: event.subtotal,
        taxAmount: taxAmount,
        withholdingAmount: newWithholdingAmount,
        discountAmount: event.discountAmount,
        isWithholdingEnabled: event.isWithholdingEnabled,
      ),
    );
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    // Validate payment details
    if (!state.isValid) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: 'Please complete all payment details',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PaymentStatus.processing));

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    if (random.nextDouble() > 0.2) {
      final transactionID = _generateTransactionID();
      final paymentModel = PaymentModel.fromPaymentState(
        id: transactionID,
        transactionID: transactionID,
        state: state,
        paymentStatus: 'Completed',
      );

      add(PaymentSuccess(transactionID: transactionID));
    } else {
      add(
        const PaymentFailure(
          errorMessage: 'Payment processing failed. Please try again.',
        ),
      );
    }
  }

  void _onPaymentSuccess(PaymentSuccess event, Emitter<PaymentState> emit) {
    emit(
      state.copyWith(
        status: PaymentStatus.success,
        transactionID: event.transactionID,
        errorMessage: null,
      ),
    );

    // Auto-reset after success
    Future.delayed(const Duration(seconds: 3), () {
      add(const ResetPayment());
    });
  }

  void _onPaymentFailure(PaymentFailure event, Emitter<PaymentState> emit) {
    emit(
      state.copyWith(
        status: PaymentStatus.failure,
        errorMessage: event.errorMessage,
        transactionID: null,
      ),
    );
  }

  void _onCancelPayment(CancelPayment event, Emitter<PaymentState> emit) {
    emit(
      state.copyWith(
        status: PaymentStatus.cancelled,
        errorMessage: 'Payment was cancelled by user',
      ),
    );
  }

  void _onResetPayment(ResetPayment event, Emitter<PaymentState> emit) {
    emit(const PaymentState());
  }

  String _generateTransactionID() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'TXN$timestamp${random.nextInt(1000)}';
  }
}
