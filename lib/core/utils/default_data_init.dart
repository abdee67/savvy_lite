import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/services/auth/auth_service.dart';

class DefaultDataInitializer {
  static Future<void> ensureDefaultData() async {
    // This will automatically create default data when needed
    // through the repository's fallback mechanisms
    if (kDebugMode) {
      print('Default data initializer ready - data will be created on demand');
    }
  }

  static Future<SystemConstant> getDefaultSystemConstants() async {
    final authService = getIt<AuthService>();
    final companyId = authService.currentCompany?.id;

    return SystemConstant(
      applyLotMgm: 'N',
      applyLocationMgm: 'Y',
      decimalPlaces: 2,
      generateBarcodeForItem: 'N',
      company: companyId,
      rateVatPercentage: 15.0,
      rateWithholdingPercentage: 2.0,
      withHoldInitials: 1000.0,
      autoSalesPrice: 'N',
      lotQtyAutoForSales: 'Y',
      locationCategoryLevel: 1,
    );
  }
}
