import 'package:flutter/material.dart';

class TableColumnConfig<T> {
  final String header;
  final double flex;
  final Widget Function(T item) cellBuilder;
  final MainAxisAlignment alignment;

  const TableColumnConfig({
    required this.header,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = MainAxisAlignment.spaceBetween,
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
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color expandedBackgroundColor;
  final Color selectedColor;
  final bool showHeaderRow;
  final T? selectedValue;

  const CustomTableDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.displayText,
    required this.columns,
    required this.onItemSelected,
    this.expandedHeight = 200,
    this.emptyText = 'Select One',
    this.borderRadius,
    this.backgroundColor = const Color(0xFFEDEDED),
    this.expandedBackgroundColor = const Color(0xFFFDD105),
    this.selectedColor = const Color(0xFF145888),
    this.showHeaderRow = true,
    this.selectedValue,
  });

  @override
  State<CustomTableDropdown<T>> createState() => _CustomTableDropdownState<T>();
}

class _CustomTableDropdownState<T> extends State<CustomTableDropdown<T>>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  T? _selectedItem;

  // Animation controllers for smooth expansion
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
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
      }
    });
  }

  void _selectItem(T item) {
    setState(() {
      _selectedItem = item;
      _isExpanded = false;
      _animationController.reverse();
      widget.onItemSelected(item);
    });
  }

  // Helper method to extract phone number from item
  String _getPhoneNumber(T item) {
    if (widget.columns.length > 2) {
      final phoneWidget = widget.columns[2].cellBuilder(item);
      if (phoneWidget is Text) {
        return phoneWidget.data ?? '0923505050';
      }
    }
    return '0923505050';
  }

  String _getTin(T item) {
    if (widget.columns.length > 1) {
      final tinWidget = widget.columns[1].cellBuilder(item);
      if (tinWidget is Text) {
        return tinWidget.data ?? '0923505050';
      }
    }
    return '0923505050';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.only(
                top: 10,
                left: 27,
                right: 12,
                bottom: 10,
              ),
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
                  Text(
                    widget.selectedValue != null
                        ? widget.displayText(widget.selectedValue as T)
                        : widget.emptyText,
                    style: const TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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

          // Expanded Content - Only show when expanded OR during collapse animation
          if (_isExpanded || _animationController.isAnimating)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final currentHeight =
                    _heightAnimation.value * widget.expandedHeight;
                final currentOpacity = _opacityAnimation.value;

                // Don't render if height is effectively zero
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Row (Name and Phone)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1C1C1C))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name Header
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                //TIN
                Expanded(
                  flex: 2,
                  child: Text(
                    'TIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Phone Header
                Expanded(
                  flex: 2,
                  child: Text(
                    'Phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Items List
          Expanded(
            child: widget.items.isEmpty
                ? Center(
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
                          'No items available',
                          style: TextStyle(
                            color: const Color(0xFF887F7F),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: widget.items.map((item) {
                        final bool isSelected =
                            _selectedItem == item ||
                            (widget.selectedValue != null &&
                                item == widget.selectedValue);

                        return _buildItemCard(item, isSelected);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(T item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? widget.selectedColor : Colors.transparent,
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
              children: [
                // Customer Name
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.displayText(item),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    _getTin(item),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Phone Number
                Expanded(
                  flex: 2,
                  child: Text(
                    _getPhoneNumber(item),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
