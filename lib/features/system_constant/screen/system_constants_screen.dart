import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_state.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
import 'package:savvy_stock/core/theme/colors.dart';
import 'package:savvy_stock/core/theme/text_styles.dart';
import 'package:savvy_stock/core/widgets/app_button.dart';

class SystemConstantsScreen extends StatefulWidget {
  const SystemConstantsScreen({super.key});

  @override
  _SystemConstantsScreenState createState() => _SystemConstantsScreenState();
}

class _SystemConstantsScreenState extends State<SystemConstantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  SystemConstant _editedSystemConstant = SystemConstant();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SystemConstantBloc, SystemConstantState>(
      listener: (context, state) {
        if (state.status == SystemConstantStatus.success) {
          if (state.systemConstants.isNotEmpty) {
            _editedSystemConstant = state.systemConstants.first.copyWith();
            _hasChanges = false;
          }
        }
      },
      builder: (context, state) {
        if (state.status == SystemConstantStatus.loading &&
            state.systemConstants.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.systemConstants.isNotEmpty &&
            _editedSystemConstant.id == null) {
          _editedSystemConstant = state.systemConstants.first.copyWith();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('System Configuration'),
            actions: [
              if (_hasChanges)
                IconButton(
                  icon: const Icon(Iconsax.refresh),
                  onPressed: _resetChanges,
                  tooltip: 'Reset Changes',
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'General Settings', icon: Icon(Iconsax.settings)),
                Tab(text: 'Report Setup', icon: Icon(Iconsax.document)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              GeneralSettingsTab(
                formKey: _formKey,
                systemConstant: _editedSystemConstant,
                onChanged: _handleFieldChange,
              ),
              const ReportSetupTab(),
            ],
          ),
          floatingActionButton: _hasChanges
              ? FloatingActionButton.extended(
                  onPressed: () => _saveChanges(context),
                  icon: const Icon(Iconsax.save_2),
                  label: const Text('Save Changes'),
                  backgroundColor: AppColors.primary,
                )
              : null,
        );
      },
    );
  }

  void _handleFieldChange(SystemConstant updatedConstant) {
    setState(() {
      _editedSystemConstant = updatedConstant;
      _hasChanges = true;
    });
  }

  void _resetChanges() {
    final currentState = context.read<SystemConstantBloc>().state;
    if (currentState.systemConstants.isNotEmpty) {
      setState(() {
        _editedSystemConstant = currentState.systemConstants.first.copyWith();
        _hasChanges = false;
      });
    }
  }

  void _saveChanges(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SystemConstantBloc>().add(
        UpdateSystemConstant(_editedSystemConstant),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving changes...'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }
}

class GeneralSettingsTab extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final SystemConstant systemConstant;
  final Function(SystemConstant) onChanged;

  const GeneralSettingsTab({
    Key? key,
    required this.formKey,
    required this.systemConstant,
    required this.onChanged,
  }) : super(key: key);

  @override
  _GeneralSettingsTabState createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  late SystemConstant _localSystemConstant;

  @override
  void initState() {
    super.initState();
    _localSystemConstant = widget.systemConstant.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildGeneralConfigurationCard(),
              const SizedBox(height: 20),
              _buildNumberFormattingCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralConfigurationCard() {
    return Container(
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
              value: _localSystemConstant.rateWithPercentage ?? 0.0,
              onChanged: (value) => _updateField(rateWithPercentage: value),
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

  Widget _buildNumberFormattingCard() {
    return Container(
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
                items: const {
                  1: 'Expiration Date',
                  2: 'Effective Date',
                  3: 'Receipt Date',
                  4: 'Production Date',
                  5: 'Manufacturing Date',
                },
                validator: (value) {
                  if (_localSystemConstant.applyLotMgm == 'Y' &&
                      value == null) {
                    return 'Please select a lot type';
                  }
                  return null;
                },
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
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Decimal Places for Display',
              value: _localSystemConstant.decimalPlaces,
              onChanged: (value) => _updateField(decimalPlaces: value),
              items: const {
                0: '0 (e.g., 123)',
                1: '1 (e.g., 123.4)',
                2: '2 (e.g., 123.45)',
                3: '3 (e.g., 123.456)',
                4: '4 (e.g., 123.4567)',
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select decimal places';
                }
                return null;
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
          widget.onChanged(_localSystemConstant);
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
            onChanged: (newValue) {
              onChanged(newValue);
              widget.onChanged(_localSystemConstant);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required Function(T?) onChanged,
    required Map<T, String> items,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
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
      value: value,
      items: items.entries.map((entry) {
        return DropdownMenuItem<T>(
          value: entry.key,
          child: Text(entry.value, style: AppTextStyles.bodyMedium),
        );
      }).toList(),
      validator: validator,
      onChanged: (newValue) {
        onChanged(newValue);
        widget.onChanged(_localSystemConstant);
      },
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  void _updateField({
    double? withHoldInitials,
    double? rateVatPercentage,
    double? rateWithPercentage,
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
        rateWithPercentage: rateWithPercentage,
        applyLotMgm: applyLotMgm,
        lotType: lotType,
        lotQtyAutoForSales: lotQtyAutoForSales,
        autoSalesPrice: autoSalesPrice,
        generateBarcodeForItem: generateBarcodeForItem,
        decimalPlaces: decimalPlaces,
        locationCategoryLevel: locationCategoryLevel,
      );
    });
  }
}

class ReportSetupTab extends StatelessWidget {
  const ReportSetupTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movement Report Setup',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Iconsax.chart_1, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Report Configuration',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fast/Slow/Non-moving rules setup will be implemented here',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton.primary(
                    text: 'Configure Reports',
                    onPressed: () {
                      // TODO: Implement report configuration
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
