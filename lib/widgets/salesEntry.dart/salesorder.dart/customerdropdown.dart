import 'package:flutter/material.dart';
import 'package:savvy_stock/models/customer.dart';

class CustomerDropdown extends StatefulWidget {
  final Customer? value;
  final ValueChanged<Customer?> onChanged;
  final String hintText;
  const CustomerDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select Customer',
  });

  @override
  State<CustomerDropdown> createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<CustomerDropdown> {
  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();
  final _link = LayerLink();
  String _selectedCustomer = '';

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.value?.name ?? '--Selecte Customer--';
  }

  // Mock customer data
  final List<Customer> customers = [
    Customer(
      id: '1',
      name: 'John Doe',
      tin: '123456789',
      phone: '555-1234',
      country: 'USA',
    ),
    Customer(
      id: '2',
      name: 'Jane Smith',
      tin: '987654321',
      phone: '555-5678',
      country: 'Canada',
    ),
    Customer(
      id: '3',
      name: 'Acme Corp',
      tin: '456123789',
      phone: '555-9012',
      country: 'UK',
    ),
    Customer(
      id: '4',
      name: 'Global Enterprises',
      tin: '789123456',
      phone: '555-3456',
      country: 'Germany',
    ),
    Customer(
      id: '5',
      name: 'Tech Solutions Ltd',
      tin: '321654987',
      phone: '555-7890',
      country: 'Japan',
    ),
  ];

  Widget _buildTableCell(String text) {
    return GestureDetector(
      onTap: () {
        final customer = customers.firstWhere(
          (c) =>
              c.name == text ||
              c.phone == text ||
              c.tin == text ||
              c.country == text,
        );
        setState(() {
          _selectedCustomer = customer.name;
        });
        widget.onChanged(customer);
        _overlayPortalController.hide();
      },
      child: Padding(padding: const EdgeInsets.all(8.0), child: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayPortalController,
        overlayChildBuilder: (context) {
          return CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -30),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.only(top: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(50.0),
                          bottomRight: Radius.circular(50.0),
                        ),
                        border: Border(
                          left: BorderSide(color: Colors.black),
                          right: BorderSide(color: Colors.black),
                          bottom: BorderSide(color: Colors.black),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Table(
                        border: TableBorder(
                          top: BorderSide.none,
                          left: BorderSide.none,
                          right: BorderSide.none,
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                          verticalInside: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(150),
                          1: FixedColumnWidth(100),
                          2: FixedColumnWidth(120),
                        },
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Table header
                          TableRow(
                            decoration: BoxDecoration(color: Colors.amber),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Phone',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'TIN',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          // Table rows
                          ...customers
                              .map(
                                (customer) => TableRow(
                                  decoration: BoxDecoration(
                                    color: _selectedCustomer == customer.name
                                        ? Colors.blue[50]
                                        : Colors.white,
                                  ),
                                  children: [
                                    _buildTableCell(customer.name),
                                    _buildTableCell(customer.phone),
                                    _buildTableCell(customer.tin),
                                  ],
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            if (_overlayPortalController.isShowing) {
              _overlayPortalController.hide();
            } else {
              _overlayPortalController.show();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(255, 21, 88, 136)),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCustomer,
                  style: TextStyle(
                    color: _selectedCustomer.isNotEmpty
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
