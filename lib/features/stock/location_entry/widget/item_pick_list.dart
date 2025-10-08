// features/stock/location_master/widgets/items_pick_list.dart
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class ItemsPickList extends StatefulWidget {
  final List<ItemInBranchModel> sourceItems;
  final List<ItemInBranchModel> targetItems;
  final Function(List<ItemInBranchModel> source, List<ItemInBranchModel> target)
  onSelectionChanged;

  const ItemsPickList({
    super.key,
    required this.sourceItems,
    required this.targetItems,
    required this.onSelectionChanged,
  });

  @override
  State<ItemsPickList> createState() => _ItemsPickListState();
}

class _ItemsPickListState extends State<ItemsPickList> {
  final List<ItemInBranchModel> _selectedSource = [];
  final List<ItemInBranchModel> _selectedTarget = [];
  final TextEditingController _sourceFilterController = TextEditingController();
  final TextEditingController _targetFilterController = TextEditingController();

  List<ItemInBranchModel> get _filteredSource {
    if (_sourceFilterController.text.isEmpty) {
      return widget.sourceItems;
    }
    return widget.sourceItems.where((item) {
      return item.branchrefrence?.description?.toLowerCase().contains(
            _sourceFilterController.text.toLowerCase(),
          ) ??
          false;
    }).toList();
  }

  List<ItemInBranchModel> get _filteredTarget {
    if (_targetFilterController.text.isEmpty) {
      return widget.targetItems;
    }
    return widget.targetItems.where((item) {
      return item.branchrefrence?.description?.toLowerCase().contains(
            _targetFilterController.text.toLowerCase(),
          ) ??
          false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Source List
        Expanded(
          child: _buildListSection(
            title: 'Available Items',
            items: _filteredSource,
            selectedItems: _selectedSource,
            filterController: _sourceFilterController,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedSource.clear();
                _selectedSource.addAll(selected);
              });
            },
          ),
        ),

        // Transfer Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _selectedSource.isNotEmpty ? _moveToTarget : null,
                child: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedTarget.isNotEmpty ? _moveToSource : null,
                child: const Icon(Icons.arrow_back),
              ),
            ],
          ),
        ),

        // Target List
        Expanded(
          child: _buildListSection(
            title: 'Assigned Items',
            items: _filteredTarget,
            selectedItems: _selectedTarget,
            filterController: _targetFilterController,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedTarget.clear();
                _selectedTarget.addAll(selected);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required String title,
    required List<ItemInBranchModel> items,
    required List<ItemInBranchModel> selectedItems,
    required TextEditingController filterController,
    required Function(List<ItemInBranchModel>) onSelectionChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: filterController,
            decoration: const InputDecoration(
              hintText: 'Filter...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItems.contains(item);
                  final isDisabled = _isItemDisabled(item);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: isDisabled
                        ? null
                        : (value) {
                            final newSelection = List<ItemInBranchModel>.from(
                              selectedItems,
                            );
                            if (value == true) {
                              newSelection.add(item);
                            } else {
                              newSelection.remove(item);
                            }
                            onSelectionChanged(newSelection);
                          },
                    title: Text(
                      item.branchrefrence?.description ?? 'Unknown Item',
                      style: TextStyle(color: isDisabled ? Colors.grey : null),
                    ),
                    secondary: isDisabled
                        ? const Icon(Icons.lock, color: Colors.grey, size: 16)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isItemDisabled(ItemInBranchModel item) {
    // This would check if the item is already assigned to this location
    // For now, return false - you'd implement the actual check
    return false;
  }

  void _moveToTarget() {
    final newSource = List<ItemInBranchModel>.from(widget.sourceItems);
    final newTarget = List<ItemInBranchModel>.from(widget.targetItems);

    for (final item in _selectedSource) {
      if (newSource.contains(item)) {
        newSource.remove(item);
        newTarget.add(item);
      }
    }

    _selectedSource.clear();
    widget.onSelectionChanged(newSource, newTarget);
  }

  void _moveToSource() {
    final newSource = List<ItemInBranchModel>.from(widget.sourceItems);
    final newTarget = List<ItemInBranchModel>.from(widget.targetItems);

    for (final item in _selectedTarget) {
      if (newTarget.contains(item)) {
        newTarget.remove(item);
        newSource.add(item);
      }
    }

    _selectedTarget.clear();
    widget.onSelectionChanged(newSource, newTarget);
  }

  @override
  void dispose() {
    _sourceFilterController.dispose();
    _targetFilterController.dispose();
    super.dispose();
  }
}
