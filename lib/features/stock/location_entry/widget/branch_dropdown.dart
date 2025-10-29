import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';

class BranchDropdown extends StatefulWidget {
  final bool isEditMode;

  const BranchDropdown({super.key, required this.isEditMode});

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationMasterBloc, LocationMasterState>(
      builder: (context, locationState) {
        return BlocBuilder<BranchBloc, BranchState>(
          builder: (context, branchState) {
            return _buildDropdown(context, locationState, branchState);
          },
        );
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    LocationMasterState locationState,
    BranchState branchState,
  ) {
    if (branchState.status == BranchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (branchState.branchs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No branch available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final selectedLocation = locationState.selected;
    final selectedBranchId = selectedLocation?.branch;

    // Find the selected branch for display
    final selectedBranch = branchState.branchs.firstWhere(
      (branch) => branch.id == selectedBranchId,
      orElse: () => Branch.empty(),
    );

    // In edit mode, show a disabled field with the branch name
    if (widget.isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store*',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
              color:
                  Colors.grey.shade100, // Grey background to indicate disabled
            ),
            child: Row(
              children: [
                const Icon(Icons.store, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedBranch.description ?? 'Unknown Branch',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey, // Grey text to indicate disabled
                    ),
                  ),
                ),
                const Icon(Icons.lock, color: Colors.grey, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Branch cannot be changed in edit mode',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // Create mode - normal dropdown
    return CustomDropdown<int>(
      value: selectedBranchId,
      labelText: 'Store*',
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Select One')),
        ...branchState.branchs.map((branch) {
          return DropdownMenuItem<int>(
            value: branch.id,
            child: Text(branch.description ?? 'Branch ${branch.id}'),
          );
        }),
      ],
      onChanged: (int? newBranchId) {
        _handleBranchChange(context, locationState, newBranchId);
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a store';
        }
        return null;
      },
    );
  }

  void _handleBranchChange(
    BuildContext context,
    LocationMasterState locationState,
    int? newBranchId,
  ) {
    final currentLocation = locationState.selected;
    final companyId = locationState.companyId;

    if (newBranchId != null) {
      // Load items for the selected branch
      context.read<LocationMasterBloc>().add(LoadItemsForBranch(newBranchId));

      // Update or create location with the new branch
      LocationMaster updatedLocation;

      if (currentLocation != null) {
        // Update existing location
        updatedLocation = currentLocation.copyWith(branch: newBranchId);
      } else {
        // Create new location
        updatedLocation = LocationMaster(
          branch: newBranchId,
          company: companyId,
          validCell: true,
          tempId: _generateTempId(locationState.createItems),
        );
      }

      context.read<LocationMasterBloc>().add(
        SetSelectedLocation(updatedLocation),
      );

      // If this is a new location, also add it to createItems
      if (currentLocation == null) {
        context.read<LocationMasterBloc>().add(
          AddToCreateList(updatedLocation),
        );
      }
    } else {
      // Branch was cleared
      if (currentLocation != null) {
        final updatedLocation = currentLocation.copyWith(branch: null);
        context.read<LocationMasterBloc>().add(
          SetSelectedLocation(updatedLocation),
        );
      }
    }
  }

  int _generateTempId(List<LocationMaster> createItems) {
    if (createItems.isEmpty) return 1;
    final maxTempId = createItems
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }
}
