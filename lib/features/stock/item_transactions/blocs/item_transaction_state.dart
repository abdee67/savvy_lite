import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';

enum ItemTransactionsStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  processing,
  searching,
  exporting,
  success,
  error,
  failure,
  loadingItemTransactionReport,
  loadedItemTransactionReport,
  loadingMoreItemTransactionReport,
  exportingItemTransactionReport,
  exportItemTransactionReportSuccess,
}

class ItemTransactionsState extends Equatable {
  final ItemTransactionsStatus status;
  final List<ItemTransactionModel> transactions;
  final List<ItemTransactionModel> filteredTransactions;
  final List<ItemTransactionModel> createItems;
  final List<ItemTransactionModel> editItems;
  final List<ItemTransactionModel> exportedTransactions;
  final String? successmessage;
  final String? error;
  final List<ItemTransactionModel> selectedItems;
  final ItemTransactionModel? selected;
  final ItemTransactionModel? selected1;
  final ItemTransactionModel? selected2;
  final ItemTransactionModel? editingItem;
  final String? searchQuery;
  final bool isSelectionMode;
  final Map<String, dynamic>? filters;
  final double totalQuantity;
  final double totalCost;
  final double openingAmount;
  final double totlaAmount;
  //for daily stock report
  final double openingQuantityBefore;
  final double openingQuantityBeforeToday;
  final double salesQtyOnDate;
  final double differenceSalesQty;
  //for balance stock item
  final double openingAmountBefore;
  final double openingAmountInitial;
  final double purchaseAmountOnDate;
  final double salesAmountOnDate;
  final double salesAmountOnThisDateCOS;
  final double grossProfitOnThisDate;
  final double amountEnding;

  final bool isDuplicate;
  final int? companyId;

  //dropdown data
  final List<ItemLocation> availableLocations;
  final List<LotMaster> availableLots;
  final List<ItemLocation> availableToLocations;
  final List<ItemInBranchModel> availableItems;
  final Map<int, String> uomDescriptions; // Cache for UoM descriptions
  final bool loadingUoMDescription;

  // Loading states for dropdowns
  final bool loadingLocations;
  final bool loadingLots;
  final bool loadingToLocations;
  final bool loadingItems;

  //report data
  final List<ItemTransactionModel> itemTransactionReportItems;
  final int itemTransactionReportPage;
  final int itemTransactionReportTotalPages;
  final int itemTransactionReportTotalCount;
  final double itemTransactionReportTotalCost;
  final bool hasMoreItemTransactionReport;

  const ItemTransactionsState({
    this.status = ItemTransactionsStatus.initial,
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.exportedTransactions = const [],
    this.successmessage,
    this.error,
    this.selectedItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.editingItem,
    this.searchQuery,
    this.isSelectionMode = false,
    this.filters,
    this.totalQuantity = 0.0,
    this.totalCost = 0.0,
    this.openingAmount = 0.0,
    this.totlaAmount = 0.0,
    this.openingQuantityBefore = 0.0,
    this.openingQuantityBeforeToday = 0.0,
    this.salesQtyOnDate = 0.0,
    this.differenceSalesQty = 0.0,
    this.openingAmountBefore = 0.0,
    this.openingAmountInitial = 0.0,
    this.purchaseAmountOnDate = 0.0,
    this.salesAmountOnDate = 0.0,
    this.salesAmountOnThisDateCOS = 0.0,
    this.grossProfitOnThisDate = 0.0,
    this.amountEnding = 0.0,
    this.companyId,
    this.isDuplicate = false,
    this.availableLocations = const [],
    this.availableLots = const [],
    this.availableToLocations = const [],
    this.availableItems = const [],
    this.uomDescriptions = const {},
    this.loadingUoMDescription = false,
    this.loadingLocations = false,
    this.loadingLots = false,
    this.loadingToLocations = false,
    this.loadingItems = false,
    this.itemTransactionReportItems = const [],
    this.itemTransactionReportPage = 1,
    this.itemTransactionReportTotalPages = 0,
    this.itemTransactionReportTotalCount = 0,
    this.itemTransactionReportTotalCost = 0.0,
    this.hasMoreItemTransactionReport = false,
  });

  bool get hasError => error != null && error!.isNotEmpty;

  bool get hasSuccess => successmessage != null && successmessage!.isNotEmpty;

  bool get hastransactions => transactions.isNotEmpty;

  bool get hasFilteredTransactions => filteredTransactions.isNotEmpty;

  bool get hasSelectedItems => selectedItems.isNotEmpty;

  bool get hasSearchQuery => searchQuery != null && searchQuery!.isNotEmpty;

  bool get hasFilters => filters != null && filters!.isNotEmpty;

  bool get hasItemTransactionReport => itemTransactionReportItems.isNotEmpty;

  bool isExporting() => status == ItemTransactionsStatus.exporting;
  bool isLoading() => status == ItemTransactionsStatus.loading;
  bool isProcessing() => status == ItemTransactionsStatus.processing;
  bool isSaving() => status == ItemTransactionsStatus.saving;
  bool isSuccess() => status == ItemTransactionsStatus.success;
  bool isError() => status == ItemTransactionsStatus.error;
  bool isFailure() => status == ItemTransactionsStatus.failure;
  bool isDeleting() => status == ItemTransactionsStatus.deleting;
  bool isLoaded() => status == ItemTransactionsStatus.loaded;
  bool isInitial() => status == ItemTransactionsStatus.initial;
  bool isCreating() => status == ItemTransactionsStatus.creating;
  bool isUpdating() => status == ItemTransactionsStatus.updating;
  bool isDeletingMultiple() => status == ItemTransactionsStatus.deleting;

  ItemTransactionsState copyWith({
    ItemTransactionsStatus? status,
    List<ItemTransactionModel>? transactions,
    List<ItemTransactionModel>? filteredTransactions,
    List<ItemTransactionModel>? createItems,
    List<ItemTransactionModel>? editItems,
    List<ItemTransactionModel>? exportedTransactions,
    String? successmessage,
    String? error,
    List<ItemTransactionModel>? selectedItems,
    ItemTransactionModel? selected,
    ItemTransactionModel? selected1,
    ItemTransactionModel? selected2,
    ItemTransactionModel? editingItem,

    String? searchQuery,
    bool? isSelectionMode,
    Map<String, dynamic>? filters,
    double? totalQuantity,
    double? totalCost,
    double? openingAmount,
    bool? isDuplicate,
    int? companyId,
    //for daily stock report
    double? totlaAmount,
    double? openingQuantityBefore,
    double? openingQuantityBeforeToday,
    double? salesQtyOnDate,
    double? differenceSalesQty,

    //for balance stock item
    double? openingAmountBefore,
    double? openingAmountInitial,
    double? purchaseAmountOnDate,
    double? salesAmountOnDate,
    double? salesAmountOnThisDateCOS,
    double? grossProfitOnThisDate,
    double? amountEnding,

    List<ItemLocation>? availableLocations,
    List<LotMaster>? availableLots,
    List<ItemLocation>? availableToLocations,
    List<ItemInBranchModel>? availableItems,
    Map<int, String>? uomDescriptions,
    bool? loadingUoMDescription,
    bool? loadingLocations,
    bool? loadingLots,
    bool? loadingToLocations,
    bool? loadingItems,

    List<ItemTransactionModel>? itemTransactionReportItems,
    int? itemTransactionReportPage,
    int? itemTransactionReportTotalPages,
    int? itemTransactionReportTotalCount,
    double? itemTransactionReportTotalCost,
    bool? hasMoreItemTransactionReport,
  }) {
    return ItemTransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      exportedTransactions: exportedTransactions ?? this.exportedTransactions,
      successmessage: successmessage ?? this.successmessage,
      error: error ?? this.error,
      selectedItems: selectedItems ?? this.selectedItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      editingItem: editingItem ?? this.editingItem,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      filters: filters ?? this.filters,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalCost: totalCost ?? this.totalCost,
      openingAmount: openingAmount ?? this.openingAmount,
      totlaAmount: totlaAmount ?? this.totlaAmount,
      openingQuantityBefore:
          openingQuantityBefore ?? this.openingQuantityBefore,
      openingQuantityBeforeToday:
          openingQuantityBeforeToday ?? this.openingQuantityBeforeToday,
      salesQtyOnDate: salesQtyOnDate ?? this.salesQtyOnDate,
      differenceSalesQty: differenceSalesQty ?? this.differenceSalesQty,
      openingAmountBefore: openingAmountBefore ?? this.openingAmountBefore,
      openingAmountInitial: openingAmountInitial ?? this.openingAmountInitial,
      purchaseAmountOnDate: purchaseAmountOnDate ?? this.purchaseAmountOnDate,
      salesAmountOnDate: salesAmountOnDate ?? this.salesAmountOnDate,
      salesAmountOnThisDateCOS:
          salesAmountOnThisDateCOS ?? this.salesAmountOnThisDateCOS,
      grossProfitOnThisDate:
          grossProfitOnThisDate ?? this.grossProfitOnThisDate,
      amountEnding: amountEnding ?? this.amountEnding,
      companyId: companyId ?? this.companyId,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      availableLocations: availableLocations ?? this.availableLocations,
      availableLots: availableLots ?? this.availableLots,
      availableToLocations: availableToLocations ?? this.availableToLocations,
      availableItems: availableItems ?? this.availableItems,
      uomDescriptions: uomDescriptions ?? this.uomDescriptions,
      loadingUoMDescription:
          loadingUoMDescription ?? this.loadingUoMDescription,
      loadingLocations: loadingLocations ?? this.loadingLocations,
      loadingLots: loadingLots ?? this.loadingLots,
      loadingToLocations: loadingToLocations ?? this.loadingToLocations,
      loadingItems: loadingItems ?? this.loadingItems,
      itemTransactionReportItems:
          itemTransactionReportItems ?? this.itemTransactionReportItems,
      itemTransactionReportPage:
          itemTransactionReportPage ?? this.itemTransactionReportPage,
      itemTransactionReportTotalPages:
          itemTransactionReportTotalPages ??
          this.itemTransactionReportTotalPages,
      itemTransactionReportTotalCount:
          itemTransactionReportTotalCount ??
          this.itemTransactionReportTotalCount,
      itemTransactionReportTotalCost:
          itemTransactionReportTotalCost ?? this.itemTransactionReportTotalCost,
      hasMoreItemTransactionReport:
          hasMoreItemTransactionReport ?? this.hasMoreItemTransactionReport,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    filteredTransactions,
    successmessage,
    error,
    selectedItems,
    selected,
    selected1,
    selected2,
    editingItem,
    createItems,
    editItems,
    exportedTransactions,
    openingAmount,
    totlaAmount,
    openingQuantityBefore,
    openingQuantityBeforeToday,
    salesQtyOnDate,
    differenceSalesQty,
    openingAmountBefore,
    openingAmountInitial,
    purchaseAmountOnDate,
    salesAmountOnDate,
    salesAmountOnThisDateCOS,
    grossProfitOnThisDate,
    amountEnding,
    companyId,
    searchQuery,
    isSelectionMode,
    filters,
    totalQuantity,
    totalCost,
    availableLocations,
    availableLots,
    availableToLocations,
    availableItems,
    uomDescriptions,
    loadingUoMDescription,
    loadingLocations,
    loadingLots,
    loadingToLocations,
    loadingItems,
    itemTransactionReportItems,
    itemTransactionReportPage,
    itemTransactionReportTotalPages,
    itemTransactionReportTotalCount,
    itemTransactionReportTotalCost,
    hasMoreItemTransactionReport,
  ];
}
