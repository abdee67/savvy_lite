import 'package:flutter/material.dart';

class TableColumnConfig<T> {
  final String header;
  final double flex;
  final Widget Function(T item) cellBuilder;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAxisAlignment;

  const TableColumnConfig({
    required this.header,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });
}

class CustomTableDropdown<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) displayText;
  final List<TableColumnConfig<T>> columns;
  final ValueChanged<T?> onItemSelected;
  final double expandedHeight;
  final String emptyText;
  final String noItemsText;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color expandedBackgroundColor;
  final Color selectedColor;
  final Color textColor;
  final Color selectedTextColor;
  final bool showHeaderRow;
  final T? selectedValue;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final TextStyle? textStyle;
  final TextStyle? headerTextStyle;
  final bool showSearch;
  final String? searchHint;
  final bool showSelectedItemInHeader;
  final Color Function(T item, bool isSelected)? rowBackgroundColor;

  const CustomTableDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.displayText,
    required this.columns,
    required this.onItemSelected,
    this.expandedHeight = 200,
    this.emptyText = 'Select One',
    this.noItemsText = 'No items available',
    this.borderRadius,
    this.backgroundColor = const Color(0xFFEDEDED),
    this.expandedBackgroundColor = const Color(0xFFFDD105),
    this.selectedColor = Colors.transparent,
    this.textColor = Colors.white,
    this.selectedTextColor = Colors.white,
    this.showHeaderRow = true,
    this.selectedValue,
    this.leadingIcon,
    this.trailingIcon,
    this.textStyle,
    this.headerTextStyle,
    this.showSearch = false,
    this.searchHint,
    this.showSelectedItemInHeader = true,
    this.rowBackgroundColor,
  });

  @override
  State<CustomTableDropdown<T>> createState() => _CustomTableDropdownState<T>();
}

class _CustomTableDropdownState<T> extends State<CustomTableDropdown<T>>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  T? _selectedItem;
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _selectedItem = widget.selectedValue;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward(from: 0.0);
      } else {
        _animationController.reverse();
        _searchController.clear();
        _filteredItems = widget.items;
      }
    });
  }

  void _selectItem(T item) {
    setState(() {
      _selectedItem = item;
      _isExpanded = false;
      _animationController.reverse();
      _searchController.clear();
      _filteredItems = widget.items;
      widget.onItemSelected(item);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final displayText = widget.displayText(item).toLowerCase();
          return displayText.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomTableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
    }
    if (oldWidget.selectedValue != widget.selectedValue) {
      _selectedItem = widget.selectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(20.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Field
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              width: cardWidth,
              height: 39,
              padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 10),
              decoration: ShapeDecoration(
                color: widget.backgroundColor,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFF1C1C1C)),
                  borderRadius: _isExpanded
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )
                      : borderRadius,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.leadingIcon != null) ...[
                          widget.leadingIcon!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            _selectedItem != null &&
                                    widget.showSelectedItemInHeader
                                ? widget.displayText(_selectedItem as T)
                                : widget.emptyText,
                            style:
                                widget.textStyle ??
                                const TextStyle(
                                  color: Color(0xFF373737),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    widget.trailingIcon!,
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF1C1C1C),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded || _animationController.isAnimating)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final currentHeight =
                    _heightAnimation.value * widget.expandedHeight;
                final currentOpacity = _opacityAnimation.value;

                if (currentHeight < 1.0) {
                  return const SizedBox.shrink();
                }

                return Container(
                  width: cardWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    color: widget.expandedBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: const Color(0xFF1C1C1C),
                      width: 1,
                    ),
                  ),
                  child: Opacity(
                    opacity: currentOpacity,
                    child: _isExpanded ? _buildExpandedContent() : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          if (widget.showSearch) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Search...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Header Row
          if (widget.showHeaderRow && widget.columns.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1C1C1C))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: widget.columns.map((column) {
                  return Expanded(
                    flex: column.flex.round(),
                    child: Text(
                      column.header,
                      textAlign: TextAlign.center,
                      style:
                          widget.headerTextStyle ??
                          const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Items List
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final bool isSelected =
                          _selectedItem == item ||
                          (widget.selectedValue != null &&
                              item == widget.selectedValue);

                      return _buildItemCard(item, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Color(0xFF887F7F),
          ),
          const SizedBox(height: 8),
          Text(
            widget.noItemsText,
            style: const TextStyle(
              color: Color(0xFF887F7F),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(T item, bool isSelected) {
    Color? rowColor = widget.rowBackgroundColor?.call(item, isSelected);

    // If rowColor is provided and not transparent, use it.
    // Otherwise, if selected, use selectedColor.
    final backgroundColor = (rowColor != null && rowColor != Colors.transparent)
        ? rowColor
        : (isSelected ? widget.selectedColor : Colors.transparent);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectItem(item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.columns.map((column) {
                return Expanded(
                  flex: column.flex.round(),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: column.cellBuilder(item),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
