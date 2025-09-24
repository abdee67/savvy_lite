// features/user/screens/user_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _emailController = TextEditingController();

  final List<Role> _selectedRoles = [];

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
                    'Employee: ${widget.employee!.nameFirst} ${widget.employee!.nameLast}',
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

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
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
              subtitle: Text(role.description),
              value: _selectedRoles.any((r) => r.id == role.id),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedRoles.add(role);
                  } else {
                    _selectedRoles.removeWhere((r) => r.id == role.id);
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

      // Create user model
      final user = UserModel(
        id: 0, // Will be assigned by database
        userName: _usernameController.text,
        password: _passwordController.text, // Will be hashed in BLoC
        userEmail: _emailController.text,
        employeesId: widget.employee?.id,
        company: widget.employee?.company ?? 1, // Get from current context
        branch: widget.employee?.branch ?? 1,
        status: 'active',
        dateCreated: DateTime.now(),
      );

      userBloc.add(
        CreateUser(user, _selectedRoles.map((role) => role.id).toList(), 1),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );

      Navigator.pop(context);
    }
  }
}
