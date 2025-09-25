// features/user/screens/user_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';

class UserCreationScreen extends StatefulWidget {
  final Employee? employee;

  const UserCreationScreen({this.employee, super.key});

  @override
  State<UserCreationScreen> createState() => _UserCreationScreenState();
}

class _UserCreationScreenState extends State<UserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeController = TextEditingController();
  final _branchController = TextEditingController();
  final List<int> _selectedRoles = [];

  @override
  void initState() {
    super.initState();
    // Load available roles
    context.read<RoleBloc>().add(LoadRoles(widget.employee?.company ?? 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employee == null
              ? 'Create User'
              : 'Create User for ${widget.employee!.employeeId}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (widget.employee != null) ...[
                ListTile(
                  title: Text(
                    'USER: ${widget.employee!.nameFirst} ${widget.employee!.nameLast}',
                  ),
                  subtitle: Text('ID: ${widget.employee!.employeeId}'),
                ),
                const Divider(),
              ],

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              DropdownButtonFormField<int>(
                initialValue: widget.employee?.id,
                items: context
                    .read<EmployeeBloc>()
                    .state
                    .employees
                    .map(
                      (employee) => DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.nameFirst.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _employeeController.text = value.toString();
                  });
                },
                decoration: const InputDecoration(labelText: 'Employee'),
                validator: (value) {
                  if (value == null || value == 0) {
                    return 'Please select employee';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text(
                'Assign Roles:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              BlocBuilder<RoleBloc, RoleState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const CircularProgressIndicator();
                  } else if (state.isSuccess) {
                    return _buildRoleSelection(state.roles);
                  } else {
                    return const Text('Failed to load roles');
                  }
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createUser,
                child: const Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(List<Role> roles) {
    return Column(
      children: roles
          .map(
            (role) => CheckboxListTile(
              title: Text(role.name),
              subtitle: Text('${role.description}'),
              value: _selectedRoles.contains(role.id),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedRoles.add(role.id);
                  } else {
                    _selectedRoles.remove(role.id);
                  }
                });
              },
            ),
          )
          .toList(),
    );
  }

  void _createUser() {
    if (_formKey.currentState!.validate()) {
      final userBloc = context.read<UserBloc>();
      userBloc.add(
        CreateUser(
          _employeeController.text,
          _usernameController.text,
          _passwordController.text,
          _selectedRoles,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );

      Navigator.pop(context);
    }
  }
}
