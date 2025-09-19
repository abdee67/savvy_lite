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
        // Show appropriate messages based on state
        if (state.status == SystemConstantStatus.success &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('System Configuration'),
            actions: [
              IconButton(
                icon: Icon(
                  state.isOnline ? Icons.cloud : Icons.cloud_off,
                  color: state.isOnline ? Colors.green : Colors.orange,
                ),
                onPressed: () {
                  if (!state.isOnline) {
                    context.read<SystemConstantBloc>().add(
                      const RetryFailedOperations(),
                    );
                  }
                },
                tooltip: state.isOnline ? 'Online' : 'Offline - Tap to retry',
              ),
              // Sync button
              if (state.unsyncedCount > 0)
                IconButton(
                  icon: Badge(
                    label: Text(state.unsyncedCount.toString()),
                    child: const Icon(Icons.sync),
                  ),
                  onPressed: () {
                    context.read<SystemConstantBloc>().add(
                      const SyncSystemConstants(),
                    );
                  },
                  tooltip: 'Sync changes',
                ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<SystemConstantBloc>().add(
                    const PullSystemConstants(),
                  );
                },
                tooltip: 'Refresh data',
              ),
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
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving system constants...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // Save with offline-first approach
      context.read<SystemConstantBloc>().add(
        SaveInEdit([_editedSystemConstant]),
      );

      // Try to sync immediately
      context.read<SystemConstantBloc>().add(const SyncSystemConstants());
    }
  }
}

class GeneralSettingsTab extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final SystemConstant systemConstant;
  final Function(SystemConstant) onChanged;

  const GeneralSettingsTab({
    super.key,
    required this.formKey,
    required this.systemConstant,
    required this.onChanged,
  });

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
              _buildNumberFormattingCard(
                context.read<SystemConstantBloc>().state,
              ),
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

  Widget _buildNumberFormattingCard(SystemConstantState state) {
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
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Decimal Places for Display',
              value: _localSystemConstant.decimalPlaces,
              onChanged: (value) => _updateField(decimalPlaces: value),
              context: context,
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
    return BlocBuilder<SystemConstantBloc, SystemConstantState>(
      builder: (context, state) {
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
          items: state.lotTypes.entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.key,
              child: Text(entry.value, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        );
      },
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
  const ReportSetupTab({super.key});

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
