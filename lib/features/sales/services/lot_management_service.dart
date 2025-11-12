// features/sales/services/lot_management_service.dart
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';

class LotManagementService {
  final LotMasterRepository lotMasterRepository;
  final LotExpirationColorsRepository expirationColorsRepository;

  LotManagementService({
    required this.lotMasterRepository,
    required this.expirationColorsRepository,
  });
}
