import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/blocs/item_master_events.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/blocs/item_master_state.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/models/item_master_model.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/repo/item_master_repo.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/repo/migration_service.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/services/excel_service.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';

// Import other required blocs
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';

class ItemMasterBloc extends Bloc<ItemMasterEvent, ItemMasterState> {
  final ItemMasterRepository repository;
  final MigrationService migrationService;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final StockItemsEntryBloc itemsEntryBloc;
  final LocationMasterBloc locationMasterBloc;
  final StockItemInBranchBloc itemsInBranchBloc;
  final StockItemLocationBloc itemLocationsBloc;
  final LotMasterBloc lotMasterBloc;
  final ItemCostBloc itemCostBloc;
  final UdcDetailsBloc udcDetailsBloc;
  final NextNumberBloc nextNumberBloc;

  StreamSubscription? _authSubscription;

  ItemMasterBloc({
    required this.repository,
    required this.migrationService,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.itemsEntryBloc,
    required this.locationMasterBloc,
    required this.itemsInBranchBloc,
    required this.itemLocationsBloc,
    required this.lotMasterBloc,
    required this.itemCostBloc,
    required this.udcDetailsBloc,
    required this.nextNumberBloc,
  }) : super(const ItemMasterState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated) {
        // Load initial data if needed
        add(const LoadItemMasters(null));
      }
    });

    // Event handlers - Core CRUD operations
    on<LoadItemMasters>(_onLoadItemMasters);
    on<CreateItemMaster>(_onCreateItemMaster);
    on<UpdateItemMaster>(_onUpdateItemMaster);
    on<DeleteItemMaster>(_onDeleteItemMaster);
    on<DeleteSelectedItemMasters>(_onDeleteSelectedItemMasters);

    // Event handlers - Preparation operations
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCopy>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreate1>(_onPrepareCreate1);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);

    // Event handlers - Complex business operations
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);
    on<CreateInEdit>(_onCreateInEdit);
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveInEdit>(_onRemoveInEdit);
    on<RemoveRecord>(_onRemoveRecord);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);
    on<RefreshList>(_onRefreshList);

    // Event handlers - Data migration operations
    on<ApplyMigration>(_onApplyMigration);
    on<PrepareExcelTemplate>(_onPrepareExcelTemplate);
    on<ProcessExcelFile>(_onProcessExcelFile);
    on<SetColumnVisibility>(_onSetColumnVisibility);

    on<DataMigrationStock>(_onDataMigrationStock);
    on<PrepareDataMigrationImport>(_onPrepareDataMigrationImport);
    on<FilterItemEntry>(_onFilterItemEntry);
    on<SettingDefaults>(_onSettingDefaults);

    // Event handlers - Filter and search operations
    on<SearchItemMasters>(_onSearchItemMasters);
    on<GetItemsAvailableSelectMany>(_onGetItemsAvailableSelectMany);
    on<GetItemsAvailableSelectOne>(_onGetItemsAvailableSelectOne);
    on<GetItemDescriptions>(_onGetItemDescriptions);
    on<GetLocationCategories>(_onGetLocationCategories);

    // Event handlers - State management operations
    on<UpdateSelected>(_onUpdateSelected);
    on<UpdateMultiSelection>(_onUpdateMultiSelection);
    on<UpdateCreateItems>(_onUpdateCreateItems);
    on<UpdateEditItems>(_onUpdateEditItems);
    on<UpdateFilteredValues>(_onUpdateFilteredValues);
    on<UpdateFirst>(_onUpdateFirst);
    on<SaveAndClose>(_onSaveAndClose);
    on<SaveAndAddNew>(_onSaveAndAddNew);
    on<SaveAndAddContinue>(_onSaveAndAddContinue);
    on<CheckDuplicate>(_onCheckDuplicate);
    on<UpdateMigrationColumns>(_onUpdateMigrationColumns);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ========== CORE CRUD OPERATIONS ==========

  Future<void> _onLoadItemMasters(
    LoadItemMasters event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(status: ItemMasterStatus.loading));

    try {
      final items = await repository.findAll(
        companyCategoryId: event.companyCategoryId,
      );

      emit(
        state.copyWith(
          status: ItemMasterStatus.loaded,
          items: items,
          filteredItems: items,
          selectedItems: [],
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to load item masters: $e',
        ),
      );
    }
  }

  Future<void> _onCreateItemMaster(
    CreateItemMaster event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemMasterStatus.creating,
        message: 'Creating item master...',
      ),
    );

    try {
      // Check for duplication
      final isDuplicate = await _duplicateChecker(event.item);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: ItemMasterStatus.duplication,
            message: 'Duplicate Item Description Not Allowed!',
          ),
        );
        return;
      }

      await repository.create(event.item);

      // Reload items
      if (event.item.companyCategory != null) {
        add(LoadItemMasters(event.item.companyCategory!));
      }

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          message: 'Item master created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to create item master: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateItemMaster(
    UpdateItemMaster event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemMasterStatus.updating,
        message: 'Updating item master...',
      ),
    );

    try {
      // Check for duplication
      final isDuplicate = await _duplicateChecker(event.item);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: ItemMasterStatus.duplication,
            message: 'Duplicate Item Description Not Allowed!',
          ),
        );
        return;
      }

      await repository.update(event.item);

      // Reload items
      if (event.item.companyCategory != null) {
        add(LoadItemMasters(event.item.companyCategory!));
      }

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          message: 'Item master updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to update item master: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteItemMaster(
    DeleteItemMaster event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemMasterStatus.deleting,
        message: 'Deleting item master...',
      ),
    );

    try {
      if (event.item.id != null) {
        await repository.delete(event.item.id!);
      }

      // Reload items
      if (event.item.companyCategory != null) {
        add(LoadItemMasters(event.item.companyCategory!));
      }

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          message: 'Item master deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to delete item master: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSelectedItemMasters(
    DeleteSelectedItemMasters event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemMasterStatus.deleting,
        message: 'Deleting selected item masters...',
      ),
    );

    try {
      final ids = event.items
          .where((item) => item.id != null)
          .map((item) => item.id!)
          .toList();
      await repository.deleteMultiple(ids);

      // Reload items
      if (event.items.isNotEmpty && event.items.first.companyCategory != null) {
        add(LoadItemMasters(event.items.first.companyCategory!));
      }

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          message: 'Selected item masters deleted successfully',
          multiselectionItems: [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to delete selected item masters: $e',
        ),
      );
    }
  }

  // ========== PREPARATION OPERATIONS ==========

  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<ItemMasterState> emit,
  ) async {
    final createItems = List<ItemMaster>.from(state.createItems);
    int tempId = 1;

    if (createItems.isNotEmpty) {
      tempId =
          createItems
              .map((e) => e.tempId ?? 0)
              .reduce((a, b) => a > b ? a : b) +
          1;
    }

    final selected = ItemMaster(itemDescription: '', tempId: tempId);

    createItems.add(selected);

    emit(
      state.copyWith(
        createItems: createItems,
        selected: selected,
        showCreatePanel: true,
      ),
    );
  }

  Future<void> _onPrepareCopy(
    PrepareCopy event,
    Emitter<ItemMasterState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    final createItems = List<ItemMaster>.from(state.createItems);
    final selected = state.multiselectionItems.first.copyWith(id: null);

    createItems.add(selected);

    emit(
      state.copyWith(
        createItems: createItems,
        selected: selected,
        showCreatePanel: true,
      ),
    );
  }

  Future<void> _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<ItemMasterState> emit,
  ) async {
    final items = List<ItemMaster>.from(state.items);
    final selected1 = ItemMaster(itemDescription: '');

    items.add(selected1);

    emit(state.copyWith(items: items, selected1: selected1));
  }

  Future<void> _onPrepareCreate1(
    PrepareCreate1 event,
    Emitter<ItemMasterState> emit,
  ) async {
    final createItems = List<ItemMaster>.from(state.createItems);
    int tempId = 0;

    for (final item in createItems) {
      if (item.tempId != null && item.tempId! > tempId) {
        tempId = item.tempId!;
      }
    }

    final selected = ItemMaster(itemDescription: '', tempId: tempId + 1);

    createItems.add(selected);

    emit(state.copyWith(createItems: createItems, selected: selected));
  }

  Future<void> _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<ItemMasterState> emit,
  ) async {
    final editItems = List<ItemMaster>.from(state.editItems);
    final selected1 = ItemMaster(itemDescription: '');

    int tempId = 0;
    for (final item in editItems) {
      if (item.tempId != null && item.tempId! > tempId) {
        tempId = item.tempId!;
      }
    }
    tempId += 1;

    selected1.tempId = tempId;
    editItems.add(selected1);

    emit(state.copyWith(editItems: editItems, selected1: selected1));
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<ItemMasterState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    final editItems = [state.multiselectionItems.first];

    emit(
      state.copyWith(
        editItems: editItems,
        selected: state.multiselectionItems.first,
        showEditPanel: true,
      ),
    );
  }

  // ========== COMPLEX BUSINESS OPERATIONS ==========

  Future<void> _onSaveRow(SaveRow event, Emitter<ItemMasterState> emit) async {
    emit(state.copyWith(status: ItemMasterStatus.saving));

    try {
      for (final item in state.editItems) {
        if (item.id == null) {
          await repository.create(item);
        } else {
          await repository.update(item);
        }
      }

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          message: 'Saved successfully',
        ),
      );

      // Reload items
      add(const LoadItemMasters(null));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(status: ItemMasterStatus.saving));

    try {
      bool isDuplicate = false;

      for (final item in state.editItems) {
        if (state.selected2!.companyCategory != null) {
          final duplicate = await _duplicateChecker(item);
          if (duplicate &&
              (item.id == null ||
                  !state.editItems.any((existing) => existing.id == item.id))) {
            isDuplicate = true;
            break;
          } else {
            if (item.id == null) {
              await repository.create(item);
            } else {
              await repository.update(item);
            }
          }
        }
      }

      if (isDuplicate) {
        emit(
          state.copyWith(
            status: ItemMasterStatus.duplication,
            message: 'Duplicate key not allowed here!',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ItemMasterStatus.success,
            message: 'Saved successfully',
          ),
        );

        // Reload items
        add(const LoadItemMasters(null));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to save in edit: $e',
        ),
      );
    }
  }

  Future<void> _onCreateInEdit(
    CreateInEdit event,
    Emitter<ItemMasterState> emit,
  ) async {
    if (state.selected1 == null) return;

    emit(state.copyWith(status: ItemMasterStatus.creating));

    try {
      await repository.create(state.selected1!);

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          message: 'Created successfully',
        ),
      );

      // Reload items
      add(const LoadItemMasters(null));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to create: $e',
        ),
      );
    }
  }

  Future<void> _onRemoveInCreate(
    RemoveInCreate event,
    Emitter<ItemMasterState> emit,
  ) async {
    final items = [ItemMaster(itemDescription: '')];

    emit(state.copyWith(items: items));
  }

  Future<void> _onRemoveInEdit(
    RemoveInEdit event,
    Emitter<ItemMasterState> emit,
  ) async {
    final editItems = List<ItemMaster>.from(state.editItems);

    if (event.item.id == null) {
      editItems.removeWhere((element) => element.tempId == event.item.tempId);
    } else {
      editItems.removeWhere((element) => element.id == event.item.id);
      if (event.item.id != null) {
        await repository.delete(event.item.id!);
      }
    }

    emit(state.copyWith(editItems: editItems));
  }

  Future<void> _onRemoveRecord(
    RemoveRecord event,
    Emitter<ItemMasterState> emit,
  ) async {
    if (event.item.id != null) {
      await repository.delete(event.item.id!);
    }

    // Reload items
    add(const LoadItemMasters(null));
  }

  Future<void> _onCancelUpdate(
    CancelUpdate event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(selected1: null, editItems: [], showEditPanel: false));
  }

  Future<void> _onCancelCreate(
    CancelCreate event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        selected: null,
        createItems: [],
        items: [],
        showCreatePanel: false,
      ),
    );
  }

  Future<void> _onDiscardChanges(
    DiscardChanges event,
    Emitter<ItemMasterState> emit,
  ) async {
    final createItems = List<ItemMaster>.from(state.createItems);

    for (final item in createItems) {
      if (item.id != null) {
        await repository.delete(item.id!);
      }
    }

    emit(state.copyWith(selected: null, createItems: [], items: []));
  }

  Future<void> _onRefreshList(
    RefreshList event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(items: []));
    add(const LoadItemMasters(null));
  }

  // ========== DATA MIGRATION OPERATIONS ==========

  Future<void> _onApplyMigration(
    ApplyMigration event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(status: ItemMasterStatus.migrating));

    try {
      final result = await migrationService.applyMigration(event.item);

      if (result.success) {
        // Refresh data after successful migration
        add(LoadItemMasters(authBloc.state.companyId));

        emit(
          state.copyWith(
            status: ItemMasterStatus.success,
            message: result.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ItemMasterStatus.failure,
            message: result.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Migration failed: $e',
        ),
      );
    }
  }

  // Add these to your ItemMasterBloc

  // Event handlers for Excel operations
  Future<void> _onPrepareExcelTemplate(
    PrepareExcelTemplate event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(status: ItemMasterStatus.generatingTemplate));

    try {
      // Replicate Java columnsForDataMigration logic
      final (columns, columnLabels) = await _prepareMigrationColumns();
      final systemConstant = systemConstantBloc.state.selected!;
      final lotType = await migrationService.udcRepository.getUdcDetailById(
        systemConstant.lotType!,
      );

      // Generate Excel template
      final excelService = ExcelService();
      final templateFile = await excelService.generateTemplate(
        columns: columns,
        columnLabels: columnLabels,
        locationLevel:
            systemConstantBloc.state.selected?.locationCategoryLevel ?? 1,
        lotType: lotType?.detailCode ?? 'X',
      );

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          migrationColumns: columns,
          migrationColumnLabels: columnLabels,
          message: 'Template generated successfully',
        ),
      );

      // Open the file for download
      await OpenFile.open(templateFile.path);
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to generate template: $e',
        ),
      );
    }
  }

  Future<void> _onProcessExcelFile(
    ProcessExcelFile event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(status: ItemMasterStatus.processingFile));

    try {
      final excelService = ExcelService();
      final items = await excelService.parseExcelFile(
        file: event.excelFile,
        columns: event.columns,
        columnLabels: event.columnLabels,
      );

      if (items.isEmpty) {
        emit(
          state.copyWith(
            status: ItemMasterStatus.failure,
            message: 'No valid data found in the Excel file',
          ),
        );
        return;
      }

      // Add items to createItems for review before migration
      final createItems = List<ItemMaster>.from(state.createItems)
        ..addAll(items);

      emit(
        state.copyWith(
          status: ItemMasterStatus.success,
          createItems: createItems,
          uploadedItems: items,
          currentExcelFile: event.excelFile,
          showMigrationPanel: true,
          message: '${items.length} items loaded from Excel file',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to process Excel file: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateMigrationColumns(
    UpdateMigrationColumns event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        migrationColumns: event.columns,
        migrationColumnLabels: event.columnLabels,
      ),
    );
  }

  Future<void> _onSetColumnVisibility(
    SetColumnVisibility event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(columnVisibility: event.columnVisibility));
  }

  /// Helper method to replicate Java columnsForDataMigration logic
  Future<(List<String>, Map<String, String>)> _prepareMigrationColumns() async {
    final systemConstant = systemConstantBloc.state.selected;
    final level = systemConstant?.locationCategoryLevel ?? 1;
    final lotType = await migrationService.udcRepository.getUdcDetailById(
      systemConstant?.lotType,
    );

    // Replicate Java date field logic
    final dateField = "dateExpired";
    final dateLabel =
        (systemConstant?.lotType == null || lotType?.detailCode == 'X')
        ? "Expiration Date"
        : (lotType?.detailCode == 'F'
              ? "Effective Date"
              : (lotType?.detailCode == 'R' ? "Received Date" : ""));

    // Calculate column size based on level - replicates Java logic
    final columnSize = level == 1
        ? 10
        : (level == 2
              ? 11
              : (level == 3
                    ? 12
                    : (level == 4
                          ? 13
                          : (level == 5
                                ? 14
                                : (level == 6
                                      ? 15
                                      : (level == 7
                                            ? 16
                                            : (level == 8
                                                  ? 17
                                                  : (level == 9
                                                        ? 18
                                                        : 19))))))));

    // Base columns - replicates Java baseColumns logic
    final baseColumns = List<String>.filled(columnSize, '');
    baseColumns[0] = "itemDescription";
    baseColumns[1] = "branch";
    baseColumns[2] = "defualtUom";
    baseColumns[3] = "taxableFlag";
    baseColumns[4] = "unitPrice";
    baseColumns[5] = "unitCost";
    baseColumns[6] = "quantity";
    baseColumns[7] = dateField;
    baseColumns[8] = "batchNumber";

    // Add location codes dynamically
    for (int i = 9; i < columnSize; i++) {
      baseColumns[i] = "locationCode${i - 8}";
    }

    // Create column labels map - replicates Java columns4LabelMap
    final columnLabels = <String, String>{};
    columnLabels["itemDescription"] = "Item Description";
    columnLabels["branch"] = "Store";
    columnLabels["defualtUom"] = "UoM";
    columnLabels["taxableFlag"] = "Taxable (Y/N)";
    columnLabels["unitPrice"] = "Unit Price";
    columnLabels["unitCost"] = "Unit Cost";
    columnLabels["quantity"] = "Quantity";
    columnLabels[dateField] = dateLabel;
    columnLabels["batchNumber"] = "Batch Number";

    // Add location code labels
    for (int i = 9; i < columnSize; i++) {
      final key = "locationCode${i - 8}";
      columnLabels[key] = "Location ${i - 8}";
    }

    return (baseColumns, columnLabels);
  }

  Future<void> _onDataMigrationStock(
    DataMigrationStock event,
    Emitter<ItemMasterState> emit,
  ) async {
    if (state.createItems.isEmpty) return;

    final validItems = state.createItems
        .where(
          (item) =>
              item.itemDescription!.isNotEmpty && item.dateExpired != null,
        )
        .toList();

    if (validItems.isNotEmpty) {
      for (final item in validItems) {
        add(ApplyMigration(item));
      }
    }
  }

  Future<void> _onPrepareDataMigrationImport(
    PrepareDataMigrationImport event,
    Emitter<ItemMasterState> emit,
  ) async {
    // This would prepare the data migration columns based on system constants
    // For now, we'll set up basic columns
    final columns = [
      "itemDescription",
      "branch",
      "defualtUom",
      "taxableFlag",
      "unitPrice",
      "locationCode1",
      "quantity",
      "dateExpired",
      "batchNumber",
      "unitCost",
    ];

    final columnLabels = {
      "itemDescription": "Item Description",
      "branch": "Store",
      "defualtUom": "UoM",
      "taxableFlag": "Taxable (Y/N)",
      "unitPrice": "Unit Price",
      "unitCost": "Unit Cost",
      "quantity": "Quantity",
      "dateExpired": "Expiration Date",
      "batchNumber": "Batch Number",
      "locationCode1": "Location 01",
    };

    emit(
      state.copyWith(
        columns4: columns,
        columns4LabelMap: columnLabels,
        showMigrationPanel: true,
      ),
    );
  }

  Future<void> _onFilterItemEntry(
    FilterItemEntry event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      List<ItemMaster> editItems = [];

      if (state.selected2!.companyCategory != null) {
        editItems = await repository.findByCompanyCategory(
          state.selected2!.companyCategory!,
        );
      }

      emit(state.copyWith(editItems: editItems));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to filter item entry: $e',
        ),
      );
    }
  }

  Future<void> _onSettingDefaults(
    SettingDefaults event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      if (event.item.itemDescription!.isNotEmpty) {
        final existingItem = await repository.findByDescription(
          event.item.itemDescription!,
          event.item.companyCategory ?? 0,
        );

        if (existingItem != null) {
          // Update the item with defaults from existing item
          // This would be handled in the UI layer by updating the form
        }
      }
    } catch (e) {
      // Handle error silently as this is a convenience feature
      print('Error setting defaults: $e');
    }
  }

  // ========== FILTER AND SEARCH OPERATIONS ==========

  Future<void> _onSearchItemMasters(
    SearchItemMasters event,
    Emitter<ItemMasterState> emit,
  ) async {
    emit(state.copyWith(status: ItemMasterStatus.searching));

    try {
      final results = await repository.search(
        event.query,
        companyCategoryId: event.companyCategoryId,
      );

      emit(
        state.copyWith(
          status: ItemMasterStatus.loaded,
          filteredItems: results,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to search item masters: $e',
        ),
      );
    }
  }

  Future<void> _onGetItemsAvailableSelectMany(
    GetItemsAvailableSelectMany event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      final items = await repository.getItemsForSelectMany(
        event.companyCategoryId,
      );
      // This would typically be used for dropdowns or multi-select components
      // The result would be stored in appropriate state or used directly in UI
    } catch (e) {
      // Handle error
      print('Error getting items for select many: $e');
    }
  }

  Future<void> _onGetItemsAvailableSelectOne(
    GetItemsAvailableSelectOne event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      final items = await repository.getItemsForSelectOne();
      // This would typically be used for dropdown components
    } catch (e) {
      // Handle error
      print('Error getting items for select one: $e');
    }
  }

  Future<void> _onGetItemDescriptions(
    GetItemDescriptions event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      final descriptions = await repository.getItemDescriptions(
        event.companyCategoryId,
      );
      // This would be used for autocomplete or search suggestions
    } catch (e) {
      // Handle error
      print('Error getting item descriptions: $e');
    }
  }

  Future<void> _onGetLocationCategories(
    GetLocationCategories event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      // This would integrate with UDC details repository
      // For now, we'll leave it as a placeholder
    } catch (e) {
      // Handle error
      print('Error getting location categories: $e');
    }
  }

  // ========== STATE MANAGEMENT OPERATIONS ==========

  void _onUpdateSelected(UpdateSelected event, Emitter<ItemMasterState> emit) {
    emit(
      state.copyWith(
        selected: event.selected,
        selected1: event.selected1,
        selected2: event.selected2 ?? state.selected2,
      ),
    );
  }

  void _onUpdateMultiSelection(
    UpdateMultiSelection event,
    Emitter<ItemMasterState> emit,
  ) {
    emit(state.copyWith(multiselectionItems: event.multiSelectionItems));
  }

  void _onUpdateCreateItems(
    UpdateCreateItems event,
    Emitter<ItemMasterState> emit,
  ) {
    emit(state.copyWith(createItems: event.createItems));
  }

  void _onUpdateEditItems(
    UpdateEditItems event,
    Emitter<ItemMasterState> emit,
  ) {
    emit(state.copyWith(editItems: event.editItems));
  }

  void _onUpdateFilteredValues(
    UpdateFilteredValues event,
    Emitter<ItemMasterState> emit,
  ) {
    emit(state.copyWith(filteredValues: event.filteredValues));
  }

  void _onUpdateFirst(UpdateFirst event, Emitter<ItemMasterState> emit) {
    emit(state.copyWith(first: event.first));
  }

  void _onSaveAndClose(SaveAndClose event, Emitter<ItemMasterState> emit) {
    add(const CancelUpdate());
    add(const CancelCreate());
    // Navigation would be handled in the UI layer
  }

  void _onSaveAndAddNew(SaveAndAddNew event, Emitter<ItemMasterState> emit) {
    emit(state.copyWith(createItems: [ItemMaster(itemDescription: '')]));
    // Navigation would be handled in the UI layer
  }

  void _onSaveAndAddContinue(
    SaveAndAddContinue event,
    Emitter<ItemMasterState> emit,
  ) {
    if (state.selected != null) {
      emit(state.copyWith(createItems: [state.selected!]));
    }
    // Navigation would be handled in the UI layer
  }

  Future<void> _onCheckDuplicate(
    CheckDuplicate event,
    Emitter<ItemMasterState> emit,
  ) async {
    try {
      final isDuplicate = await _duplicateChecker(event.item);
      emit(state.copyWith(isDuplicate: isDuplicate));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemMasterStatus.failure,
          message: 'Failed to check duplicate: $e',
        ),
      );
    }
  }

  // ========== HELPER METHODS ==========

  Future<bool> _duplicateChecker(ItemMaster item) async {
    if (item.companyCategory == null || item.itemDescription!.isEmpty) {
      return false;
    }

    return await repository.checkDuplicate(
      itemDescription: item.itemDescription!,
      companyCategoryId: item.companyCategory!,
      excludeId: item.id,
    );
  }
}
