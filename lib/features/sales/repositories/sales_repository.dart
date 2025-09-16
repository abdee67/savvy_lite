import 'package:dartz/dartz.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

abstract class SalesRepository {
  Future<Either<Fail, bool>> processPayment(
    PaymentModel payment,
    List<ConfirmedItem> items,
    double totalAmount,
  );

  Future<Either<Fail, List<PaymentModel>>> getPaymentHistory();
  Future<Either<Fail, PaymentModel>> getPaymentDetails(String transactionId);
}

class SalesRepositoryImpl implements SalesRepository {
  @override
  Future<Either<Fail, bool>> processPayment(
    PaymentModel payment,
    List<ConfirmedItem> items,
    double totalAmount,
  ) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Here you would typically make an API call to your backend
      // For now, we'll simulate a successful payment
      return const Right(true);
    } catch (e) {
      return Left(Fail(e.toString()));
    }
  }

  @override
  Future<Either<Fail, List<PaymentModel>>> getPaymentHistory() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Return empty list for simulation
      return const Right([]);
    } catch (e) {
      return Left(Fail(e.toString()));
    }
  }

  @override
  Future<Either<Fail, PaymentModel>> getPaymentDetails(
    String transactionId,
  ) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Return dummy data for simulation
      return Right(
        PaymentModel(
          id: '',
          transactionID: '',
          paymentType: 'Cash',
          paymentMethod: '',
          paymentInstrument: 'Cash',
          paymentTerm: '',
          paymentStatus: '',
          paymentDate: DateTime.now(),
          amount: 0,
          discountAmount: 0,
          withholdingAmount: 0,
          taxAmount: 0,
        ),
      );
    } catch (e) {
      return Left(Fail(e.toString()));
    }
  }
}
