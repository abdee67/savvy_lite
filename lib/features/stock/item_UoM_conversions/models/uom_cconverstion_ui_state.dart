// models/uom_conversion_ui_state.dart
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';

class UomConversionUiState {
  final List<ItemUomConversion> createItems;
  final List<ItemUomConversion> editItems;
  final ItemUomConversion? selected;
  final ItemUomConversion? selected1;
  final ItemUomConversion? selected2;
  final List<ItemUomConversion> multiSelectionItems;

  const UomConversionUiState({
    this.createItems = const [],
    this.editItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.multiSelectionItems = const [],
  });

  UomConversionUiState copyWith({
    List<ItemUomConversion>? createItems,
    List<ItemUomConversion>? editItems,
    ItemUomConversion? selected,
    ItemUomConversion? selected1,
    ItemUomConversion? selected2,
    List<ItemUomConversion>? multiSelectionItems,
  }) {
    return UomConversionUiState(
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
    );
  }
}
