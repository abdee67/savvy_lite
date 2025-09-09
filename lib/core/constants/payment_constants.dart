class PaymentConstants {
  static const Map<String, bool> fieldEnabled = {
    'Discount Amount': false,
    'Withhold Amount': true,
  };
  static const double taxRate = 0.1;
  static const double withholdingRate = 0.02;
  static const double minSubtotalForWithholding = 10000;
}
