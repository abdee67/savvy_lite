import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/models/SalesEntry/salesorder.dart';
import 'package:savvy_stock/models/confirmedItems.dart';
import 'package:savvy_stock/models/itemInStore.dart';
import 'package:savvy_stock/models/items.dart';
import 'package:savvy_stock/models/selectedItem.dart';
import 'package:savvy_stock/screens/paymentSummary.dart';
import 'package:savvy_stock/screens/stores.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/barcode_section.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/item_list.dart';

class ItemEntryScreen extends StatefulWidget {
  const ItemEntryScreen({super.key});

  @override
  _ItemEntryScreenState createState() => _ItemEntryScreenState();
}

class _ItemEntryScreenState extends State<ItemEntryScreen> {
  List<SelectedItem> selectedItems = [];
  List<ItemInStore> itemsInStores = [];
  List<ConfirmedItem> confirmedItems = [];
  final NumberFormat currencyFormat = NumberFormat('#,##0.00');
  bool _useBarcode = false;
  final ScrollController _upperScrollController = ScrollController();
  final ScrollController _lowerScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Mock data initialization
    _initializeData();
    // Add an empty item to start with
    selectedItems.add(SelectedItem());
  }

  void _initializeData() {
    // Create some sample items
    final items = [
      Item(
        id: 'ITM-001',
        description: 'Laptop Computer',
        uom: 'PCS',
        barcode: 123456789000,
      ),
      Item(
        id: 'ITM-002',
        description: 'Wireless Mouse',
        uom: 'PCS',
        barcode: 987654321000,
      ),
      Item(
        id: 'ITM-003',
        description: 'Keyboard',
        uom: 'PCS',
        barcode: 112233445000,
      ),
      Item(
        id: 'ITM-004',
        description: 'Monitor 24"',
        uom: 'PCS',
        barcode: 556677889000,
      ),
      Item(
        id: 'ITM-005',
        description: 'Webcam HD',
        uom: 'PCS',
        barcode: 334455667000,
      ),
    ];

    // Create some sample stores
    final stores = [
      Store(
        id: 'STR-001',
        branchName: 'Main Branch',
        unitPrice: 999.99,
        availability: 15,
      ),
      Store(
        id: 'STR-002',
        branchName: 'Downtown Branch',
        unitPrice: 1029.99,
        availability: 8,
      ),
      Store(
        id: 'STR-003',
        branchName: 'Westside Branch',
        unitPrice: 949.99,
        availability: 3,
      ),
      Store(
        id: 'STR-004',
        branchName: 'North Branch',
        unitPrice: 979.99,
        availability: 0,
      ),
    ];

    // Create relationships between items and stores
    itemsInStores = [
      ItemInStore(
        item: items[0],
        availableStores: [
          stores[0],
          stores[1],
          stores[2],
        ], // Laptop available in 3 stores
      ),
      ItemInStore(
        item: items[1],
        availableStores: [stores[0], stores[3]], // Mouse available in 2 stores
      ),
      ItemInStore(
        item: items[2],
        availableStores: [
          stores[1],
          stores[2],
          stores[3],
        ], // Keyboard available in 3 stores
      ),
      ItemInStore(
        item: items[3],
        availableStores: [], // Monitor out of stock in all stores
      ),
      ItemInStore(
        item: items[4],
        availableStores: [
          stores[0],
          stores[1],
          stores[2],
          stores[3],
        ], // Webcam available in all stores
      ),
    ];
  }

  List<Store> _getAvailableStoresForItem(Item? item) {
    if (item == null) return [];

    final itemInStore = itemsInStores.firstWhere(
      (element) => element.item.id == item.id,
      orElse: () => ItemInStore(item: item, availableStores: []),
    );

    return itemInStore.availableStores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // This prevents the scaffold from resizing when keyboard appears
      body: SafeArea(
        child: Column(
          children: [
            // Upper Section - Order Items (will scroll when keyboard appears)
            Expanded(
              flex: 3, // Give more space to the upper section
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Items List
                    Expanded(
                      child: selectedItems.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _upperScrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: selectedItems.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildItemEntry(
                                    selectedItems[index],
                                    index,
                                  ),
                                );
                              },
                            ),
                    ),
                    // Action Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed:
                              selectedItems.any(
                                (item) => item.extendedPrice > 0,
                              )
                              ? _addToLowerPage
                              : null,
                          icon: Icon(
                            selectedItems.any((item) => item.extendedPrice > 0)
                                ? Icons.check
                                : Icons.outlined_flag,
                          ),
                          label: Text(
                            selectedItems.any((item) => item.extendedPrice > 0)
                                ? 'Confirm Order'
                                : 'Select first',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedItems.any(
                                  (item) => item.extendedPrice > 0,
                                )
                                ? const Color.fromARGB(255, 10, 38, 58)
                                : Colors.grey,
                            foregroundColor:
                                selectedItems.any(
                                  (item) => item.extendedPrice > 0,
                                )
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Lower Section - Order Summary (fixed position)
            Container(
              height: MediaQuery.of(context).size.height * 0.4, // Fixed height
              color: Colors.grey.shade500,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Scrollable list of confirmed items
                  Expanded(
                    child: confirmedItems.isEmpty
                        ? Center(
                            child: Text(
                              'No items confirmed yet',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            controller: _lowerScrollController,
                            itemCount: confirmedItems.length,
                            itemBuilder: (context, index) {
                              final item = confirmedItems[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.quantity.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 14,
                                          background: Paint()
                                            ..color = Colors.grey.shade200,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '\$${item.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 29, 91, 134),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '\$${_getTotalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: _getTotalPrice() > 0
                          ? _navigateToSummary
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          24,
                          103,
                          160,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save & Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No items added yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget itemDropdown(SelectedItem selectedItem, int index) {
    return PopupMenuButton<Item>(
      itemBuilder: (BuildContext context) {
        return itemsInStores.map((ItemInStore item) {
          return PopupMenuItem<Item>(
            value: item.item,
            height: 60, // Set a fixed height for each item
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    item.item.id,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Color.fromARGB(255, 61, 61, 61),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 61, 61, 61),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      onSelected: (Item? newValue) {
        setState(() {
          selectedItem.item = newValue;
          selectedItem.store = null;

          final stores = _getAvailableStoresForItem(newValue);
          if (stores.isNotEmpty) {
            selectedItem.store = stores.first;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 10, 38, 58)),
          borderRadius: BorderRadius.circular(30.0),
          color: Colors.grey.shade200,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedItem.item?.id ?? '--Select One--',
              style: TextStyle(
                color: selectedItem.item != null
                    ? Colors.black
                    : Color.fromARGB(255, 10, 38, 58),
                fontSize: 14,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color.fromARGB(255, 10, 38, 58),
            ),
          ],
        ),
      ),
    );
  }

  Widget storeDropdown(SelectedItem selectedItem, int index) {
    final availableStores = _getAvailableStoresForItem(selectedItem.item);
    selectedItem.isOutOfStock =
        availableStores.isEmpty && selectedItem.item != null;
    return PopupMenuButton<Store>(
      itemBuilder: (BuildContext context) {
        return availableStores.map((Store store) {
          return PopupMenuItem<Store>(
            value: store,
            height: 60, // Set a fixed height for each item
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    store.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Color.fromARGB(255, 61, 61, 61),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.branchName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 61, 61, 61),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Color.fromARGB(255, 61, 61, 61),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedItem.item?.description ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 61, 61, 61),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Color.fromARGB(255, 61, 61, 61),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.availability.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 61, 61, 61),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Color.fromARGB(255, 61, 61, 61),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currencyFormat.format(store.unitPrice),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 61, 61, 61),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      onSelected: (Store? newValue) {
        setState(() {
          selectedItem.store = newValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Color.fromARGB(255, 10, 38, 58)),
          borderRadius: BorderRadius.circular(30.0),
          color: Colors.grey.shade200,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedItem.store?.id ?? '--Select One--',
              style: TextStyle(
                color: selectedItem.store != null ? Colors.black : Colors.grey,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildItemEntry(SelectedItem selectedItem, int index) {
    final availableStores = _getAvailableStoresForItem(selectedItem.item);
    selectedItem.isOutOfStock =
        availableStores.isEmpty && selectedItem.item != null;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            // Item selection with ID and Description
            itemDropdown(selectedItem, index),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 10, 38, 58),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  selectedItem.quantity = double.tryParse(value) ?? 0;
                });
              },
            ),

            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'UoM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: selectedItem.item?.uom ?? '',
              ),
            ),
            SizedBox(height: 16),
            // Store selection or Out of Stock message
            if (selectedItem.item != null) ...[
              if (selectedItem.isOutOfStock)
                Text(
                  'Out of Stock',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              else
                storeDropdown(selectedItem, index),
            ],
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Unit Price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: selectedItem.unitPrice > 0
                    ? currencyFormat.format(selectedItem.unitPrice)
                    : '',
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Line Total',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: selectedItem.extendedPrice > 0
                    ? currencyFormat.format(selectedItem.extendedPrice)
                    : '',
              ),
            ),
            // Barcode toggle
            Row(
              children: [
                Checkbox(
                  value: _useBarcode,
                  onChanged: (value) {
                    setState(() {
                      _useBarcode = value ?? false;
                    });
                  },
                ),
                const Text('Use Barcode'),
              ],
            ),

            const SizedBox(height: 10),

            // Barcode section (conditionally shown)
            if (_useBarcode)
              BarcodeSection(
                onItemAdded: (List<ConfirmedItem> items) {
                  setState(() {
                    confirmedItems.addAll(items);
                  });
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addNewItem() {
    setState(() {
      selectedItems.add(SelectedItem());
    });
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedItems.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  int _getSelectedItemsCount() {
    return selectedItems.where((item) => item.item != null).length;
  }

  double _getTotalQuantity() {
    return selectedItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double _getTotalPrice() {
    return confirmedItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void _navigateToSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryPaymentPage(
          selectedItems: selectedItems,
          totalAmount: _getTotalPrice(),
        ),
      ),
    );
  }

  void _addToLowerPage() {
    setState(() {
      for (var item in selectedItems) {
        if (item.item != null && item.quantity > 0 && item.extendedPrice > 0) {
          confirmedItems.add(
            ConfirmedItem(
              itemName: item.item!.description,
              quantity: item.quantity,
              totalPrice: item.extendedPrice,
            ),
          );
        }
      }
      selectedItems.clear();
      selectedItems.add(SelectedItem());
    });
  }

  @override
  void dispose() {
    _upperScrollController.dispose();
    _lowerScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
