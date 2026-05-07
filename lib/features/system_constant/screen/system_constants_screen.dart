import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/FSNMR/screens/FSNMR_dashboard.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/core/theme/colors.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/system_constant/widgets/general_setting_tab.dart';
import 'package:savvy_stock/features/system_constant/widgets/report_tab.dart';

class SystemConstantsScreen extends StatefulWidget {
  final AuthBloc authBloc;
  const SystemConstantsScreen({super.key, required this.authBloc});

  @override
  _SystemConstantsScreenState createState() => _SystemConstantsScreenState();
}

class _SystemConstantsScreenState extends State<SystemConstantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  SystemConstant _editedSystemConstant = SystemConstant();
  bool _hasChanges = false;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data when dependencies change (screen becomes visible)
    if (!_initialLoadComplete) {
      _loadInitialData();
      _initialLoadComplete = true;
    }
  }

  void _loadInitialData() {
    // Load UDC data and system constants
    context.read<SystemConstantBloc>().add(
      LoadSystemConstants(widget.authBloc.state.companyId!),
    );
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
        if (!mounted) return;
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
              // Sync button
              if (state.unsyncedCount > 0)
                IconButton(
                  icon: Badge(
                    label: Text(state.unsyncedCount.toString()),
                    child: const Icon(Iconsax.send),
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
                onPressed: () => context.read<SystemConstantBloc>().add(
                  LoadSystemConstants(widget.authBloc.state.companyId!),
                ),
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
              tabs: [
                Tab(
                  icon: Icon(Iconsax.settings, color: Colors.amber),
                  child: Text(
                    'General Settings',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Tab(
                  icon: Icon(Iconsax.document, color: Colors.amber),
                  child: Text(
                    'Report Setup',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                GeneralSettingsTab(
                  onChanged: _handleFieldChange,
                  formKey: _formKey,
                  authBloc: widget.authBloc,
                ),
                FSNMRDashboard(authBloc: widget.authBloc),
              ],
            ),
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
      // RELOAD DATA AFTER SAVE to ensure UI shows latest
      Future.delayed(const Duration(milliseconds: 500), () {
        context.read<SystemConstantBloc>().add(
          LoadSystemConstants(widget.authBloc.state.companyId!),
        );
      });
      setState(() {
        _hasChanges = false;
      });
    }
  }
}
