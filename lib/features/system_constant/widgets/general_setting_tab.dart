import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/core/theme/colors.dart';
import 'package:savvy_stock/core/theme/text_styles.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class GeneralSettingsTab extends StatefulWidget {
  final Function(SystemConstant)? onChanged;
  final GlobalKey<FormState> formKey;
  final AuthBloc authBloc;

  const GeneralSettingsTab({
    super.key,
    this.onChanged,
    required this.formKey,
    required this.authBloc,
  });

  @override
  _GeneralSettingsTabState createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  SystemConstant _localSystemConstant = SystemConstant();
  bool _isLoading = true;
  bool _isEdititng = false;
  @override
  void initState() {
    super.initState();
    // Load system constants when the tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final companyId = widget.authBloc.state.companyId;
      if (companyId == null) {
        developer.log(
          'companyId is null; skipping LoadSystemConstants until available',
        );
        // Optionally we could listen to the AuthBloc and retry when companyId becomes available.
        return;
      }

      context.read<SystemConstantBloc>().add(LoadSystemConstants(companyId));
      context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('LT'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SystemConstantBloc, SystemConstantState>(
      listener: (context, state) {
        // Update local data when state changes
        if (state.systemConstants.isNotEmpty && _isLoading) {
          setState(() {
            _localSystemConstant = state.systemConstants.first;
            _isLoading = false;
            developer.log(
              'Data loaded from Bloc: ${_localSystemConstant.toJson()}',
            );
          });
        } else if (state.status == SystemConstantStatus.success &&
            state.systemConstants.isNotEmpty) {
          // Update with latest data after save operations
          setState(() {
            _localSystemConstant = state.systemConstants.first;
            _isEdititng = false;
          });
        }
      },
      builder: (context, state) {
        if (_isLoading || state.systemConstants.isEmpty) {
          return const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading system constants...'),
              ],
            ),
          );
        }
        // If we have data but _isLoading is still true, fix it
        if (_isLoading && state.systemConstants.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _localSystemConstant = state.systemConstants.first;
              _isLoading = false;
            });
          });
        }

        // Debug output to see what's happening
        developer.log(
          'UI Building with system constant: ${_localSystemConstant.toJson()}',
        );

        return Form(
          key: widget.formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGeneralConfigurationCard(),
                  const SizedBox(height: 20),
                  _buildNumberFormattingCard(state),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralConfigurationCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Iconsax.briefcase,
              title: 'General Configuration',
            ),
            const SizedBox(height: 20),

            _buildNumberField(
              label: 'Withhold Initial (ETB)',
              value: _localSystemConstant.withHoldInitials ?? 0.0,
              onChanged: (value) => _updateField(withHoldInitials: value),
              suffix: 'ETB',
              min: 0,
              max: 1000000,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Rate Withhold (%)',
              value: _localSystemConstant.rateWithholdingPercentage ?? 0.0,
              onChanged: (value) =>
                  _updateField(rateWithholdingPercentage: value),
              suffix: '%',
              min: 0,
              max: 100,
              isPercentage: true,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'VAT (%)',
              value: _localSystemConstant.rateVatPercentage ?? 0.0,
              onChanged: (value) => _updateField(rateVatPercentage: value),
              suffix: '%',
              min: 0,
              max: 100,
              isPercentage: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberFormattingCard(SystemConstantState state) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Iconsax.setting_4,
              title: 'Number Formatting & Barcodes',
            ),
            const SizedBox(height: 20),
            _buildSwitchTile(
              title: 'Apply Lot Management',
              value: _localSystemConstant.applyLotMgm == 'Y',
              onChanged: (value) =>
                  _updateField(applyLotMgm: value ? 'Y' : 'N'),
            ),
            if (_localSystemConstant.applyLotMgm == 'Y') ...[
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Lot Type',
                value: _localSystemConstant.lotType,
                onChanged: (value) => _updateField(lotType: value),
                context: context,
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Apply Overhead Cost',
                value: _localSystemConstant.applyOverheadCost == 'Y',
                onChanged: (value) =>
                    _updateField(applyOverheadCost: value ? 'Y' : 'N'),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Auto-Issue Lot Quantity at Sales',
                value: _localSystemConstant.lotQtyAutoForSales == 'Y',
                onChanged: (value) =>
                    _updateField(lotQtyAutoForSales: value ? 'Y' : 'N'),
              ),
            ],
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Generate Price using Margin',
              value: _localSystemConstant.autoSalesPrice == 'Y',
              onChanged: (value) =>
                  _updateField(autoSalesPrice: value ? 'Y' : 'N'),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Auto-Generate Barcode',
              value: _localSystemConstant.generateBarcodeForItem == 'Y',
              onChanged: (value) =>
                  _updateField(generateBarcodeForItem: value ? 'Y' : 'N'),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Discount Display',
              value: _localSystemConstant.discountDisplay == 'Y',
              onChanged: (value) =>
                  _updateField(discountDisplay: value ? 'Y' : 'N'),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Tax Info Display',
              value: _localSystemConstant.taxInfoDisplay == 'Y',
              onChanged: (value) =>
                  _updateField(taxInfoDisplay: value ? 'Y' : 'N'),
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Days Left',
              value: _localSystemConstant.daysLeft?.toDouble() ?? 180,
              onChanged: (value) => _updateField(daysLeft: value.toInt()),
              isInteger: true,
              min: 0,
              max: 365,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Currency Code',
              value: _localSystemConstant.currencyCode ?? 'ETB',
              onChanged: (value) => _updateField(currencyCode: value),
            ),
            const SizedBox(height: 16),

            // Reorder Point UOM Type Dropdown
            CustomDropdown<String>(
              // Specify type <String>
              labelText: 'Reorder Point UOM Type',
              prefixIcon: const Icon(Iconsax.setting_4),
              items: [
                DropdownMenuItem(value: 'I', child: Text('Itself')),
                DropdownMenuItem(value: 'D', child: Text('Default')),
              ],
              value: _localSystemConstant.reorderPointUomType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _updateField(reorderPointUomType: value);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Decimal Place Dropdown
            CustomDropdown<String>(
              // Keep as String for display
              labelText: 'Decimal Place',
              prefixIcon: const Icon(Iconsax.setting_4),
              items: [
                '1',
                '2',
                '3',
                '4',
                '5',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              value: _localSystemConstant.decimalPlaces?.toString(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _updateField(
                      decimalPlaces: int.tryParse(value),
                    ); // Convert back to int
                  });
                }
              },
            ),

            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Location Category Level',
              value:
                  _localSystemConstant.locationCategoryLevel?.toDouble() ?? 1.0,
              onChanged: (value) =>
                  _updateField(locationCategoryLevel: value.toInt()),
              min: 1,
              max: 10,
              isInteger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required Function(double) onChanged,
    String? suffix,
    double min = 0,
    double max = 100,
    bool isPercentage = false,
    bool isInteger = false,
  }) {
    return CustomTextField(
      labelText: label,
      value: value.toString(),
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      validator: (value) {
        final numValue = double.tryParse(value ?? '');
        if (numValue == null || numValue < min || numValue > max) {
          return 'Must be between $min and $max';
        }
        return null;
      },
      onChanged: (text) {
        final newValue = double.tryParse(text) ?? min;
        if (newValue >= min && newValue <= max && newValue != value) {
          onChanged(newValue);
          _setEditingState();
        }
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return CustomTextField(
      labelText: label,
      value: value,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field is required';
        }
        return null;
      },
      onChanged: (text) {
        onChanged(text);
        _setEditingState();
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (value) {
              onChanged(value);
              _setEditingState();
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required BuildContext context,
    required String label,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
      builder: (context, state) {
        // Create default options if lotTypes is empty
        developer.log('Lot types: ${state.groupCode}');
        return CustomDropdown<int>(
          labelText: label,
          prefixIcon: const Icon(Iconsax.setting_4),
          items: state.details.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.id,
              child: Text(entry.description1, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          value: value,
          onChanged: (selected) {
            if (selected != null && selected != value) {
              onChanged(selected);
              _setEditingState();
            }
          },
        );
      },
    );
  }

  void _setEditingState() {
    setState(() {
      _isEdititng = true;
    });

    // Notify parent about changes but DON'T save automatically
    if (widget.onChanged != null) {
      widget.onChanged!(_localSystemConstant);
    }
  }

  void _updateField({
    double? withHoldInitials,
    double? rateVatPercentage,
    double? rateWithholdingPercentage,
    String? applyLotMgm,
    String? applyOverheadCost,
    int? lotType,
    String? lotQtyAutoForSales,
    String? autoSalesPrice,
    String? generateBarcodeForItem,
    String? discountDisplay,
    String? taxInfoDisplay,
    int? daysLeft,
    String? currencyCode,
    String? reorderPointUomType,
    int? decimalPlaces,
    int? locationCategoryLevel,
  }) {
    setState(() {
      _localSystemConstant = _localSystemConstant.copyWith(
        withHoldInitials: withHoldInitials,
        rateVatPercentage: rateVatPercentage,
        rateWithholdingPercentage: rateWithholdingPercentage,
        applyLotMgm: applyLotMgm,
        applyOverheadCost: applyOverheadCost,
        lotType: lotType,
        lotQtyAutoForSales: lotQtyAutoForSales,
        autoSalesPrice: autoSalesPrice,
        generateBarcodeForItem: generateBarcodeForItem,
        discountDisplay: discountDisplay,
        taxInfoDisplay: taxInfoDisplay,
        daysLeft: daysLeft,
        currencyCode: currencyCode,
        reorderPointUomType: reorderPointUomType,
        decimalPlaces: decimalPlaces,
        locationCategoryLevel: locationCategoryLevel,
      );
    });

    // Notify parent about changes
    if (widget.onChanged != null) {
      widget.onChanged!(_localSystemConstant);
    }
  }
}
