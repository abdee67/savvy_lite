import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/selected_item.dart';
import 'package:savvy_stock/features/sales/payment/screens/paymentSummary.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/barcode_section.dart';

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
    _initializeData();
    // Mock data initialization
    // Add an empty item to start with
    selectedItems.add(SelectedItem());
  }

  void _initializeData() {
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
              flex: 1, // Give more space to the upper section
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
                              padding: const EdgeInsets.all(8),
                              itemCount: selectedItems.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: _buildItemEntry(
                                    selectedItems[index],
                                    index,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // This Stack will contain both the button and the lower section
            Expanded(
              child: Stack(
                clipBehavior: Clip.none, // Allow button to overflow
                children: [
                  // Lower Section - Order Summary (fixed position)
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey.shade500,
                      padding: const EdgeInsets.only(
                        top: 30, // Reduced top padding to make room for button
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 4), // Space for the button
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
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                item.quantity.toStringAsFixed(
                                                  2,
                                                ),
                                                style: TextStyle(fontSize: 14),
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
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
                  ),
                  // The button positioned between sections
                  Positioned(
                    right: 16,
                    top: -20, // Half outside the container
                    child: SizedBox(
                      width: 150,
                      height: 40, // Fixed height for the button
                      child: ElevatedButton(
                        onPressed:
                            selectedItems.any((item) => item.extendedPrice > 0)
                            ? _addToLowerPage
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              selectedItems.any(
                                (item) => item.extendedPrice > 0,
                              )
                              ? const Color.fromARGB(255, 29, 110, 168)
                              : Colors.grey,
                          foregroundColor:
                              selectedItems.any(
                                (item) => item.extendedPrice > 0,
                              )
                              ? Colors.white
                              : Colors.black,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          selectedItems.any((item) => item.extendedPrice > 0)
                              ? 'Confirm Order'
                              : 'Select item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
            // Item selection with ID and Description
            CustomTableDropdown<Item>(
              title: 'Item',
              items: itemsInStores
                  .map((ItemInStore itemInStore) => itemInStore.item)
                  .toList(),
              displayText: (item) => item.description,
              selectedValue: selectedItem.item,
              columns: [
                TableColumnConfig(
                  header: 'ID',
                  cellBuilder: (item) => Text(item.id),
                ),
                TableColumnConfig(
                  header: 'Description',
                  cellBuilder: (item) => Text(item.description),
                ),
              ],
              onItemSelected: (Item? newValue) {
                setState(() {
                  selectedItem.item = newValue;
                  selectedItem.store = null;
                  final stores = _getAvailableStoresForItem(newValue);
                  if (stores.isNotEmpty) {
                    selectedItem.store = stores.first;
                  }
                });
              },
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
                CustomTableDropdown<Store>(
                  title: 'Store',
                  items: _getAvailableStoresForItem(selectedItem.item),
                  displayText: (store) => store.branchName,
                  selectedValue: selectedItem.store,
                  columns: [
                    TableColumnConfig(
                      header: 'Branch',
                      cellBuilder: (store) => Text(store.branchName),
                    ),
                    TableColumnConfig(
                      header: 'Item',
                      cellBuilder: (store) =>
                          Text(selectedItem.item?.description ?? ''),
                    ),
                    TableColumnConfig(
                      header: 'Available ',
                      cellBuilder: (store) =>
                          Text(store.availability.toString()),
                    ),
                    TableColumnConfig(
                      header: 'Unit Price',
                      cellBuilder: (store) =>
                          Text(currencyFormat.format(store.unitPrice)),
                    ),
                  ],
                  onItemSelected: (store) {
                    setState(() {
                      selectedItem.store = store;
                    });
                  },
                ),
            ],
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Quantity',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  selectedItem.quantity = double.tryParse(value) ?? 0;
                });
              },
            ),

            SizedBox(height: 16),
            CustomTextField(
              labelText: 'UoM',
              value: selectedItem.item?.uom ?? '',
              readOnly: true,
            ),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Unit Price',
              value: selectedItem.store != null
                  ? currencyFormat.format(selectedItem.store!.unitPrice)
                  : '',
              readOnly: true,
            ),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Line Total',
              value: selectedItem.extendedPrice > 0
                  ? currencyFormat.format(selectedItem.extendedPrice)
                  : '',
              readOnly: true,
            ),
            SizedBox(height: 16),
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
      _useBarcode = false;
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
