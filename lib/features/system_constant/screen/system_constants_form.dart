import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

import '../bloc/system_constant_bloc.dart';

class SystemConstantsForm extends StatefulWidget {
  const SystemConstantsForm({super.key});

  @override
  _SystemConstantsFormState createState() => _SystemConstantsFormState();
}

class _SystemConstantsFormState extends State<SystemConstantsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final state = context.read<SystemConstantBloc>().state;
    final systemConstants = state.editItems.isNotEmpty
        ? state.editItems
        : state.createItems;

    for (final systemConstant in systemConstants) {
      _controllers.add(
        TextEditingController(
          text: systemConstant.rateVatPercentage?.toString() ?? '',
        ),
      );
      // Add more controllers for other fields as needed
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SystemConstantBloc, SystemConstantState>(
      listener: (context, state) {
        if (state.status == SystemConstantStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
          Navigator.pop(context);
        } else if (state.status == SystemConstantStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
      },
      builder: (context, state) {
        final systemConstants = state.editItems.isNotEmpty
            ? state.editItems
            : state.createItems;

        if (systemConstants.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No system constants to display')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('System Constants Configuration'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveSystemConstants(context, systemConstants),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildBooleanField(
                      'Apply LOT Management',
                      systemConstants.first.applyLotMgm == 'Y',
                      (value) {
                        // Update all system constants
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) =>
                                  sc.copyWith(applyLotMgm: value ? 'Y' : 'N'),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    _buildBooleanField(
                      'Apply Location Management',
                      systemConstants.first.applyLocationMgm == 'Y',
                      (value) {
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) => sc.copyWith(
                                applyLocationMgm: value ? 'Y' : 'N',
                              ),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    _buildNumberField(
                      'Decimal Places',
                      systemConstants.first.decimalPlaces?.toString() ?? '2',
                      (value) {
                        final decimalPlaces = int.tryParse(value) ?? 2;
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) => sc.copyWith(decimalPlaces: decimalPlaces),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    _buildNumberField(
                      'VAT Percentage',
                      systemConstants.first.rateVatPercentage?.toString() ?? '',
                      (value) {
                        final vatPercentage = double.tryParse(value);
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) =>
                                  sc.copyWith(rateVatPercentage: vatPercentage),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    _buildNumberField(
                      'Withholding Percentage',
                      systemConstants.first.rateWithholdingPercentage
                              ?.toString() ??
                          '',
                      (value) {
                        final withPercentage = double.tryParse(value);
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) => sc.copyWith(
                                rateWithholdingPercentage: withPercentage,
                              ),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    _buildBooleanField(
                      'Auto Generate Barcode',
                      systemConstants.first.generateBarcodeForItem == 'Y',
                      (value) {
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) => sc.copyWith(
                                generateBarcodeForItem: value ? 'Y' : 'N',
                              ),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    _buildBooleanField(
                      'Auto Issue LOT Quantity at Sales',
                      systemConstants.first.lotQtyAutoForSales == 'Y',
                      (value) {
                        final updatedSystemConstants = systemConstants
                            .map(
                              (sc) => sc.copyWith(
                                lotQtyAutoForSales: value ? 'Y' : 'N',
                              ),
                            )
                            .toList();
                        _updateSystemConstants(context, updatedSystemConstants);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          _saveSystemConstants(context, systemConstants),
                      child: const Text('Save Configuration'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooleanField(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final number = double.tryParse(value);
          if (number == null) {
            return 'Please enter a valid number';
          }
          if (number < 0 || number > 100) {
            return 'Value must be between 0 and 100';
          }
        }
        return null;
      },
    );
  }

  void _updateSystemConstants(
    BuildContext context,
    List<SystemConstant> updatedSystemConstants,
  ) {
    if (context.read<SystemConstantBloc>().state.editItems.isNotEmpty) {
      context.read<SystemConstantBloc>().add(
        UpdateSystemConstant(updatedSystemConstants.first),
      );
    } else {
      context.read<SystemConstantBloc>().add(
        CreateSystemConstant(updatedSystemConstants.first),
      );
    }
  }

  void _saveSystemConstants(
    BuildContext context,
    List<SystemConstant> systemConstants,
  ) {
    if (_formKey.currentState!.validate()) {
      if (context.read<SystemConstantBloc>().state.editItems.isNotEmpty) {
        context.read<SystemConstantBloc>().add(SaveInEdit(systemConstants));
      } else {
        context.read<SystemConstantBloc>().add(
          SaveSystemConstants(systemConstants),
        );
      }
    }
  }
}
