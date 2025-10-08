import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';

class BranchDropdown extends StatefulWidget {
  const BranchDropdown({super.key});

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

    // Debug print to see what's happening
    print('Selected Branch ID: $selectedBranchId');
    print('Available branches: ${branchState.branchs.length}');

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
    print('Branch changed to: $newBranchId');

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
