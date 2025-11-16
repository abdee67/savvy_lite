import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

@immutable
abstract class ItemEntryEvent extends Equatable {
  const ItemEntryEvent();

  @override
  List<Object> get props => [];
}

class ToggleBarcode extends ItemEntryEvent {
  final bool useBarcode;

  const ToggleBarcode({required this.useBarcode});

  @override
  List<Object> get props => [useBarcode];
}

class AddBarcodeItems extends ItemEntryEvent {
  final List<ConfirmedItem> items;

  const AddBarcodeItems({required this.items});

  @override
  List<Object> get props => [items];
}

class ScanBarcode extends ItemEntryEvent {
  final String barcode;

  const ScanBarcode({required this.barcode});

  @override
  List<Object> get props => [barcode];
}
