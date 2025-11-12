// features/sales/sales_order_details/blocs/sales_order_details_event.dart

import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

abstract class SalesOrderDetailsEvent {
  const SalesOrderDetailsEvent();
}

// Initialization events
class SalesOrderDetailsInitialized extends SalesOrderDetailsEvent {
  final int companyId;

  const SalesOrderDetailsInitialized({required this.companyId});
}

class ValidateStockForOrder extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;

  const ValidateStockForOrder({required this.item});
}

class ValidateAllStockForOrder extends SalesOrderDetailsEvent {
  const ValidateAllStockForOrder();
}

class AvailableValidatorMethod extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;

  const AvailableValidatorMethod({required this.item});
}

class SystemConstantUpdate extends SalesOrderDetailsEvent {
  final SystemConstant systemConstant;

  const SystemConstantUpdate({required this.systemConstant});
}

class LoadSalesOrderDetails extends SalesOrderDetailsEvent {
  final int companyId;

  const LoadSalesOrderDetails({required this.companyId});
}

class LoadSalesOrderDetailsByHeader extends SalesOrderDetailsEvent {
  final int headerId;

  const LoadSalesOrderDetailsByHeader({required this.headerId});
}

// CRUD Operations
class CreateSalesOrderDetails extends SalesOrderDetailsEvent {
  final SalesOrderDetail details;

  const CreateSalesOrderDetails({required this.details});
}

class UpdateSalesOrderDetails extends SalesOrderDetailsEvent {
  final SalesOrderDetail details;

  const UpdateSalesOrderDetails({required this.details});
}

class DeleteSalesOrderDetails extends SalesOrderDetailsEvent {
  final int id;

  const DeleteSalesOrderDetails({required this.id});
}

class DeleteSalesOrderDetailsBatch extends SalesOrderDetailsEvent {
  final List<int> ids;

  const DeleteSalesOrderDetailsBatch({required this.ids});
}

// UI State Management (equivalent to Java preparation methods)
class PrepareCreate extends SalesOrderDetailsEvent {
  const PrepareCreate();
}

class PrepareCreateAfterCreate extends SalesOrderDetailsEvent {
  const PrepareCreateAfterCreate();
}

class PrepareCopy extends SalesOrderDetailsEvent {
  const PrepareCopy();
}

class PrepareCreateInCreate extends SalesOrderDetailsEvent {
  const PrepareCreateInCreate();
}

class PrepareCreate1 extends SalesOrderDetailsEvent {
  const PrepareCreate1();
}

class PrepareCreateInEdit extends SalesOrderDetailsEvent {
  const PrepareCreateInEdit();
}

class PrepareEdit extends SalesOrderDetailsEvent {
  const PrepareEdit();
}

class CancelUpdate extends SalesOrderDetailsEvent {
  const CancelUpdate();
}

class CancelCreate extends SalesOrderDetailsEvent {
  const CancelCreate();
}

class Discard extends SalesOrderDetailsEvent {
  const Discard();
}

// Item Management in Lists
class AddToCreateItems extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;

  const AddToCreateItems({required this.item});
}

class UpdateInCreateItems extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;
  final int index;

  const UpdateInCreateItems({required this.item, required this.index});
}

class RemoveFromCreateItems extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;

  const RemoveFromCreateItems({required this.item});
}

class RemoveFromEditItems extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;

  const RemoveFromEditItems({required this.item});
}

class ClearCreateItems extends SalesOrderDetailsEvent {
  const ClearCreateItems();
}

class ClearEditItems extends SalesOrderDetailsEvent {
  const ClearEditItems();
}

// Selection Management
class SetSelected extends SalesOrderDetailsEvent {
  final SalesOrderDetail? selected;

  const SetSelected({this.selected});
}

class SetSelected1 extends SalesOrderDetailsEvent {
  final SalesOrderDetail? selected1;

  const SetSelected1({this.selected1});
}

class SetSelected2 extends SalesOrderDetailsEvent {
  final SalesOrderDetail? selected2;

  const SetSelected2({this.selected2});
}

class SetMultiSelectionItems extends SalesOrderDetailsEvent {
  final List<SalesOrderDetail> items;

  const SetMultiSelectionItems({required this.items});
}

// Barcode and Stock Validation
class SetUseBarcode extends SalesOrderDetailsEvent {
  final bool useBarcode;

  const SetUseBarcode({required this.useBarcode});
}

class SetBarCode extends SalesOrderDetailsEvent {
  final String barCode;

  const SetBarCode({required this.barCode});
}

class ScanBarcode extends SalesOrderDetailsEvent {
  const ScanBarcode();
}

class ValidateStockAvailability extends SalesOrderDetailsEvent {
  final SalesOrderDetail salesOrderDetail;

  const ValidateStockAvailability({required this.salesOrderDetail});
}

class ValidateAllStockAvailability extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;
  const ValidateAllStockAvailability({required this.item});
}

// Calculations
class CalculateExtendedPrice extends SalesOrderDetailsEvent {
  final SalesOrderDetail item;

  const CalculateExtendedPrice({required this.item});
}

class CalculateAllExtendedPrices extends SalesOrderDetailsEvent {
  const CalculateAllExtendedPrices();
}

class UpdateUnitPriceWithUom extends SalesOrderDetailsEvent {
  final SalesOrderDetail salesOrderDetail;
  final ItemInBranchModel? itemsInBranch;

  const UpdateUnitPriceWithUom({
    required this.salesOrderDetail,
    this.itemsInBranch,
  });
}

class CalculateItemCost extends SalesOrderDetailsEvent {
  final SalesOrderDetail salesOrderDetail;

  const CalculateItemCost({required this.salesOrderDetail});
}

class CalculateAllItemCosts extends SalesOrderDetailsEvent {
  final List<SalesOrderDetail> salesOrderDetail;
  final int companyId;
  const CalculateAllItemCosts({
    required this.salesOrderDetail,
    required this.companyId,
  });
}

class ReverseStockOnVoid extends SalesOrderDetailsEvent {
  final int salesOrderId;
  final bool applyLotMgm;
  const ReverseStockOnVoid({
    required this.salesOrderId,
    required this.applyLotMgm,
  });
}

// Filtering and Search
class FilterSalesOrderDetails extends SalesOrderDetailsEvent {
  final int? customerTableId;
  final int? itemsTableId;
  final String? fsNumber;
  final String? proformaNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? orderStatus;
  final bool? voidIndicator;
  final bool? detailTransaction;
  final String? salesRepresent;

  const FilterSalesOrderDetails({
    this.customerTableId,
    this.itemsTableId,
    this.fsNumber,
    this.proformaNumber,
    this.startDate,
    this.endDate,
    this.orderStatus,
    this.voidIndicator,
    this.detailTransaction,
    this.salesRepresent,
  });
}

class SetFilteredValues extends SalesOrderDetailsEvent {
  final List<SalesOrderDetail> filteredValues;

  const SetFilteredValues({required this.filteredValues});
}

// Batch Operations
class SaveCreateItems extends SalesOrderDetailsEvent {
  final int salesOrderHeaderId;

  const SaveCreateItems({required this.salesOrderHeaderId});
}

class SaveEditItems extends SalesOrderDetailsEvent {
  const SaveEditItems();
}

class SaveRow extends SalesOrderDetailsEvent {
  const SaveRow();
}

// Utility Events
class RefreshSalesOrderDetails extends SalesOrderDetailsEvent {
  const RefreshSalesOrderDetails();
}

class SetFirst extends SalesOrderDetailsEvent {
  final int first;

  const SetFirst({required this.first});
}

class SetAvailablitySelections extends SalesOrderDetailsEvent {
  final String availablitySelections;

  const SetAvailablitySelections({required this.availablitySelections});
}

class ResetSalesOrderDetails extends SalesOrderDetailsEvent {
  const ResetSalesOrderDetails();
}
