
// bloc/item_cost_state.dart

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';

@immutable
abstract class ItemCostState {
  final List<ItemCost> items;
  final List<ItemCost> createItems;
  final List<ItemCost> editItems;
  final List<ItemCost> multiselectionItems;
  final List<ItemCost> filteredValues;
  final ItemCost? selected;
  final ItemCost? selected1;
  final ItemCost? selected2;
  final String? errorMessage;
  final String? successMessage;
  final bool isLoading;

  const ItemCostState({
    this.items = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiselectionItems = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.errorMessage,
    this.successMessage,
    this.isLoading = false,
  });

  ItemCostState copyWith({
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  });
}

class ItemCostInitial extends ItemCostState {
  const ItemCostInitial() : super();
  
  @override
  ItemCostInitial copyWith({
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return ItemCostInitial();
  }
}

class ItemCostLoading extends ItemCostState {
  const ItemCostLoading({
    super.items,
    super.createItems,
    super.editItems,
    super.multiselectionItems,
    super.filteredValues,
    super.selected,
    super.selected1,
    super.selected2,
    super.isLoading = true,
  });

  @override
  ItemCostLoading copyWith({
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return ItemCostLoading(
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ItemCostLoaded extends ItemCostState {
  const ItemCostLoaded({
    required super.items,
    super.createItems,
    super.editItems,
    super.multiselectionItems,
    super.filteredValues,
    super.selected,
    super.selected1,
    super.selected2,
    super.successMessage,
    super.isLoading = false,
  });

  @override
  ItemCostLoaded copyWith({
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return ItemCostLoaded(
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class ItemCostError extends ItemCostState {
  const ItemCostError({
    super.items,
    super.createItems,
    super.editItems,
    super.multiselectionItems,
    super.filteredValues,
    super.selected,
    super.selected1,
    super.selected2,
    required super.errorMessage,
    super.isLoading = false,
  });

  @override
  ItemCostError copyWith({
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return ItemCostError(
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ItemCostOperationSuccess extends ItemCostState {
  const ItemCostOperationSuccess({
    required super.items,
    super.createItems,
    super.editItems,
    super.multiselectionItems,
    super.filteredValues,
    super.selected,
    super.selected1,
    super.selected2,
    required super.successMessage,
    super.isLoading = false,
  });

  @override
  ItemCostOperationSuccess copyWith({
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return ItemCostOperationSuccess(
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}