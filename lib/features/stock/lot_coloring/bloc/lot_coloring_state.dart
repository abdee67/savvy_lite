import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';

enum LotExpirationColorsStatus {
  initial,
  loading,
  loaded,
  saving,
  recalculating,
  deleting,
  success,
  failure,
}

class LotExpirationColorsState extends Equatable {
  final LotExpirationColorsStatus status;
  final List<LotExpirationColor> items;
  final List<LotExpirationColor> filteredItems;
  final String? message;
  final LotExpirationColor? calculatedColor;
  final bool? areRangesValid;
  final List<LotExpirationColor> selectedItems;
  final String? searchQuery;
  final bool isSelectionMode;

  const LotExpirationColorsState({
    this.status = LotExpirationColorsStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.message,
    this.calculatedColor,
    this.areRangesValid,
    this.selectedItems = const [],
    this.searchQuery,
    this.isSelectionMode = false,
  });

  @override
  List<Object?> get props => [
    status,
    items,
    filteredItems,
    message,
    calculatedColor,
    areRangesValid,
    selectedItems,
    searchQuery,
    isSelectionMode,
  ];

  bool get canEdit => selectedItems.isNotEmpty;

  bool get canDelete => selectedItems.isNotEmpty;

  LotExpirationColorsState copyWith({
    LotExpirationColorsStatus? status,
    List<LotExpirationColor>? items,
    List<LotExpirationColor>? filteredItems,
    String? message,
    LotExpirationColor? calculatedColor,
    bool? areRangesValid,
    List<LotExpirationColor>? selectedItems,
    String? searchQuery,
    bool? isSelectionMode,
  }) {
    return LotExpirationColorsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      message: message ?? this.message,
      calculatedColor: calculatedColor ?? this.calculatedColor,
      areRangesValid: areRangesValid ?? this.areRangesValid,
      selectedItems: selectedItems ?? this.selectedItems,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }
}
