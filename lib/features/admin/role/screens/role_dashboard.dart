// features/role/screens/role_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_state.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import '../blocs/role_bloc.dart';
import '../blocs/role_event.dart';
import '../../privilege/blocs/privilege_bloc.dart';
import '../../privilege/blocs/privilege_event.dart';

class RoleCreationScreen extends StatefulWidget {
  final AuthBloc authBloc;
  const RoleCreationScreen({super.key, required this.authBloc});

  @override
  State<RoleCreationScreen> createState() => _RoleCreationScreenState();
}

class _RoleCreationScreenState extends State<RoleCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<int> _selectedPrivilegeIds = [];

  @override
  void initState() {
    super.initState();
    // Load available privileges
    context.read<PrivilegeBloc>().add(
      LoadPrivileges(widget.authBloc.state.companyId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Role')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Role Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter role name';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text(
                'Select Privileges:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              BlocBuilder<PrivilegeBloc, PrivilegeState>(
                builder: (context, state) {
                  if (state.status == PrivilegeStatus.loading) {
                    return const CircularProgressIndicator();
                  } else if (state.status == PrivilegeStatus.success) {
                    return _buildPrivilegeSelection(state.privileges);
                  } else {
                    return const Text('Failed to load privileges');
                  }
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createRole,
                child: const Text('Create Role'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivilegeSelection(List<Privilege> privileges) {
    return Column(
      children: privileges
          .map(
            (privilege) => CheckboxListTile(
              title: Text(privilege.name),
              subtitle: Text('${privilege.uri} - ${privilege.description}'),
              value: _selectedPrivilegeIds.contains(privilege.id),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedPrivilegeIds.add(privilege.id);
                  } else {
                    _selectedPrivilegeIds.remove(privilege.id);
                  }
                });
              },
            ),
          )
          .toList(),
    );
  }

  void _createRole() {
    if (_formKey.currentState!.validate()) {
      final roleBloc = context.read<RoleBloc>();

      roleBloc.add(
        CreateRole(
          _nameController.text,
          _descriptionController.text,
          _selectedPrivilegeIds,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role created successfully')),
      );
    }
  }
}
