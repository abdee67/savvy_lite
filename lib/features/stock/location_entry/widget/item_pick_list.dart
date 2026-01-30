// features/stock/location_master/widgets/items_pick_list.dart
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

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
      final desc = item.itemRef?.itemDescription?.toLowerCase() ?? '';
      final code = item.itemRef?.itemsId?.toLowerCase() ?? '';
      return desc.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Available items section - use Flexible to shared space
        Expanded(flex: 3, child: _buildAvailableItemsSection()),
        // Show assigned items section in edit mode
        if (widget.isEditMode && widget.targetItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Flexible(flex: 2, child: _buildAssignedItemsSection()),
        ],
      ],
    );
  }

  Widget _buildAssignedItemsSection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Iconsax.lock, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Assigned Items (${widget.targetItems.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.targetItems.length,
              itemBuilder: (context, index) {
                final item = widget.targetItems[index];
                return _buildItemCard(item, isAssigned: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableItemsSection() {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Items (${_filteredItems.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1C4292),
                      ),
                    ),
                    if (_selectedItems.isNotEmpty)
                      Text(
                        '${_selectedItems.length} selected',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = _selectedItems.contains(item);
                          return _buildItemCard(
                            item,
                            isSelected: isSelected,
                            onTap: () => _handleItemSelection(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_selectedItems.isNotEmpty) _buildActionArea(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    ItemInBranchModel item, {
    bool isSelected = false,
    bool isAssigned = false,
    VoidCallback? onTap,
  }) {
    final description = item.itemRef?.itemDescription ?? 'Unknown Item';
    final itemId = item.itemRef?.itemsId ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1C4292).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1C4292)
                : isAssigned
                ? Colors.grey[200]!
                : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1C4292).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1C4292)
                    : isAssigned
                    ? Colors.grey[100]
                    : const Color(0xFF1C4292).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAssigned
                    ? Iconsax.lock
                    : isSelected
                    ? Iconsax.tick_circle
                    : Iconsax.box,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : isAssigned
                    ? Colors.grey
                    : const Color(0xFF1C4292),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isAssigned ? Colors.grey : const Color(0xFF333333),
                    ),
                  ),
                  if (itemId.isNotEmpty)
                    Text(
                      'ID: $itemId',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            if (!isAssigned)
              Icon(
                isSelected ? Iconsax.minus_cirlce : Iconsax.add_circle,
                color: isSelected ? Colors.red[400] : const Color(0xFF1C4292),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_search, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No matches found'
                  : 'No items available',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => _selectedItems.clear()),
              child: const Text('Clear', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _assignSelectedItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C4292),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Assign ${_selectedItems.length} Items',
                style: const TextStyle(fontWeight: FontWeight.bold),
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

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assigned ${_selectedItems.length} items successfully'),
        backgroundColor: const Color(0xFF1C4292),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Clear selection after assignment
    setState(() {
      _selectedItems.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
