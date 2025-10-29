import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';

abstract class LotExpirationColorsEvent extends Equatable {
  const LotExpirationColorsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLotExpirationColors extends LotExpirationColorsEvent {
  final int companyId;

  const LoadLotExpirationColors(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class SaveLotExpirationColors extends LotExpirationColorsEvent {
  final LotExpirationColor color;

  const SaveLotExpirationColors(this.color);

  @override
  List<Object?> get props => [color];
}

class UpdateLotExpirationColors extends LotExpirationColorsEvent {
  final LotExpirationColor color;

  const UpdateLotExpirationColors(this.color);

  @override
  List<Object?> get props => [color];
}

class DeleteLotExpirationColors extends LotExpirationColorsEvent {
  final LotExpirationColor color;

  const DeleteLotExpirationColors(this.color);

  @override
  List<Object?> get props => [color];
}

class DeleteMultipleLotExpirationColors extends LotExpirationColorsEvent {
  final List<LotExpirationColor> colors;

  const DeleteMultipleLotExpirationColors(this.colors);

  @override
  List<Object?> get props => [colors];
}

class FilterLotExpirationColors extends LotExpirationColorsEvent {
  final String? level;
  final int? branchId;
  final int? itemId;

  const FilterLotExpirationColors({this.level, this.branchId, this.itemId});

  @override
  List<Object?> get props => [level, branchId, itemId];
}

class CalculateLotExpirationColor extends LotExpirationColorsEvent {
  final int? branch;
  final int? item;
  final DateTime? expirationDate;
  final DateTime? effectiveDate;
  final DateTime? receivedDate;
  final String? lotType;

  const CalculateLotExpirationColor({
    this.branch,
    this.item,
    this.expirationDate,
    this.effectiveDate,
    this.receivedDate,
    this.lotType,
  });

  @override
  List<Object?> get props => [
    branch,
    item,
    expirationDate,
    effectiveDate,
    receivedDate,
    lotType,
  ];
}

class RecalculateAllColor extends LotExpirationColorsEvent {
  const RecalculateAllColor();

  @override
  List<Object?> get props => [];
}

class ValidateLotExpirationRanges extends LotExpirationColorsEvent {
  final List<LotExpirationColor> colors;

  const ValidateLotExpirationRanges(this.colors);

  @override
  List<Object?> get props => [colors];
}

class SelectLotExpirationColor extends LotExpirationColorsEvent {
  final LotExpirationColor color;
  final bool selected;

  const SelectLotExpirationColor(this.color, this.selected);

  @override
  List<Object?> get props => [color, selected];
}

class SelectMultipleLotExpirationColors extends LotExpirationColorsEvent {
  final List<LotExpirationColor> colors;
  final bool selected;

  const SelectMultipleLotExpirationColors(this.colors, this.selected);

  @override
  List<Object?> get props => [colors, selected];
}

class SearchLotExpirationColors extends LotExpirationColorsEvent {
  final String query;

  const SearchLotExpirationColors(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSelection extends LotExpirationColorsEvent {
  const ClearSelection();

  @override
  List<Object?> get props => [];
}
