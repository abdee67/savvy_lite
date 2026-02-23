// services/excel_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/models/item_master_model.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class ExcelService {
  /// Generate Excel template using Syncfusion (better formatting)
  Future<File> generateTemplate({
    required List<String> columns,
    required Map<String, String> columnLabels,
    required int locationLevel,
    required String lotType,
  }) async {
    try {
      // Create a new Excel document
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'ItemMasterTemplate';

      // Add headers with labels
      for (int i = 0; i < columns.length; i++) {
        final columnName = columns[i];
        final label = columnLabels[columnName] ?? columnName;
        sheet.getRangeByIndex(1, i + 1).setText(label);

        // Style header
        final range = sheet.getRangeByIndex(1, i + 1);
        range.cellStyle.backColor = '#2E86AB';
        range.cellStyle.fontColor = '#FFFFFF';
        range.cellStyle.bold = true;
      }

      // Add example data row
      final exampleRow = _getExampleData(columns, locationLevel, lotType);
      for (int i = 0; i < exampleRow.length; i++) {
        final range = sheet.getRangeByIndex(2, i + 1);
        final value = exampleRow[i];

        if (_isNumeric(value)) {
          range.setNumber(double.tryParse(value) ?? 0.0);
        } else if (_isDate(value)) {
          range.setDateTime(DateTime.tryParse(value) ?? DateTime.now());
        } else {
          range.setText(value);
        }

        // Style data row
        range.cellStyle.backColor = '#F0F8FF';
      }

      // Auto-fit columns
      for (int i = 1; i <= columns.length; i++) {
        sheet.autoFitColumn(i);
      }

      // Save and dispose workbook
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Save to file
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/item_master_template_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      return file;
    } catch (e) {
      throw Exception('Failed to generate Excel template: $e');
    }
  }

  /// Parse Excel file using Syncfusion
  Future<List<ItemMaster>> parseExcelFile({
    required File file,
    required List<String> columns,
    required Map<String, String> columnLabels,
  }) async {
    try {
      final List<int> bytes = await file.readAsBytes();

      // FIX: Remove the incorrect cast
      final Workbook workbook = Workbook(bytes.first);
      final Worksheet sheet = workbook.worksheets[0];

      final List<ItemMaster> items = [];

      // Alternative approach: iterate until we find empty rows
      int rowIndex = 2; // Start from row 2 (skip header)
      bool hasMoreRows = true;

      while (hasMoreRows) {
        final item = ItemMaster();
        bool hasData = false;

        for (int colIndex = 0; colIndex < columns.length; colIndex++) {
          final range = sheet.getRangeByIndex(rowIndex, colIndex + 1);
          final String cellValue = range.displayText;

          if (cellValue.isNotEmpty) {
            hasData = true;
            _mapExcelValueToItemMaster(item, columns[colIndex], cellValue);
          }
        }

        // If no data in this row, we've reached the end
        if (!hasData) {
          hasMoreRows = false;
        } else if (_isValidItem(item)) {
          items.add(item);
        }

        rowIndex++;

        // Safety check: don't process more than 1000 rows
        if (rowIndex > 1000) {
          hasMoreRows = false;
        }
      }

      workbook.dispose();
      return items;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  /// Map Excel column values to ItemMaster fields
  void _mapExcelValueToItemMaster(
    ItemMaster item,
    String column,
    String value,
  ) {
    if (value.isEmpty) return;

    switch (column) {
      case 'itemDescription':
        item.itemDescription = value;
        break;
      case 'branch':
        // FIX: Use the correct field name based on your ItemMaster model
        item.branchDescription = value; // or item.branchDescription = value;
        break;
      case 'defualtUom':
        // FIX: Use the correct field name
        item.defualtUomDescription =
            value; // or item.defualtUomDescription = value;
        break;
      case 'taxableFlag':
        item.taxableFlag = value;
        item.taxableBoolean = value.toUpperCase() == 'Y';
        break;
      case 'unitPrice':
        item.unitPrice = double.tryParse(value) ?? 0.0;
        break;
      case 'unitCost':
        item.unitCost = double.tryParse(value) ?? 0.0;
        break;
      case 'quantity':
        item.quantity = double.tryParse(value) ?? 0.0;
        break;
      case 'dateExpired':
        item.dateExpired = _parseDate(value);
        break;
      case 'batchNumber':
        item.batchNumber = value;
        break;
      case 'locationCode1':
        item.locationCode1 = value;
        break;
      case 'locationCode2':
        item.locationCode2 = value;
        break;
      case 'locationCode3':
        item.locationCode3 = value;
        break;
      case 'locationCode4':
        item.locationCode4 = value;
        break;
      case 'locationCode5':
        item.locationCode5 = value;
        break;
      case 'locationCode6':
        item.locationCode6 = value;
        break;
      case 'locationCode7':
        item.locationCode7 = value;
        break;
      case 'locationCode8':
        item.locationCode8 = value;
        break;
      case 'locationCode9':
        item.locationCode9 = value;
        break;
      case 'locationCode10':
        item.locationCode10 = value;
        break;
    }
  }

  /// Check if item has minimum required data
  bool _isValidItem(ItemMaster item) {
    return item.itemDescription?.isNotEmpty == true &&
        item.branchDescription?.isNotEmpty == true;
  }

  List<String> _getExampleData(
    List<String> columns,
    int level,
    String lotType,
  ) {
    final exampleData = <String>[];

    for (final column in columns) {
      exampleData.add(_getExampleValue(column, level, lotType));
    }

    return exampleData;
  }

  String _getExampleValue(String column, int level, String lotType) {
    switch (column) {
      case 'itemDescription':
        return 'Sample Item Description';
      case 'branch':
        return 'MAIN';
      case 'defualtUom':
        return 'PC';
      case 'taxableFlag':
        return 'Y';
      case 'unitPrice':
        return '100.00';
      case 'unitCost':
        return '80.00';
      case 'quantity':
        return '50.0';
      case 'dateExpired':
        final now = DateTime.now();
        final futureDate = DateTime(now.year + 1, now.month, now.day);
        return '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      case 'batchNumber':
        return 'BATCH001';
      case 'locationCode1':
        return 'WAREHOUSE-A';
      default:
        if (column.startsWith('locationCode')) {
          final index =
              int.tryParse(column.replaceAll('locationCode', '')) ?? 1;
          return index <= level ? 'LOC-LEVEL-$index' : '';
        }
        return '';
    }
  }

  bool _isNumeric(String str) {
    if (str.isEmpty) return false;
    return double.tryParse(str) != null;
  }

  bool _isDate(String str) {
    return DateTime.tryParse(str) != null;
  }

  /// Parse date from string with multiple format support
  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    // Try ISO format first
    DateTime? date = DateTime.tryParse(dateString);
    if (date != null) return date;

    // Try common formats
    final formats = ['yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy/MM/dd'];

    for (final format in formats) {
      final parts = dateString.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        int? year, month, day;

        if (format == 'yyyy-MM-dd' || format == 'yyyy/MM/dd') {
          year = int.tryParse(parts[0]);
          month = int.tryParse(parts[1]);
          day = int.tryParse(parts[2]);
        } else if (format == 'MM/dd/yyyy') {
          month = int.tryParse(parts[0]);
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        } else if (format == 'dd/MM/yyyy') {
          day = int.tryParse(parts[0]);
          month = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }

        if (year != null && month != null && day != null) {
          // Handle two-digit years
          if (year < 100) {
            year += 2000;
          }

          try {
            return DateTime(year, month, day);
          } catch (e) {
            continue;
          }
        }
      }
    }

    return null;
  }

  // Note: _getColumnLetter is not used in Syncfusion implementation
  // You can remove it unless used elsewhere
}
