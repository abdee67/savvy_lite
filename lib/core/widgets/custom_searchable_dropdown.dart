import 'package:flutter/material.dart';

class CustomSearchableDropdown extends StatefulWidget {
  final String labelText;
  final List<String> options;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final bool enabled;
  final bool allowCustomEntries;

  const CustomSearchableDropdown({
    super.key,
    required this.labelText,
    required this.options,
    this.value,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
    this.allowCustomEntries = true,
  });

  @override
  State<CustomSearchableDropdown> createState() =>
      _CustomSearchableDropdownState();
}

class _CustomSearchableDropdownState extends State<CustomSearchableDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _filteredOptions = [];
  bool _isCustomEntry = false;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _controller.text = widget.value ?? '';
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant CustomSearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value ?? '';
    }
    if (oldWidget.options != widget.options) {
      _filteredOptions = widget.options;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
      // When losing focus, submit the current text as a custom entry if allowed
      if (widget.allowCustomEntries &&
          _controller.text.isNotEmpty &&
          !widget.options.contains(_controller.text)) {
        _handleCustomEntry(_controller.text);
      }
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            child: Container(
              constraints: BoxConstraints(maxHeight: 200, maxWidth: size.width),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: _buildOptionsList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOptionsList() {
    final hasExactMatch = _filteredOptions.any(
      (option) => option.toLowerCase() == _controller.text.toLowerCase(),
    );
    final showCustomOption =
        widget.allowCustomEntries &&
        _controller.text.isNotEmpty &&
        !hasExactMatch;

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        if (_filteredOptions.isEmpty && _controller.text.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No options available',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else if (_filteredOptions.isEmpty && _controller.text.isNotEmpty)
          _buildCustomEntryOption()
        else
          ..._buildFilteredOptions(showCustomOption),
      ],
    );
  }

  List<Widget> _buildFilteredOptions(bool showCustomOption) {
    final widgets = <Widget>[];

    // Add filtered options
    for (final option in _filteredOptions) {
      widgets.add(
        ListTile(
          title: Text(option),
          trailing: option == _controller.text
              ? const Icon(Icons.check, color: Colors.green, size: 16)
              : null,
          onTap: () => _selectOption(option),
        ),
      );
    }

    // Add custom entry option if needed
    if (showCustomOption) {
      widgets.add(const Divider(height: 1));
      widgets.add(_buildCustomEntryOption());
    }

    return widgets;
  }

  Widget _buildCustomEntryOption() {
    return ListTile(
      leading: const Icon(Icons.add, color: Colors.blue, size: 20),
      title: Text(
        'Add "${_controller.text}"',
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
      ),
      subtitle: const Text(
        'Create new entry',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () => _handleCustomEntry(_controller.text),
    );
  }

  void _selectOption(String option) {
    _controller.text = option;
    _isCustomEntry = false;
    widget.onChanged?.call(option);
    _focusNode.unfocus();
    _removeOverlay();
  }

  void _handleCustomEntry(String customValue) {
    _isCustomEntry = true;
    widget.onChanged?.call(customValue);
    _focusNode.unfocus();
    _removeOverlay();

    // Show a subtle feedback that custom entry was created
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added: $customValue'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where(
              (option) => option.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });

    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _clearSelection() {
    _controller.clear();
    _isCustomEntry = false;
    widget.onChanged?.call(null);
    _filterOptions('');
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: _controller.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCustomEntry)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.edit, color: Colors.blue, size: 16),
                      ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSelection,
                    ),
                  ],
                )
              : null,
          hintText: 'Type or select from list...',
        ),
        onChanged: (value) {
          _filterOptions(value);
          // For immediate feedback while typing (optional)
          if (widget.allowCustomEntries && value.isNotEmpty) {
            widget.onChanged?.call(value);
          }
        },
        onFieldSubmitted: (value) {
          if (widget.allowCustomEntries && value.isNotEmpty) {
            _handleCustomEntry(value);
          }
        },
        validator: widget.validator,
      ),
    );
  }
}
