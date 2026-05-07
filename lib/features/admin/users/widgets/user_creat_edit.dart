import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';

class UserManagementScreen extends StatefulWidget {
  final Employee? employee; // For employee conversion
  final Branch? branch;
  final UserWithRole? user; // For user editing
  final AuthBloc authBloc;

  const UserManagementScreen({
    super.key,
    this.employee,
    this.branch,
    this.user,
    required this.authBloc,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _refrenceIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _branchController = TextEditingController();

  // Role management
  final List<Role> _selectedRoles = [];
  final List<Role> _currentUserRoles = [];
  String _roleSearchQuery = '';

  // Employee selection for create mode
  int? _selectedEmployeeId;
  int? _selectBranchId;

  // Mode detection
  bool get _isEditMode => widget.user != null;
  bool get _isConversionMode => widget.employee != null;
  bool get _isCreateMode => !_isEditMode && !_isConversionMode;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _prefillForm();
  }

  void _initializeData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<RoleBloc>().add(LoadRoles(companyId));
      context.read<UserBloc>().add(LoadUsers(companyId));
      if (_isCreateMode) {
        context.read<EmployeeBloc>().add(LoadEmployees(companyId));
        context.read<BranchBloc>().add(LoadBranchs(companyId));
      }
    }
  }

  void _prefillForm() {
    if (_isEditMode && widget.user != null) {
      final user = widget.user!.user;
      _usernameController.text = user.userName ?? '';
      _emailController.text = user.userEmail ?? '';
      _currentUserRoles.addAll(widget.user!.roles);
      _selectBranchId = user.branch;
    } else if (_isConversionMode && widget.employee != null) {
      _selectedEmployeeId = widget.employee!.id;
      _emailController.text = widget.employee!.email;
      _usernameController.text = _generateUsername(widget.employee!);
    }
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _emailController.clear();
    _branchController.clear();
    _selectedRoles.clear();
    _roleSearchQuery = '';
    _selectedEmployeeId = null;
    _selectBranchId = null;
  }

  String _generateUsername(Employee employee) {
    final firstName = employee.nameFirst.toLowerCase();
    final lastName = employee.nameLast.toLowerCase();
    return '${firstName[0]}$lastName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<UserBloc, UserState>(
              listener: (context, state) {
                if (state.status == UserStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message ?? 'Operation failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state.status == UserStatus.success &&
                    state.message?.isNotEmpty == true) {
                  _showSuccessDialog();
                }
              },
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // User Information Section
                  _buildUserInfoSection(),
                  const SizedBox(height: 24),

                  // Role Management Section
                  _buildRoleManagementSection(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // Employee Selection (only for create mode)
            if (_isCreateMode)
              BlocBuilder<EmployeeBloc, EmployeeState>(
                builder: (context, state) {
                  if (state.employees.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No employees available for user creation',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Safe employee list with null check
                  final employees = state.employees
                      .where((e) => e != null)
                      .toList();
                  if (employees.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No valid employees found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return CustomDropdown<int>(
                    labelText: 'Employee *',
                    prefixIcon: const Icon(Iconsax.profile_circle),
                    value: _selectedEmployeeId,
                    items: employees.map((employee) {
                      return DropdownMenuItem(
                        value: employee.id,
                        child: Text(
                          '${employee.nameFirst} ${employee.nameLast}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                      });
                      if (value != null) {
                        final employee = _findEmployeeById(employees, value);
                        if (employee != null) {
                          _emailController.text = employee.email;
                          _usernameController.text = _generateUsername(
                            employee,
                          );
                        }
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an employee';
                      }
                      return null;
                    },
                  );
                },
              ),
            const SizedBox(height: 16),

            // Username
            CustomTextField(
              value: _usernameController.text,
              onChanged: (value) {
                setState(() {
                  _usernameController.text = value;
                });
              },
              labelText: 'Username *',
              prefixIcon: const Icon(Iconsax.user),
              inputFormatters: [LengthLimitingTextInputFormatter(45)],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                if (value.length > 45) {
                  return 'Username must be 45 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username
            CustomTextField(
              value: _refrenceIdController.text,
              onChanged: (value) {
                setState(() {
                  _refrenceIdController.text = value;
                });
              },
              labelText: 'Refrence id *',
              prefixIcon: const Icon(Iconsax.user_octagon),
              inputFormatters: [LengthLimitingTextInputFormatter(45)],
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter refrence id';
                }

                if (value.length > 45) {
                  return 'Reference ID must be 45 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            CustomTextField(
              value: _emailController.text,
              onChanged: (value) {
                setState(() {
                  _emailController.text = value;
                });
              },
              labelText: 'Email *',
              prefixIcon: const Icon(Iconsax.sms),
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (value.length > 100) {
                  return 'Email must be 100 characters or less';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Branch
            BlocBuilder<BranchBloc, BranchState>(
              builder: (context, state) {
                if (state.branchs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No branch available for user creation',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                final branch = state.branchs.toList();
                if (branch.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No valid branch found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return CustomDropdown<int>(
                  labelText: 'Branch *',
                  prefixIcon: const Icon(Iconsax.profile_circle),
                  value: _selectBranchId,
                  items: branch
                      .map(
                        (branch) => DropdownMenuItem(
                          value: branch.id,
                          child: Text('${branch.description}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectBranchId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an branch';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Password (only for create/conversion)
            if (!_isEditMode)
              Column(
                children: [
                  CustomTextField(
                    value: _passwordController.text,
                    onChanged: (value) {
                      setState(() {
                        _passwordController.text = value;
                      });
                    },
                    obscureText: true,
                    prefixIcon: const Icon(Iconsax.lock),
                    labelText: 'Password *',
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
                  const SizedBox(height: 16),
                  CustomTextField(
                    value: _confirmPasswordController.text,
                    onChanged: (value) {
                      setState(() {
                        _confirmPasswordController.text = value;
                      });
                    },
                    obscureText: true,
                    prefixIcon: const Icon(Iconsax.lock),
                    labelText: 'Confirm Password *',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Column(
                children: [
                  CustomTextField(
                    value: _passwordController.text,
                    onChanged: (value) {
                      setState(() {
                        _passwordController.text = value;
                      });
                    },
                    obscureText: true,
                    prefixIcon: const Icon(Iconsax.lock),
                    labelText: 'New Password (optional)',
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Leave password field empty to keep the current password',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Role Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.search_normal, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search roles...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (query) {
                    setState(() {
                      _roleSearchQuery = query;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Role Management based on mode
        if (_isEditMode)
          _buildEditModeRoleManagement()
        else
          _buildCreateModeRoleManagement(),
      ],
    );
  }

  Widget _buildEditModeRoleManagement() {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, roleState) {
        if (roleState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (roleState.isSuccess) {
          // Safe role list with null check
          final allRoles = roleState.roles.where((r) => r != null).toList();

          // Calculate available roles (all roles minus current user roles)
          final availableRoles = allRoles
              .where(
                (role) => !_currentUserRoles.any(
                  (userRole) => userRole.id == role.id,
                ),
              )
              .where(
                (role) => role.name.toLowerCase().contains(
                  _roleSearchQuery.toLowerCase(),
                ),
              )
              .toList();

          // Filter current user roles by search
          final filteredCurrentRoles = _currentUserRoles
              .where((role) => role != null)
              .where(
                (role) => role.name.toLowerCase().contains(
                  _roleSearchQuery.toLowerCase(),
                ),
              )
              .toList();

          return Column(
            children: [
              // Current User Roles
              _buildRoleSection(
                title: 'Current Roles (${filteredCurrentRoles.length})',
                roles: filteredCurrentRoles,
                isCurrent: true,
                onRoleTap: (role) {
                  setState(() {
                    _currentUserRoles.remove(role);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Available Roles
              _buildRoleSection(
                title: 'Available Roles (${availableRoles.length})',
                roles: availableRoles,
                isCurrent: false,
                onRoleTap: (role) {
                  setState(() {
                    if (!_currentUserRoles.any((r) => r.id == role.id)) {
                      _currentUserRoles.add(role);
                    }
                  });
                },
              ),
            ],
          );
        }

        return const Text('Failed to load roles');
      },
    );
  }

  Widget _buildCreateModeRoleManagement() {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, roleState) {
        if (roleState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (roleState.isSuccess) {
          // Safe role list with null check
          final allRoles = roleState.roles.where((r) => r != null).toList();
          final filteredRoles = allRoles
              .where(
                (role) => role.name.toLowerCase().contains(
                  _roleSearchQuery.toLowerCase(),
                ),
              )
              .toList();

          return _buildRoleSection(
            title: 'Assign Roles (${filteredRoles.length})',
            roles: filteredRoles,
            isCurrent: false,
            onRoleTap: (role) {
              setState(() {
                if (_selectedRoles.any((r) => r.id == role.id)) {
                  _selectedRoles.removeWhere((r) => r.id == role.id);
                } else {
                  _selectedRoles.add(role);
                }
              });
            },
            selectedRoles: _selectedRoles,
          );
        }

        return const Text('Failed to load roles');
      },
    );
  }

  Widget _buildRoleSection({
    required String title,
    required List<Role> roles,
    required bool isCurrent,
    required Function(Role) onRoleTap,
    List<Role> selectedRoles = const [],
  }) {
    // Safe roles list
    final safeRoles = roles.where((r) => r != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              isCurrent ? Iconsax.verify : Iconsax.user_tag,
              size: 20,
              color: isCurrent ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.green[800] : Colors.blue[800],
              ),
            ),
          ],
        ),

        // Roles List
        Container(
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
          child: safeRoles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No roles found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: safeRoles.length,
                  itemBuilder: (context, index) {
                    final role = safeRoles[index];
                    final isSelected = selectedRoles.any(
                      (r) => r.id == role.id,
                    );

                    return _buildRoleListItem(
                      role: role,
                      isCurrent: isCurrent,
                      isSelected: isSelected,
                      onTap: () => onRoleTap(role),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoleListItem({
    required Role role,
    required bool isCurrent,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.green[50]
            : isSelected
            ? Colors.amber[50]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? Colors.green[200]!
              : isSelected
              ? Colors.amber[300]!
              : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.green[100]!
                : isSelected
                ? Colors.amber[100]!
                : Colors.grey[100]!,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCurrent ? Iconsax.verify : Iconsax.user_tag,
            size: 20,
            color: isCurrent
                ? Colors.green
                : isSelected
                ? Colors.amber[800]!
                : Colors.grey[600]!,
          ),
        ),
        title: Text(
          role.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isCurrent
                ? Colors.green[800]
                : isSelected
                ? Colors.amber[800]
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          role.description,
          style: TextStyle(
            color: isCurrent
                ? Colors.green[600]
                : isSelected
                ? Colors.amber[600]
                : Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          isCurrent ? Iconsax.trash : Iconsax.add_circle,
          color: isCurrent ? Colors.red : Colors.blue,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Row(
          children: [
            // Cancel Button
            Expanded(
              child: OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),

            // Submit Button
            Expanded(
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 28, 66, 146),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _getSubmitButtonText(),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final userBloc = context.read<UserBloc>();
      final companyId = widget.authBloc.state.companyId!;
      final createdBy = widget.authBloc.state.userId!.id;

      if (_isEditMode) {
        // Update existing user
        final updatedUser = widget.user!.user.copyWith(
          userName: _usernameController.text,
          employeesId: int.parse(_refrenceIdController.text),
          userEmail: _emailController.text,
          branch: _selectBranchId,
          updatedBy: createdBy,
          dateUpdated: DateTime.now(),
        );
        // Only include password in the update if it was explicitly changed
        String? passwordToUpdate;
        if (_passwordController.text.isNotEmpty) {
          passwordToUpdate = _passwordController.text;
        }
        // Use UpdateUser event which handles both user update and role assignment
        userBloc.add(
          UpdateUser(updatedUser, _currentUserRoles, passwordToUpdate),
        );
      } else {
        // Create new user or convert employee
        int employeeId;
        if (_isConversionMode) {
          employeeId = widget.employee!.id;
        } else {
          // For create mode, get employee ID from dropdown
          if (_selectedEmployeeId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select an employee'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          employeeId = _selectedEmployeeId!;
        }

        final user = UserModel(
          id: 0,
          password: _passwordController.text,
          userName: _usernameController.text,
          userEmail: _emailController.text,
          branch: _selectBranchId,
          employeesId: employeeId,
          company: companyId,
          createdBy: createdBy,
          dateCreated: DateTime.now(),
          type: 'Company',
        );

        userBloc.add(CreateUser(user, _selectedRoles));
      }
    }
  }

  Employee? _findEmployeeById(List<Employee> employees, int id) {
    try {
      return employees.firstWhere((employee) => employee.id == id);
    } catch (e) {
      // Return null if employee not found instead of throwing
      return null;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(_getSuccessMessage()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper methods for text content
  String _getAppBarTitle() {
    if (_isEditMode) return 'Edit User';
    if (_isConversionMode) return 'Convert to User';
    return 'Create User';
  }

  String _getHeaderTitle() {
    if (_isEditMode) return 'Edit User Account';
    if (_isConversionMode) return 'Convert Employee to User';
    return 'Create New User';
  }

  String _getHeaderSubtitle() {
    if (_isEditMode) return 'Update user information and roles';
    if (_isConversionMode) return 'Create system access for employee';
    return 'Add new user to the system';
  }

  String _getSubmitButtonText() {
    if (_isEditMode) return 'Update User';
    if (_isConversionMode) return 'Convert to User';
    return 'Create User';
  }

  String _getSuccessMessage() {
    if (_isEditMode) return 'User updated successfully';
    if (_isConversionMode) return 'Employee converted to user successfully';
    return 'User created successfully';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _branchController.dispose();
    super.dispose();
  }
}
