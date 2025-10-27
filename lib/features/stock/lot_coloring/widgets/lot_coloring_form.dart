import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_event.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_state.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class LotExpirationColorsFormPage extends StatefulWidget {
  final AuthBloc authBloc;
  final LotExpirationColor? existingColoring; // null = create mode

  const LotExpirationColorsFormPage({
    super.key,
    required this.authBloc,
    this.existingColoring,
  });

  @override
  State<LotExpirationColorsFormPage> createState() =>
      _LotExpirationColorsFormPageState();
}

class _LotExpirationColorsFormPageState
    extends State<LotExpirationColorsFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLevel;
  int? _selectedBranch;
  int? _selectedItem;

  final List<LotExpirationColor> _colorRanges = [];

  @override
  void initState() {
    super.initState();

    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('CT'));
    context.read<StockItemEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );
    context.read<StockItemInBranchBloc>().add(
      LoadItemsFromBranch(widget.authBloc.state.companyId!),
    );

    if (widget.existingColoring != null) {
      // Prepopulate if editing
      final c = widget.existingColoring!;
      _selectedLevel = c.lotExpLevel?.toString();
      _selectedBranch = c.branch;
      _selectedItem = c.itemNumber;
      _colorRanges.add(c);
    } else {
      // Start with one empty range
      _addNewRange();
    }
  }

  void _suggestNextRange() {
    // Determine existing ranges for selected level/scope
    final bloc = context.read<LotExpirationColorsBloc>();
    final existing = bloc.state.items.where((i) {
      if (i.lotExpLevel != _selectedLevel) return false;
      switch (_selectedLevel) {
        case '1':
          return i.branch == null && i.itemNumber == null;
        case '2':
          return i.branch == _selectedBranch && i.itemNumber == null;
        case '3':
          return i.itemNumber == _selectedItem && i.branch == null;
        case '4':
          return i.branch == _selectedBranch && i.itemNumber == _selectedItem;
        default:
          return false;
      }
    }).toList();

    int suggestedMax;
    if (existing.isEmpty) {
      // No existing ranges: default suggestion
      suggestedMax = 9999;
    } else {
      // Find the smallest daysMinimum among existing ranges and suggest its - 1
      final mins = existing.map((e) => e.daysMinimum ?? 0).toList();
      final minOfMins = mins.reduce((v, e) => v < e ? v : e);
      suggestedMax = minOfMins - 1;
    }

    // If there's an existing empty range (missing min or max), fill its max with suggestion
    final idxToFill = _colorRanges.indexWhere((r) => r.daysMaximum == null || r.daysMinimum == null);
    if (idxToFill != -1) {
      setState(() {
        final r = _colorRanges[idxToFill];
        r.daysMaximum = suggestedMax;
        // keep daysMinimum as-is (user should fill it if missing)
      });
    } else {
      // Create a new pre-filled range with suggested max; user can adjust min/type
      setState(() {
        _colorRanges.add(LotExpirationColor(
          tempId: DateTime.now().millisecondsSinceEpoch,
          company: widget.authBloc.state.companyId!,
          daysMinimum: null,
          daysMaximum: suggestedMax,
          colorType: null,
          description: '',
          activeForSalesFlag: 'Y',
        ));
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Suggested max days: $suggestedMax (you can edit before saving)'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _onBranchChanged(int? branchId) {
    setState(() {
      _selectedBranch = branchId;
      _selectedItem = null;
    });

    if (branchId != null) {
      // Load items for selected branch
      context.read<StockItemInBranchBloc>().add(
        LoadItemsFromBranch(
          widget.authBloc.state.companyId!,
          branchId: branchId,
        ),
      );
    }
  }

  void _addNewRange() {
    setState(() {
      _colorRanges.add(
        LotExpirationColor(
          tempId: DateTime.now().millisecondsSinceEpoch,
          company: widget.authBloc.state.companyId!,
          daysMinimum: null,
          daysMaximum: null,
          colorType: null,
          description: '',
          activeForSalesFlag: 'Y',
        ),
      );
    });
  }

  void _removeRange(LotExpirationColor range) {
    setState(() => _colorRanges.remove(range));
  }

  void _saveColors() {
    if (_formKey.currentState?.validate() != true) return;

    for (final c in _colorRanges) {
      if (c.daysMinimum == null ||
          c.daysMaximum == null ||
          c.colorType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields in all ranges'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (c.daysMaximum! <= c.daysMinimum!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max days must be greater than Min days'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final bloc = context.read<LotExpirationColorsBloc>();

    // Before saving validate that the ranges across this level/scope are consecutive
    // Combine existing ranges in DB for this level/scope with the ranges being saved now
    final existing = bloc.state.items.where((i) {
      if (i.lotExpLevel != _selectedLevel) return false;
      switch (_selectedLevel) {
        case '1':
          return i.branch == null && i.itemNumber == null;
        case '2':
          return i.branch == _selectedBranch && i.itemNumber == null;
        case '3':
          return i.itemNumber == _selectedItem && i.branch == null;
        case '4':
          return i.branch == _selectedBranch && i.itemNumber == _selectedItem;
        default:
          return false;
      }
    }).toList();

    final combined = <LotExpirationColor>[];
    combined.addAll(existing);
    // Add copies of new ranges so tempId differs
    combined.addAll(_colorRanges.map((c) => c.copyWith()));

    bool validateAdjacency(List<LotExpirationColor> colors) {
      if (colors.length <= 1) return true;

      final sortedByMaxDesc = List<LotExpirationColor>.from(colors)
        ..sort((a, b) => (b.daysMaximum ?? 0).compareTo(a.daysMaximum ?? 0));

      for (int i = 0; i < sortedByMaxDesc.length - 1; i++) {
        final prev = sortedByMaxDesc[i];
        final next = sortedByMaxDesc[i + 1];

        final prevMin = prev.daysMinimum;
        final nextMax = next.daysMaximum;

        if (prevMin == null || nextMax == null) return false;

        

        // Enforce adjacency
        if (nextMax != prevMin - 1) return false;
      }

      return true;
    }

    if (!validateAdjacency(combined)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ranges must be consecutive and non-overlapping for the selected level/scope'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final c in _colorRanges) {
      final newColor = c.copyWith(
        lotExpLevel: _selectedLevel,
        branch: _selectedBranch,
        itemNumber: _selectedItem,
        company: widget.authBloc.state.companyId!,
      );

      if (c.id == null) {
        bloc.add(SaveLotExpirationColors(newColor));
      } else {
        bloc.add(UpdateLotExpirationColors(newColor));
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Color configuration saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingColoring != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Lot Coloring' : 'Create Lot Coloring'),
        backgroundColor: const Color(0xFF155888),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.tick_circle),
            onPressed: _saveColors,
            tooltip: 'Save',
          ),
        ],
      ),
      body: BlocListener<LotExpirationColorsBloc, LotExpirationColorsState>(
        listener: (context, state) {
          if (state.status == LotExpirationColorsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Error saving record'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLevelSelectors(),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'Color Ranges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._colorRanges.map(_buildRangeCard),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLevelSelectors() {
    return Column(
      children: [
        CustomDropdown(
          labelText: 'Level *',
          value: _selectedLevel,
          items: const [
            DropdownMenuItem(value: '1', child: Text('Company Level')),
            DropdownMenuItem(value: '2', child: Text('Store Level')),
            DropdownMenuItem(value: '3', child: Text('Item Level')),
            DropdownMenuItem(value: '4', child: Text('Item Store Level')),
          ],
          onChanged: (val) {
            setState(() {
              _selectedLevel = val;
              _selectedBranch = null;
              _selectedItem = null;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_selectedLevel == '2' || _selectedLevel == '4')
          BlocBuilder<BranchBloc, BranchState>(
            builder: (context, state) => CustomDropdown(
              labelText: 'Branch *',
              value: _selectedBranch,
              items: state.branchs
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(b.description ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: _onBranchChanged,
            ),
          ),
        const SizedBox(height: 12),
        if (_selectedLevel == '3' || _selectedLevel == '4')
          _buildItemSelector(),
      ],
    );
  }

  Widget _buildItemSelector() {
    if (_selectedLevel == '3') {
      return BlocBuilder<StockItemEntryBloc, ItemEntryState>(
        builder: (context, state) => CustomDropdown(
          labelText: 'Item *',
          value: _selectedItem,
          items: state.filteredItems
              .map(
                (e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.itemDescription ?? ''),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedItem = val),
        ),
      );
    } else {
      return BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
        builder: (context, state) => CustomDropdown(
          labelText: 'Item *',
          value: _selectedItem,
          items: state.items.map((item) {
            final itemEntryBloc = context.read<StockItemEntryBloc>();
            final itemEntryState = itemEntryBloc.state;
            final itemDescription =
                itemEntryState.items
                    .where((entry) => entry.id == item.itemNumber)
                    .firstOrNull
                    ?.itemDescription ??
                'Item ${item.itemNumber}';

            return DropdownMenuItem<int>(
              value: item.itemNumber,
              child: Text(itemDescription),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedItem = val),
        ),
      );
    }
  }

  Widget _buildRangeCard(LotExpirationColor range) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  labelText: 'Max Days *',
                  keyboardType: TextInputType.number,
                  value: range.daysMaximum?.toString() ?? '',
                  onChanged: (v) => range.daysMaximum = int.tryParse(v),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  suffixIcon:  IconButton(
            icon: const Icon(Iconsax.radar),
            onPressed: _suggestNextRange,
            tooltip: 'Suggest Next',
            color: Color(0xFF155888),
          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  labelText: 'Min Days *',
                  keyboardType: TextInputType.number,
                  value: range.daysMinimum?.toString() ?? '',
                  onChanged: (v) => range.daysMinimum = int.tryParse(v),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
            builder: (context, state) {
              return CustomDropdown<int>(
                value: range.colorType,
                items: state.details
                    .map(
                      (u) => DropdownMenuItem<int>(
                        value: u.id,
                        child: Text(u.description1),
                      ),
                    )
                    .toList(),
                onChanged: (v) => range.colorType = v,
                labelText: 'Color Type *',
                validator: (v) => v == null ? 'Required' : null,
              );
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            labelText: 'Description',
            value: range.description ?? '',
            onChanged: (v) => range.description = v,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: range.activeForSalesFlag == 'Y',
                    onChanged: (v) => setState(
                      () => range.activeForSalesFlag = v == true ? 'Y' : 'N',
                    ),
                  ),
                  const Text('Active'),
                ],
              ),

              IconButton(
                icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                onPressed: () => _removeRange(range),
                tooltip: 'Remove range',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: _saveColors,
        icon: const Icon(Iconsax.tick_circle),
        label: const Text('Save Configuration'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF155888),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
