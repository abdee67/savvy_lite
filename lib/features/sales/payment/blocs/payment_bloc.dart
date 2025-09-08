import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(const PaymentState()) {
    on<LoadPayment>(_onLoadPayment);
    on<UpdatePaymentDetails>(_onUpdatePaymentDetails);
    on<UpdateTaxAndFees>(_onUpdateTaxAndFees);
    on<ProcessPayment>(_onProcessPayment);
    on<PaymentSucess>(_onPaymentSuccess);
    on<PaymentFailure>(_onPaymentFailure);
    on<ResetPayment>(_onResetPayment);
  }

  Future<void> _onLoadPayment(
    LoadPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final subtotal = event.confirmedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final taxAmount = subtotal * 0.1; // 10% tax

      emit(
        state.copyWith(
          status: PaymentStatus.ready,
          confirmedItems: event.confirmedItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          totalAmount: event.totalAmount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdatePaymentDetails(
    UpdatePaymentDetails event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          paymentType: event.paymentType,
          paymentMethod: event.paymentMethod,
          paymentInstrument: event.paymentInstrument,
          paymentTerm: event.paymentTerm,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateTaxAndFees(
    UpdateTaxAndFees event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          taxAmount: event.taxAmount,
          withholdingAmount: event.withholdingAmount,
          discountAmount: event.discountAmount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
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
      try {
        await Future.delayed(const Duration(seconds: 2));
        final random = Random();
        if (random.nextDouble() > 0.2) {
          final transactionID = random.nextInt(100000).toString();
          add(PaymentSucess(transactionID: transactionID));
        } else {
          add(
            const PaymentFailure(
              errorMessage: 'Payment processing failed.Please try again.',
            ),
          );
        }
      } catch (e) {
        add(const PaymentFailure(errorMessage: 'An unexpected error occured.'));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onPaymentSuccess(PaymentSucess event, Emitter<PaymentState> emit) {
    emit(
      state.copyWith(
        status: PaymentStatus.success,
        transactionID: event.transactionID,
        errorMessage: null,
      ),
    );

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

  void _onResetPayment(ResetPayment event, Emitter<PaymentState> emit) {
    try {
      emit(const PaymentState());
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  String _getTransactionID() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'TXN$timestamp${random.nextInt(1000)}';
  }
}
