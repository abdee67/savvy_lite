import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_bloc.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_event.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_state.dart';
import 'package:savvy_stock/features/FSNMR/models/fast_slow_nonmoving_rule.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart'
    hide SaveInEdit;
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class FSNMRCreateAndEditPage extends StatefulWidget {
  final FastSlowNonMovingRule? rule;
  final AuthBloc authBloc;
  final bool isCreateInCreateMode;

  const FSNMRCreateAndEditPage({
    super.key,
    this.rule,
    required this.authBloc,
    this.isCreateInCreateMode = false,
  });

  @override
  State<FSNMRCreateAndEditPage> createState() => _FSNMRCreateAndEditPageState();
}

class _FSNMRCreateAndEditPageState extends State<FSNMRCreateAndEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _periodDaysController = TextEditingController();
  final TextEditingController _fastMovingUnitController =
      TextEditingController();
  final TextEditingController _slowMovingUnitController =
      TextEditingController();
  final TextEditingController _nonMovingUnitController =
      TextEditingController();

  int? _selectedFrequency;
  int? _selectedUom;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Load system constants
    context.read<SystemConstantBloc>().add(
      LoadSystemConstantsForCompany(widget.authBloc.state.companyId!),
    );

    // Load UoM details
    context.read<UdcDetailsBloc>().add(LoadAllUdcDetails());

    // Set up rule form if editing
    if (widget.rule != null) {
      context.read<FSNMRBloc>().add(SetRuleForm(widget.rule!));
    } else if (widget.isCreateInCreateMode) {
      // Prepare for create in create mode
      context.read<FSNMRBloc>().add(PrepareCreateInCreate());
    }
  }

  void _initializeControllers() {
    final rule = widget.rule ?? FastSlowNonMovingRule.empty();

    // Properly handle null values - don't show "null" as text
    _fastMovingUnitController.text =
        rule.fastMovementRuleUnit?.toString() ?? '';
    _nonMovingUnitController.text = rule.nonMovementRuleUnit?.toString() ?? '';
    _slowMovingUnitController.text =
        rule.slowMovementRuleUnit?.toString() ?? '';
    _periodDaysController.text = rule.periodInDays?.toString() ?? '';

    _selectedUom = rule.unitOfMeasureDefault;
    _selectedFrequency = rule.reportFrequency;
  }

  // Helper method for safe number parsing
  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  int? _parseInt(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  @override
  void dispose() {
    _slowMovingUnitController.dispose();
    _nonMovingUnitController.dispose();
    _fastMovingUnitController.dispose();
    _periodDaysController.dispose();
    super.dispose();
  }

  void _saveRule() {
    if (_formKey.currentState!.validate()) {
      final rule = FastSlowNonMovingRule(
        // Use null for new records, or existing id for updates
        id: widget.rule?.id,
        reportFrequency: _selectedFrequency,
        periodInDays: _periodDaysController.text.trim().isEmpty
            ? null
            : _parseInt(_periodDaysController.text),
        fastMovementRuleUnit: _fastMovingUnitController.text.trim().isEmpty
            ? null
            : _parseDouble(_fastMovingUnitController.text),
        slowMovementRuleUnit: _slowMovingUnitController.text.trim().isEmpty
            ? null
            : _parseDouble(_slowMovingUnitController.text),
        nonMovementRuleUnit: _nonMovingUnitController.text.trim().isEmpty
            ? null
            : _parseDouble(_nonMovingUnitController.text),
        unitOfMeasureDefault: _selectedUom,
        company: widget.authBloc.state.companyId,
      );

      // Use SaveInEdit for full Java-equivalent validation:
      // - Duplicate checking by reportFrequency + periodInDays
      // - Change detection before update
      // - Proper success/error messages
      context.read<FSNMRBloc>().add(SaveInEdit(rule));

      _showSuccessDialog();
      context.read<FSNMRBloc>().add(
        LoadRules(widget.authBloc.state.companyId!),
      );
    }
  }

  void _showSuccessDialog() {
    // Get the bloc instance from the current context BEFORE opening the dialog
    final fsnmrBloc = context.read<FSNMRBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        // Share the same bloc instance with the dialog
        value: fsnmrBloc,
        child: BlocListener<FSNMRBloc, FSNMRState>(
          listener: (context, state) {
            if (state.status == FSNMRStatus.success) {
              Navigator.of(dialogContext).pop();
              Navigator.of(dialogContext).pop(true); // Return success
            } else if (state.status == FSNMRStatus.duplication) {
              Navigator.of(dialogContext).pop();
              _showErrorDialog(state.message ?? 'Duplicate rule found');
            } else if (state.status == FSNMRStatus.failure) {
              Navigator.of(dialogContext).pop();
              _showErrorDialog(state.message ?? 'An error occurred');
            }
          },
          child: AlertDialog(
            title: const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Saving...'),
              ],
            ),
            content: const Text('Please wait while we save your rule.'),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? 'Create Rule' : 'Edit Rule'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: widget.rule != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteRule,
                  tooltip: 'Delete Rule',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<FSNMRBloc, FSNMRState>(
              listener: (context, state) {
                if (state.status == FSNMRStatus.success &&
                    state.message?.contains('Saved') == true) {
                  // Success is handled in the dialog
                } else if (state.status == FSNMRStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message ?? 'An error occurred'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            BlocListener<SystemConstantBloc, SystemConstantState>(
              listener: (context, state) {
                if (state.status == SystemConstantStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage ?? 'System constant error',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: Column(
            children: [
              Expanded(child: _buildForm()),
              _buildBottomNavigation(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteRule() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.rule?.id != null) {
                context.read<FSNMRBloc>().add(
                  DeleteRule(
                    ruleId: widget.rule!.id!,
                    deletedRule: widget.rule!,
                    deletedIndex: 0,
                  ),
                );
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Report Frequency(FQ)
            BlocConsumer<UdcDetailsBloc, UdcDetailsState>(
              listener: (context, state) {
                if (state.status == UdcDetailsStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.failure ?? 'System constant error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == UdcDetailsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                //only load 'FQ' group
                final udcList = state.details
                    .where((u) => u.udcGroup == 'FQ')
                    .toList();
                if (udcList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No valid FQ found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Builder(
                  builder: (context) {
                    String? currentFqDesc;
                    if (_selectedFrequency != null) {
                      final match = udcList.where(
                        (u) => u.id == _selectedFrequency,
                      );
                      if (match.isNotEmpty) {
                        currentFqDesc = match.first.description1;
                      }
                    }

                    return CustomSearchableDropdown(
                      labelText: 'Report Frequency(FQ) *',
                      value: currentFqDesc,
                      prefixIcon: Icons.schedule,
                      options: udcList.map((u) => u.description1).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value == null) {
                            _selectedFrequency = null;
                          } else {
                            final matches = udcList.where(
                              (u) => u.description1 == value,
                            );
                            _selectedFrequency = matches.isNotEmpty
                                ? matches.first.id
                                : null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a Report Frequency(FQ)';
                        }
                        return null;
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Period in Days
            CustomTextField(
              labelText: 'Period in Days *',
              controller: _periodDaysController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Period in Days is required';
                }
                return null;
              },
              onChanged: (value) {
                _periodDaysController.text = value;
              },
              prefixIcon: const Icon(Icons.numbers),
            ),
            const SizedBox(height: 16),

            // Unit of Measure
            BlocConsumer<UdcDetailsBloc, UdcDetailsState>(
              listener: (context, state) {
                if (state.status == UdcDetailsStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.failure ?? 'System constant error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == UdcDetailsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                //only load 'UM' group
                final udcList = state.details
                    .where((u) => u.udcGroup == 'UM')
                    .toList();
                if (udcList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No valid UoM found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Builder(
                  builder: (context) {
                    String? currentUomDesc;
                    if (_selectedUom != null) {
                      final match = udcList.where((u) => u.id == _selectedUom);
                      if (match.isNotEmpty) {
                        currentUomDesc = match.first.description1;
                      }
                    }

                    return CustomSearchableDropdown(
                      labelText: 'Unit of Measure *',
                      value: currentUomDesc,
                      prefixIcon: Icons.scale,
                      options: udcList.map((u) => u.description1).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value == null) {
                            _selectedUom = null;
                          } else {
                            final matches = udcList.where(
                              (u) => u.description1 == value,
                            );
                            _selectedUom = matches.isNotEmpty
                                ? matches.first.id
                                : null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a Unit of Measure';
                        }
                        return null;
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Description
            CustomTextField(
              labelText: 'Fast Movement Rule Unit *',
              controller: _fastMovingUnitController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Fast Movement Rule Unit is required';
                }
                return null;
              },
              onChanged: (value) {
                _fastMovingUnitController.text = value;
              },
              prefixIcon: const Icon(Icons.description),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            // Reorder Point
            CustomTextField(
              labelText: 'Slow Moving Rule Unit',
              controller: _slowMovingUnitController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _slowMovingUnitController.text = value;
              },
              prefixIcon: const Icon(Icons.inventory_2),
            ),
            // Unit Price
            CustomTextField(
              labelText: 'Non Moving Rule Unit',
              controller: _nonMovingUnitController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _nonMovingUnitController.text = value;
              },
              prefixIcon: const Icon(Icons.attach_money),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Save button
          BlocBuilder<FSNMRBloc, FSNMRState>(
            builder: (context, state) {
              return ElevatedButton.icon(
                onPressed:
                    state.status == FSNMRStatus.creating ||
                        state.status == FSNMRStatus.updating
                    ? null
                    : _saveRule,
                icon:
                    state.status == FSNMRStatus.creating ||
                        state.status == FSNMRStatus.updating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(
                  state.status == FSNMRStatus.creating ||
                          state.status == FSNMRStatus.updating
                      ? 'Saving...'
                      : 'Save',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155888),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
