// features/stock/location_master/pages/location_master_create_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/branch_dropdown.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/item_pick_list.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/location_code.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import '../blocs/location_master_bloc.dart';
import '../models/location_master_model.dart';

class LocationMasterCreatePage extends StatefulWidget {
  final AuthBloc authBloc;
  final LocationMaster? editingLocation;
  final bool isEditMode;
  const LocationMasterCreatePage({
    super.key,
    required this.authBloc,
    this.editingLocation,
    this.isEditMode = false,
  });

  @override
  State<LocationMasterCreatePage> createState() =>
      _LocationMasterCreatePageState();
}

class _LocationMasterCreatePageState extends State<LocationMasterCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );
  int? _selectedBranch;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
    // Initialize with empty location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationMasterBloc>().add(
        PrepareCreateLocation(
          context.read<LocationMasterBloc>().state.companyId!,
        ),
      );
    });
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Location ' : 'Create Location'),
        backgroundColor: const Color(0xFF155888),
        actions: [
          // Single Save button in AppBar
          BlocBuilder<LocationMasterBloc, LocationMasterState>(
            builder: (context, state) {
              final isSaveEnabled =
                  state.dualListTarget.isNotEmpty && state.selected != null;
              // Determine edit mode from state if not explicitly passed
              final isEditMode =
                  widget.isEditMode || state.selected?.id != null;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                onPressed: isSaveEnabled
                    ? () => _saveLocation(context, state)
                    : isEditMode
                    ? () => _saveLocation(context, state)
                    : null,
                child: Text(
                  isEditMode ? 'Update' : 'Save',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<LocationMasterBloc, LocationMasterState>(
        listener: (context, state) {
          // Show success/error messages
          if (state.status == LocationMasterStatus.success &&
              state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == LocationMasterStatus.failure &&
              state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == LocationMasterStatus.duplication) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
          }

          // Update controllers when selected location changes
          if (state.selected != null) {
            _updateControllers(state.selected!);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Removed LocationToolbar widget
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store and Margin Section
                            _buildStoreAndMarginSection(
                              context,
                              state,
                              widget.isEditMode,
                            ),
                            const SizedBox(height: 16),
                            // Location Codes Section
                            LocationCodeForm(
                              controllers: _codeControllers,
                              onCodeChanged: (index, value) =>
                                  _onCodeChanged(context, index, value),
                              isFieldEnabled: _getFieldEnabledState(
                                state.selected,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Items Pick List Section
                            _buildItemsPickListSection(
                              context,
                              state,
                              widget.isEditMode,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreAndMarginSection(
    BuildContext context,
    LocationMasterState state,
    bool isEditMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditMode ? 'Store Information(Read Only)' : 'Store Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isEditMode ? Colors.grey : null,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              // Store dropdown - full width
              BranchDropdown(isEditMode: isEditMode),
              const SizedBox(height: 16),

              // Margin Type and Rate - Conditionally shown based on system settings
              if (!isEditMode && _shouldShowMarginFields()) ...[
                _buildMarginTypeDropdown(context, state),
                const SizedBox(height: 16),
                _buildMarginRateField(context, state),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarginTypeDropdown(
    BuildContext context,
    LocationMasterState state,
  ) {
    return DropdownButtonFormField<String>(
      isExpanded: true, // Makes the dropdown take full width
      initialValue: state.selected?.marginType,
      decoration: const InputDecoration(
        labelText: 'Margin Type',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Select One')),
        DropdownMenuItem(value: 'F', child: Text('Flat')),
        DropdownMenuItem(value: 'P', child: Text('Percentage')),
      ],
      onChanged: (String? value) {
        final updatedLocation = state.selected?.copyWith(marginType: value);
        if (updatedLocation != null) {
          context.read<LocationMasterBloc>().add(
            SetSelectedLocation(updatedLocation),
          );
        }
      },
    );
  }

  Widget _buildMarginRateField(
    BuildContext context,
    LocationMasterState state,
  ) {
    return CustomTextField(
      value: state.selected?.marginRate?.toString(),
      labelText: 'Margin Rate',
      suffixText: _getMarginRateSuffix(state.selected),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final marginRate = double.tryParse(value);
        final updatedLocation = state.selected?.copyWith(
          marginRate: marginRate,
        );
        if (updatedLocation != null) {
          context.read<LocationMasterBloc>().add(
            SetSelectedLocation(updatedLocation),
          );
        }
      },
    );
  }

  String _getMarginRateSuffix(LocationMaster? location) {
    if (location?.marginRate == null || location?.marginType == null) {
      return '';
    }
    return location?.marginType == 'F' ? 'ETB' : '%';
  }

  Widget _buildItemsPickListSection(
    BuildContext context,
    LocationMasterState state,
    bool isEditMode,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sectionHeight = (screenHeight * 0.6).clamp(400.0, 800.0);

    return SizedBox(
      height: sectionHeight,
      child: Card(
        elevation: 0, // Modern flat look, or use 2 for shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Item Assignment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24), // Visual separation
              Expanded(
                child: ItemsPickList(
                  sourceItems: state.dualListSource,
                  targetItems: state.dualListTarget,
                  authBloc: context.read<AuthBloc>(),
                  onSelectionChanged: (source, target) {
                    context.read<LocationMasterBloc>().add(
                      UpdateDualListModel(source, target),
                    );
                  },
                  isEditMode: isEditMode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowMarginFields() {
    // This would come from your system settings
    // final showMargin = context
    //   .read<SystemConstantBloc>()
    // .state
    //.selected
    //.au;
    return true;
  }

  void _updateControllers(LocationMaster location) {
    final codes = [
      location.code01,
      location.code02,
      location.code03,
      location.code04,
      location.code05,
      location.code06,
      location.code07,
      location.code08,
      location.code09,
      location.code10,
    ];

    for (int i = 0; i < codes.length; i++) {
      if (i < _codeControllers.length) {
        _codeControllers[i].text = codes[i] ?? '';
      }
    }
  }

  List<bool> _getFieldEnabledState(LocationMaster? location) {
    return [
      true, // Code 1 is always enabled
      (location?.code01?.isNotEmpty ?? false),
      (location?.code02?.isNotEmpty ?? false),
      (location?.code03?.isNotEmpty ?? false),
      (location?.code04?.isNotEmpty ?? false),
      (location?.code05?.isNotEmpty ?? false),
      (location?.code06?.isNotEmpty ?? false),
      (location?.code07?.isNotEmpty ?? false),
      (location?.code08?.isNotEmpty ?? false),
      (location?.code09?.isNotEmpty ?? false),
    ];
  }

  void _onCodeChanged(BuildContext context, int index, String value) {
    final state = context.read<LocationMasterBloc>().state;
    final currentLocation = state.selected;

    if (currentLocation != null) {
      LocationMaster updatedLocation;
      switch (index) {
        case 0:
          updatedLocation = currentLocation.copyWith(code01: value);
          break;
        case 1:
          updatedLocation = currentLocation.copyWith(code02: value);
          break;
        case 2:
          updatedLocation = currentLocation.copyWith(code03: value);
          break;
        case 3:
          updatedLocation = currentLocation.copyWith(code04: value);
          break;
        case 4:
          updatedLocation = currentLocation.copyWith(code05: value);
          break;
        case 5:
          updatedLocation = currentLocation.copyWith(code06: value);
          break;
        case 6:
          updatedLocation = currentLocation.copyWith(code07: value);
          break;
        case 7:
          updatedLocation = currentLocation.copyWith(code08: value);
          break;
        case 8:
          updatedLocation = currentLocation.copyWith(code09: value);
          break;
        case 9:
          updatedLocation = currentLocation.copyWith(code10: value);
          break;
        default:
          updatedLocation = currentLocation;
      }

      context.read<LocationMasterBloc>().add(
        SetSelectedLocation(updatedLocation),
      );
    }
  }

  void _saveLocation(BuildContext context, LocationMasterState state) {
    if (_formKey.currentState?.validate() ?? false) {
      if (state.selected != null && state.dualListTarget.isNotEmpty) {
        final isEditMode = widget.isEditMode || state.selected?.id != null;

        if (isEditMode) {
          context.read<LocationMasterBloc>().add(
            UpdateLocationMaster(state.selected!, state.dualListTarget),
          );
        } else {
          context.read<LocationMasterBloc>().add(
            SaveLocationMaster(state.selected!, state.dualListTarget),
          );
        }

        // Listen for success then navigate back or clear for new
        final bloc = context.read<LocationMasterBloc>();
        subscription?.cancel(); // Cancel previous subscription if any
        subscription = bloc.stream.listen((state) {
          if (state.status == LocationMasterStatus.success) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isEditMode) {
                Navigator.of(context).pop();
              } else {
                // Clear form for new entry if it was a create
                context.read<LocationMasterBloc>().add(ClearCreateList());
                context.read<LocationMasterBloc>().add(
                  PrepareCreateLocation(state.companyId!),
                );
                // Clear controllers
                for (var controller in _codeControllers) {
                  controller.clear();
                }
              }
              subscription?.cancel();
            });
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select items to assign to this location'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
