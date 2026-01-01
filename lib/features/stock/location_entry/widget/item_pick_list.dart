// features/stock/location_master/widgets/items_pick_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

import '../../item_entry/blocs/item_entry_bloc.dart';
import '../../item_entry/blocs/item_entry_event.dart';
import '../../item_entry/blocs/item_entry_state.dart';

class ItemsPickList extends StatefulWidget {
  final List<ItemInBranchModel> sourceItems;
  final List<ItemInBranchModel> targetItems;
  final AuthBloc authBloc;
  final Function(List<ItemInBranchModel> source, List<ItemInBranchModel> target)
  onSelectionChanged;
  final bool isEditMode;

  const ItemsPickList({
    super.key,
    required this.sourceItems,
    required this.targetItems,
    required this.authBloc,
    required this.onSelectionChanged,
    this.isEditMode = false,
  });

  @override
  State<ItemsPickList> createState() => _ItemsPickListState();
}

class _ItemsPickListState extends State<ItemsPickList> {
  final List<ItemInBranchModel> _selectedItems = [];
  final TextEditingController _searchController = TextEditingController();

  List<ItemInBranchModel> get _filteredItems {
    if (_searchController.text.isEmpty) {
      return widget.sourceItems;
    }
    final query = _searchController.text.toLowerCase();
    return widget.sourceItems.where((item) {
      return item.branchRef?.description?.toLowerCase().contains(query) ??
          false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Available items section - FIXED: Use Expanded for proper constraints
        Flexible(child: _buildAvailableItemsSection(theme, colors)),
        const SizedBox(height: 10),
        // Show assigned items section in edit mode
        if (widget.isEditMode && widget.targetItems.isNotEmpty) ...[
          Flexible(child: _buildAssignedItemsSection(theme, colors)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildAssignedItemsSection(ThemeData theme, ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Assigned Items (Read-only)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.targetItems.length} items',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Assigned Items List - FIXED: Use ConstrainedBox with minHeight
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60, maxHeight: 200),
            child: widget.targetItems.isEmpty
                ? _buildEmptyAssignedState(theme, colors)
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: widget.targetItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.targetItems[index];
                      return _buildAssignedItemListItem(
                        item: item,
                        theme: theme,
                        colors: colors,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssignedState(ThemeData theme, ColorScheme colors) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No items assigned yet',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAssignedItemListItem({
    required ItemInBranchModel item,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final description = item.item?.itemDescription ?? 'No Description';
    final itemNumber = item.itemNumber.toString() ?? 'N/A';
    final itemCode = item.item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 20,
            color: Colors.grey.shade600,
          ),
        ),
        title: Text(
          description,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item #$itemNumber',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            if (itemCode != null)
              Text(
                'Code: $itemCode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.lock, color: Colors.grey.shade500, size: 20),
      ),
    );
  }

  Widget _buildAvailableItemsSection(ThemeData theme, ColorScheme colors) {
    // FIXED: Remove the Column and use a Container with proper constraints
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selection Header
        _buildSelectionHeader(theme, colors),
        const SizedBox(height: 16),

        // Search Bar
        _buildSearchBar(colors),
        const SizedBox(height: 16),

        // Items List Section - FIXED: Use Expanded for scrollable content
        Flexible(fit: FlexFit.tight, child: _buildItemsSection(theme, colors)),

        // Action Buttons - FIXED: Use SizedBox with fixed height
        SizedBox(height: 70, child: _buildActionButtons(colors)),
      ],
    );
  }

  Widget _buildSelectionHeader(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            widget.isEditMode
                ? Icons.add_circle_outline
                : Icons.inventory_2_outlined,
            size: 20,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditMode ? 'Add More Items' : 'Available Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.sourceItems.length} items available • ${_selectedItems.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedItems.isNotEmpty)
            Badge(
              label: Text(_selectedItems.length.toString()),
              backgroundColor: colors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colors) {
    return CustomTextField(
      controller: _searchController,
      labelText: 'Search items by description...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
          : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildItemsSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isEditMode
                    ? Icons.add_box_outlined
                    : Icons.checklist_outlined,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isEditMode
                    ? 'Select Additional Items'
                    : 'Select Items for Assignment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              if (_selectedItems.isNotEmpty)
                Text(
                  '${_selectedItems.length} selected',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),

        // Items List - FIXED: Use Expanded for proper scrolling
        Flexible(
          child: _filteredItems.isEmpty
              ? _buildEmptyState(theme, colors)
              : _buildItemsList(theme, colors),
        ),
      ],
    );
  }

  Widget _buildItemsList(ThemeData theme, ColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = _selectedItems.contains(item);

        return _buildItemListItem(
          item: item,
          isSelected: isSelected,
          onTap: () => _handleItemSelection(item),
          theme: theme,
          colors: colors,
        );
      },
    );
  }

  String _getItemDescription(int? itemId) {
    if (itemId == null) return '';
    // load item descriptions from item_entry bloc
    final itemEntryBloc = context.read<StockItemsEntryBloc>();
    itemEntryBloc.add(LoadItems(widget.authBloc.state.companyId!));

    final itemEntryState = itemEntryBloc.state;
    if (itemEntryState.status == ItemEntryStatus.success) {
      final item = itemEntryState.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => ItemEntryModel.empty(),
      );
      return item.itemDescription ?? 'Item $itemId';
    }

    return 'Item $itemId';
  }

  Widget _buildItemListItem({
    required ItemInBranchModel item,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final description = _getItemDescription(item.itemNumber);
    final itemNumber = item.itemNumber.toString();
    final itemCode = item.item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? colors.primary : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? Icons.check_circle : Icons.inventory_2_outlined,
            size: 20,
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
          ),
        ),
        title: Text(
          item.itemRef!.itemDescription!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? colors.primary : colors.onSurface,
          ),
        ),
        trailing: Icon(
          isSelected ? Icons.remove_circle : Icons.add_circle,
          color: isSelected ? colors.error : colors.primary,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    final hasSourceItems = widget.sourceItems.isNotEmpty;
    final hasSearchQuery = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchQuery
                  ? Icons.search_off_outlined
                  : Icons.inventory_2_outlined,
              size: 30,
              color: colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearchQuery ? 'No items found' : 'No available items',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchQuery
                  ? 'Try adjusting your search terms'
                  : widget.isEditMode
                  ? 'All additional items have been assigned.'
                  : 'All items have been assigned or there are no items to assign.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.isEditMode && widget.targetItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.targetItems.length} items already assigned to this location',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _selectedItems.isNotEmpty
                  ? () {
                      setState(() {
                        _selectedItems.clear();
                      });
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Selection'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _selectedItems.isNotEmpty
                  ? _assignSelectedItems
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isEditMode
                        ? Icons.add_task_outlined
                        : Icons.assignment_turned_in_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.isEditMode ? 'Add Items' : 'Assign Selected'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemSelection(ItemInBranchModel item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _assignSelectedItems() {
    final newSource = List<ItemInBranchModel>.from(widget.sourceItems)
      ..removeWhere((item) => _selectedItems.contains(item));

    final newTarget = List<ItemInBranchModel>.from(widget.targetItems)
      ..addAll(_selectedItems);

    widget.onSelectionChanged(newSource, newTarget);

    // Clear selection after assignment
    setState(() {
      _selectedItems.clear();
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditMode
              ? 'Successfully added ${_selectedItems.length} items'
              : 'Successfully assigned ${_selectedItems.length} items',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
