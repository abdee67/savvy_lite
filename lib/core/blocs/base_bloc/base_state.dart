/*import 'package:equatable/equatable.dart';

enum BaseStatus { initial, loading, success, failure, searching }

class BaseState<T> extends Equatable {
  final BaseStatus status;
  final List<T> data;
  final List<T> filteredData;
  final List<T> selectedData;
  final String searchQuery;
  final T? detailItem;
  final bool showDetailPanel;
  final String? errorMessage;

  const BaseState({
    this.status = BaseStatus.initial,
    this.data = const [],
    this.filteredData = const [],
    this.selectedData = const [],
    this.searchQuery = '',
    this.detailItem,
    this.showDetailPanel = false,
    this.errorMessage,
  });

  BaseState<T> copyWith({
    BaseStatus? status,
    List<T>? data,
    List<T>? filteredData,
    List<T>? selectedData,
    String? searchQuery,
    T? detailItem,
    bool? showDetailPanel,
    String? errorMessage,
  }) {
    return BaseState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      filteredData: filteredData ?? this.filteredData,
      selectedData: selectedData ?? this.selectedData,
      searchQuery: searchQuery ?? this.searchQuery,
      detailItem: detailItem ?? this.detailItem,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isSelectionMode => selectedData.isNotEmpty;
  bool get canEdit => selectedData.length == 1;
  bool get canDelete => selectedData.isNotEmpty;

  @override
  List<Object?> get props => [
        status,
        data,
        filteredData,
        selectedData,
        searchQuery,
        detailItem,
        showDetailPanel,
        errorMessage,
      ];
}
*/
