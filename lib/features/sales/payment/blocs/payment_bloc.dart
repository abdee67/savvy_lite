import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final SystemConstantsService _systemConstantsService;
  StreamSubscription? _systemConstantsSubscription;
  bool _isSystemConstantsLoaded = false;

  PaymentBloc(this._systemConstantsService) : super(const PaymentState()) {
    on<LoadPayment>(_onLoadPayment);
    on<UpdatePaymentDetails>(_onUpdatePaymentDetails);
    on<UpdateTaxAndFees>(_onUpdateTaxAndFees);
    on<ProcessPayment>(_onProcessPayment);
    on<PaymentSuccess>(_onPaymentSuccess);
    on<PaymentFailure>(_onPaymentFailure);
    on<CancelPayment>(_onCancelPayment);
    on<ResetPayment>(_onResetPayment);
    on<LoadFeeSystemConstants>(_onLoadFeeSystemConstants);

    // Listen to system constants changes properly
    _systemConstantsSubscription = _systemConstantsService.systemConstantsStream
        .listen(
          (systemConstant) {
            if (systemConstant != null) {
              _isSystemConstantsLoaded = true;
              add(const LoadFeeSystemConstants());
            }
          },
          onError: (error) {
            emit(
              state.copyWith(
                systemConstantsError: 'System constants error: $error',
              ),
            );
          },
        );

    // Load system constants initially
    _loadInitialSystemConstants();
  }

  Future<void> _loadInitialSystemConstants() async {
    try {
      await _systemConstantsService.ensureLoaded();
      _isSystemConstantsLoaded = true;
      add(const LoadFeeSystemConstants());
    } catch (e) {
      emit(
        state.copyWith(
          systemConstantsError: 'Failed to load system constants: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _systemConstantsSubscription?.cancel();
    return super.close();
  }

  void _onLoadFeeSystemConstants(
    LoadFeeSystemConstants event,
    Emitter<PaymentState> emit,
  ) {
    try {
      final vatRate = _systemConstantsService.vatRate;
      final withholdingRate = _systemConstantsService.withholdingRate;
      final withholdingInitial = _systemConstantsService.withholdingInitial;

      developer.log('VAT Rate: $vatRate');
      developer.log('Withholding Rate: $withholdingRate');
      developer.log('Withholding Initial: $withholdingInitial');
      emit(
        state.copyWith(
          vatRate: vatRate,
          withholdingRate: withholdingRate,
          withholdingInitial: withholdingInitial,
          systemConstantsError: _systemConstantsService.error,
        ),
      );

      // Recalculate taxes and fees with new rates
      if (state.subtotal > 0) {
        add(
          UpdateTaxAndFees(
            subtotal: state.subtotal,
            discountAmount: state.discountAmount,
            isWithholdingEnabled: state.isWithholdingEnabled,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          systemConstantsError:
              'Failed to load system constants: ${e.toString()}',
        ),
      );
    }
  }

  void _onLoadPayment(LoadPayment event, Emitter<PaymentState> emit) {
    try {
      final subtotal = event.confirmedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final vatRate = _systemConstantsService.vatRate;
      final withholdingRate = _systemConstantsService.withholdingRate;
      final withholdingInitial = _systemConstantsService.withholdingInitial;

      final taxAmount = _systemConstantsService.calculateTaxAmount(subtotal);
      final canApplyWithholding = _systemConstantsService
          .shouldApplyWithholding(subtotal);
      developer.log('Tax Amount: $taxAmount');
      developer.log('Can Apply Withholding: $canApplyWithholding');
      emit(
        state.copyWith(
          status: PaymentStatus.ready,
          confirmedItems: event.confirmedItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          grandTotal: event.totalAmount,
          withholdingAmount: 0,
          customer: event.customer,
          vatRate: vatRate,
          withholdingRate: withholdingRate,
          withholdingInitial: withholdingInitial,
          canApplyWithholding: canApplyWithholding,
          systemConstantsError: _systemConstantsService.error,
        ),
      );
    } catch (e) {
      developer.log('Failed to load payment: ${e.toString()}');
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: 'Failed to load payment: ${e.toString()}',
          systemConstantsError: _systemConstantsService.error,
        ),
      );
    }
  }

  void _onUpdateTaxAndFees(UpdateTaxAndFees event, Emitter<PaymentState> emit) {
    try {
      // Use the current rates from the service
      final vatRate = _systemConstantsService.vatRate;
      final withholdingRate = _systemConstantsService.withholdingRate;
      final withholdingInitial = _systemConstantsService.withholdingInitial;

      final taxAmount = event.subtotal * (vatRate / 100);
      developer.log('Tax Amount: $taxAmount');
      // Calculate withholding only if it's enabled and subtotal meets minimum
      double newWithholdingAmount = 0;
      if (event.isWithholdingEnabled) {
        if (event.subtotal >= withholdingInitial) {
          newWithholdingAmount = event.subtotal * (withholdingRate / 100);
        }
      }

      final grandTotal =
          event.subtotal +
          taxAmount -
          event.discountAmount -
          newWithholdingAmount;

      final canApplyWithholding = event.subtotal >= withholdingInitial;

      emit(
        state.copyWith(
          subtotal: event.subtotal,
          taxAmount: taxAmount,
          withholdingAmount: newWithholdingAmount,
          discountAmount: event.discountAmount,
          isWithholdingEnabled: event.isWithholdingEnabled,
          grandTotal: grandTotal,
          canApplyWithholding: canApplyWithholding,
          systemConstantsError: _systemConstantsService.error,
          vatRate: vatRate,
          withholdingRate: withholdingRate,
          withholdingInitial: withholdingInitial,
        ),
      );
    } catch (e) {
      developer.log('Failed to update tax and fees: ${e.toString()}');
      emit(state.copyWith(systemConstantsError: _systemConstantsService.error));
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

  PaymentState get currentState => state;
  String? get transactionID => state.transactionID;
}
