import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/models/confirmedItems.dart';
import 'package:savvy_stock/models/itemInStore.dart';
import 'package:savvy_stock/models/items.dart';
import 'package:savvy_stock/models/selectedItem.dart';
import 'package:savvy_stock/screens/paymentSummary.dart';
import 'package:savvy_stock/screens/stores.dart';

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
      Item(id: 'ITM-001', description: 'Laptop Computer', uom: 'PCS'),
      Item(id: 'ITM-002', description: 'Wireless Mouse', uom: 'PCS'),
      Item(id: 'ITM-003', description: 'Keyboard', uom: 'PCS'),
      Item(id: 'ITM-004', description: 'Monitor 24"', uom: 'PCS'),
      Item(id: 'ITM-005', description: 'Webcam HD', uom: 'PCS'),
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
      body: Column(
        children: [
          // Upper part - White background
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedItems.length,
                      itemBuilder: (context, index) {
                        return _buildItemEntry(selectedItems[index], index);
                      },
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        selectedItems.any((item) => item.extendedPrice > 0)
                            ? _addToLowerPage()
                            : _addNewItem();
                      },
                      icon: Icon(
                        selectedItems.any((item) => item.extendedPrice > 0)
                            ? Icons.check
                            : Icons.add,
                      ),
                      label: Text(
                        selectedItems.any((item) => item.extendedPrice > 0)
                            ? 'Confirm Order'
                            : 'Add New Item',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedItems.any((item) => item.extendedPrice > 0)
                            ? Color.fromARGB(255, 10, 38, 58)
                            : Colors.amber,
                        foregroundColor:
                            selectedItems.any((item) => item.extendedPrice > 0)
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lower part - Black background
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            color: Colors.grey.shade500,
            padding: EdgeInsets.all(16),
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
                          itemCount: confirmedItems.length,
                          itemBuilder: (context, index) {
                            final item = confirmedItems[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      confirmedItems.isEmpty
                                          ? 'Item name'
                                          : item.itemName,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      confirmedItems.isEmpty
                                          ? 'Qunatity'
                                          : item.quantity.toStringAsFixed(2),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        background: Paint()
                                          ..color = Colors.grey.shade200,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      confirmedItems.isEmpty
                                          ? 'Total price'
                                          : '${currencyFormat.format(item.totalPrice)} ETB',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Color.fromARGB(255, 10, 38, 58),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(_getTotalPrice())} ETB',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: _getTotalPrice() > 0 ? _navigateToSummary : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 10, 38, 58),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Save & Continue'),
                  ),
                ),
              ],
            ),
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
}
