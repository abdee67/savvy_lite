/** 
class CustomerDropdown extends StatefulWidget {
  final Customer? value;
  final List<Customer> customers;
  final ValueChanged<Customer?> onChanged;

  const CustomerDropdown({
    super.key,
    required this.value,
    required this.customers,
    required this.onChanged,
  });

  @override
  State<CustomerDropdown> createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<CustomerDropdown> {
  bool _isExpanded = false;
  String _selectedCustomer = '';

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.value?.name ?? '';
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer.name;
      _isExpanded = false;
    });
    widget.onChanged(customer);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with selected customer and toggle button
          Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(220, 228, 228, 228),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(50.0),
                topRight: const Radius.circular(50.0),
                bottomLeft: _isExpanded
                    ? Radius.zero
                    : const Radius.circular(50.0),
                bottomRight: _isExpanded
                    ? Radius.zero
                    : const Radius.circular(50.0),
              ),
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedCustomer.isEmpty
                      ? '--Select Customer--'
                      : _selectedCustomer,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
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

          // Expandable content
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFDD400),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
                border: Border(
                  left: BorderSide(color: Colors.black, width: 1.0),
                  right: BorderSide(color: Colors.black, width: 1.0),
                  bottom: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            'Phone',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            'TIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Customer list
                    ...widget.customers.map((customer) {
                      final bool isSelected =
                          _selectedCustomer == customer.name;
                      return InkWell(
                        onTap: () => _selectCustomer(customer),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1C5380)
                                : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.0,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTableCell(customer.name),
                              _buildTableCell(customer.phone),
                              _buildTableCell(customer.tin),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black, fontSize: 14.0),
    );
  }
}
**/
