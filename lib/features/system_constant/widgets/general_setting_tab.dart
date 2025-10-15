import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_state.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
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
      context.read<SystemConstantBloc>().add(
        LoadSystemConstants(widget.authBloc.state.companyId!),
      );
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
              label: 'VAT (%)',
              value: _localSystemConstant.rateVatPercentage ?? 0.0,
              onChanged: (value) => _updateField(rateVatPercentage: value),
              suffix: '%',
              min: 0,
              max: 100,
              isPercentage: true,
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
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      initialValue: value.toString(),
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
        if (newValue >= min && newValue <= max) {
          onChanged(newValue);
          _setEditingState();
        }
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
        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          initialValue: value,
          items: state.details.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.id,
              child: Text(entry.description1, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: (value) {
            onChanged(value);
            _setEditingState();
          },
          onSaved: (value) => _setEditingState(),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
    int? lotType,
    String? lotQtyAutoForSales,
    String? autoSalesPrice,
    String? generateBarcodeForItem,
    int? decimalPlaces,
    int? locationCategoryLevel,
  }) {
    setState(() {
      _localSystemConstant = _localSystemConstant.copyWith(
        withHoldInitials: withHoldInitials,
        rateVatPercentage: rateVatPercentage,
        rateWithholdingPercentage: rateWithholdingPercentage,
        applyLotMgm: applyLotMgm,
        lotType: lotType,
        lotQtyAutoForSales: lotQtyAutoForSales,
        autoSalesPrice: autoSalesPrice,
        generateBarcodeForItem: generateBarcodeForItem,
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
