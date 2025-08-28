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
  final ValueChanged<T>? onItemSelected;
  final double expandedHeight;
  final String emptyText;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color expandedBackgroundColor;
  final Color selectedColor;
  final bool showHeaderRow;

  const CustomTableDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.displayText,
    required this.columns,
    this.onItemSelected,
    this.expandedHeight = 200,
    this.emptyText = 'Select One',
    this.borderRadius,
    this.backgroundColor = const Color.fromARGB(220, 228, 228, 228),
    this.expandedBackgroundColor = const Color(0xFFFDD400),
    this.selectedColor = const Color(0xFF1C5380),
    this.showHeaderRow = true,
  });

  @override
  State<CustomTableDropdown<T>> createState() => _CustomTableDropdownState<T>();
}

class _CustomTableDropdownState<T> extends State<CustomTableDropdown<T>> {
  bool _isExpanded = false;
  T? _selectedItem;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectItem(T item) {
    setState(() {
      _selectedItem = item;
      _isExpanded = false;
    });
    widget.onItemSelected?.call(item);
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
      ),
      child: Row(
        children: widget.columns.map((column) {
          return Expanded(
            flex: column.flex.toInt(),
            child: Text(
              column.header,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
              textAlign: _getTextAlignment(column.alignment),
            ),
          );
        }).toList(),
      ),
    );
  }

  TextAlign _getTextAlignment(MainAxisAlignment alignment) {
    switch (alignment) {
      case MainAxisAlignment.start:
        return TextAlign.left;
      case MainAxisAlignment.center:
        return TextAlign.center;
      case MainAxisAlignment.end:
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Widget _buildTableRow(T item, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? widget.selectedColor : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: widget.columns.map((column) {
          return Expanded(
            flex: column.flex.toInt(),
            child: DefaultTextStyle(
              style: TextStyle(color: isSelected ? Colors.white : Colors.black),
              child: column.cellBuilder(item),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(50.0);

    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header/Trigger
          Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: borderRadius.topLeft,
                topRight: borderRadius.topRight,
                bottomLeft: _isExpanded ? Radius.zero : borderRadius.bottomLeft,
                bottomRight: _isExpanded
                    ? Radius.zero
                    : borderRadius.bottomRight,
              ),
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _selectedItem != null
                          ? widget.displayText(_selectedItem as T)
                          : widget.emptyText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  ),
                  onPressed: _toggleExpand,
                ),
              ],
            ),
          ),

          // Expanded Table Content
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: widget.expandedBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
                border: const Border(
                  left: BorderSide(color: Colors.black, width: 1.0),
                  right: BorderSide(color: Colors.black, width: 1.0),
                  bottom: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
              height: widget.expandedHeight,
              child: Column(
                children: [
                  // Table Header
                  if (widget.showHeaderRow && widget.columns.isNotEmpty)
                    _buildTableHeader(),

                  // Table Rows
                  Expanded(
                    child: widget.items.isEmpty
                        ? Center(
                            child: Text(
                              'No items available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.0,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: widget.items.map((item) {
                                final bool isSelected = _selectedItem == item;
                                return InkWell(
                                  onTap: () => _selectItem(item),
                                  child: _buildTableRow(item, isSelected),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
