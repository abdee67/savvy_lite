// features/role/screens/role_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_event.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_state.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class RoleFormScreen extends StatefulWidget {
  final AuthBloc authBloc;
  final Role? role; // null for create, provided for edit

  const RoleFormScreen({super.key, required this.authBloc, this.role});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<int> _selectedPrivilegeIds = [];
  String _privilegeSearchQuery = '';

  bool get _isEditMode => widget.role != null;

  @override
  void initState() {
    super.initState();
    _prefillForm();
    context.read<PrivilegeBloc>().add(
      LoadPrivileges(widget.authBloc.state.companyId!),
    );
  }

  void _prefillForm() {
    if (_isEditMode && widget.role != null) {
      _nameController.text = widget.role!.name;
      _descriptionController.text = widget.role!.description;
      _selectedPrivilegeIds.addAll(
        widget.role!.privileges.map((p) => p.id).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Role' : 'Create Role'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Role Information Section
              _buildRoleInfoSection(),
              const SizedBox(height: 24),

              // Privilege Management Section
              _buildPrivilegeManagementSection(),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isEditMode ? Iconsax.user_tag : Iconsax.user_tag,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditMode ? 'Edit Role' : 'Create New Role',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditMode
                        ? 'Update role information and privileges'
                        : 'Add new role to the system',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Role Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Role Name *',
                prefixIcon: Icon(Iconsax.user_tag),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter role name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Iconsax.note_text),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegeManagementSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privilege Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Privilege Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.search_normal,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search privileges...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (query) {
                        setState(() {
                          _privilegeSearchQuery = query;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privilege List
            _buildPrivilegeList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegeList() {
    return BlocBuilder<PrivilegeBloc, PrivilegeState>(
      builder: (context, state) {
        if (state.status == PrivilegeStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == PrivilegeStatus.failure) {
          return const Text('Failed to load privileges');
        }

        final filteredPrivileges = state.privileges
            .where(
              (privilege) =>
                  privilege.name.toLowerCase().contains(
                    _privilegeSearchQuery.toLowerCase(),
                  ) ||
                  privilege.uri.toLowerCase().contains(
                    _privilegeSearchQuery.toLowerCase(),
                  ),
            )
            .toList();

        return Container(
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: filteredPrivileges.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No privileges found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredPrivileges.length,
                  itemBuilder: (context, index) {
                    final privilege = filteredPrivileges[index];
                    final isSelected = _selectedPrivilegeIds.contains(
                      privilege.id,
                    );

                    return _buildPrivilegeListItem(privilege, isSelected);
                  },
                ),
        );
      },
    );
  }

  Widget _buildPrivilegeListItem(Privilege privilege, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.amber[300]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber[100]! : Colors.grey[100]!,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? Iconsax.verify : Iconsax.shield_security,
            size: 20,
            color: isSelected ? Colors.amber[800]! : Colors.grey[600]!,
          ),
        ),
        title: Text(
          privilege.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.amber[800] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              privilege.uri,
              style: TextStyle(
                color: isSelected ? Colors.amber[600] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              privilege.description,
              style: TextStyle(
                color: isSelected ? Colors.amber[600] : Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Icon(
          isSelected ? Iconsax.tick_circle : Iconsax.add_circle,
          color: isSelected ? Colors.amber : Colors.blue,
          size: 20,
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedPrivilegeIds.remove(privilege.id);
            } else {
              _selectedPrivilegeIds.add(privilege.id);
            }
          });
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) {
        return Row(
          children: [
            // Cancel Button
            Expanded(
              child: OutlinedButton(
                onPressed: state.status == RoleStatus.loading
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
                onPressed: state.status == RoleStatus.loading
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 28, 66, 146),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.status == RoleStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Role' : 'Create Role',
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
      final roleBloc = context.read<RoleBloc>();

      if (_isEditMode) {
        // Update existing role
        final updatedRole = widget.role!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
        );
        roleBloc.add(UpdateRole(updatedRole));
        roleBloc.add(
          AssignPrivilegesToRole(updatedRole, _selectedPrivilegeIds),
        );
      } else {
        // Create new role
        roleBloc.add(
          CreateRole(
            _nameController.text,
            _descriptionController.text,
            _selectedPrivilegeIds,
          ),
        );
      }

      // Show success message and navigate back
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
