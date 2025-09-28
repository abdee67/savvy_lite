import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/employees/widgets/convert_to_user.dart';
import 'package:savvy_stock/features/admin/employees/widgets/emloyee_create_and_edit.dart.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class EmployeeListPage extends StatefulWidget {
  final AuthBloc authBloc;
  final UserBloc userBloc;
  const EmployeeListPage({
    super.key,
    required this.authBloc,
    required this.userBloc,
  });

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};
  Employee? _selectedEmployee;
  bool _employeeDetail = false;

  bool _isEmployeeUser(Employee employee) {
    final userState = context.read<UserBloc>().state;
    return userState.users.any(
      (userWithRole) => userWithRole.user.employeesId == employee.id,
    );
  }

  UserWithRole? _getUserForEmployee(Employee employee) {
    final userState = context.read<UserBloc>().state;
    return userState.users.firstWhere(
      (userWithRole) => userWithRole.user.employeesId == employee.id,
      orElse: () => UserWithRole(user: UserModel.empty(), roles: []),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<EmployeeBloc>().add(
      LoadEmployees(widget.authBloc.state.companyId!),
    );
    context.read<UserBloc>().add(LoadUsers(widget.authBloc.state.companyId!));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<EmployeeBloc>().add(SearchEmployees(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<EmployeeBloc>().add(SearchEmployees(''));
  }

  void _toggleEmployeeSelection(Employee employee, bool selected) {
    context.read<EmployeeBloc>().add(SelectEmployee(employee, selected));
  }

  void _showEmployeeDetail(Employee employee) {
    setState(() {
      _selectedEmployee = employee;
      _employeeDetail = true;
    });
  }

  void _hideEmployeeDetail() {
    setState(() {
      _employeeDetail = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _selectedEmployee = null;
          });
        }
      });
    });
  }

  void _clearSelection() {
    context.read<EmployeeBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _callEmployee(String phone) {
    // Implement phone call functionality
    print('Calling: $phone');
  }

  void _emailEmployee(String? email) {
    if (email != null) {
      // Implement email functionality
      print('Emailing: $email');
    }
  }

  void _exportEmployee(Employee employee) {
    context.read<EmployeeBloc>().add(ExportSingleEmployee(employee));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Employee data exported')));
  }

  void _safeDeleteEmployee(BuildContext context, {int? index}) {
    final bloc = context.read<EmployeeBloc>();
    final state = bloc.state;

    // CASE 1: Multiple employees
    if (state.selectedEmployees.isNotEmpty) {
      final employeesToDelete = state.selectedEmployees;

      showDeleteDialog(
        context,
        title: 'Delete selected employees?',
        content:
            'Are you sure you want to delete ${employeesToDelete.length} employees?',
        onConfirm: () {
          final ids = employeesToDelete.map((e) => e.id).toList();
          final deletedIndexes = employeesToDelete
              .map((emp) => state.employees.indexOf(emp))
              .toList();
          bloc.add(
            DeleteSelectedEmployees(
              selectedEmployees: ids,
              deletedEmployees: employeesToDelete,
              deletedIndexes: deletedIndexes,
            ),
          );
        },
      );
      return;
    }

    // CASE 2: Single employee by index
    if (index == null || index < 0 || index >= state.filteredEmployees.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final employeeToDelete = state.filteredEmployees[index];

    showDeleteDialog(
      context,
      title: 'Delete "${employeeToDelete.nameFirst}"?',
      content:
          'Are you sure you want to delete "${employeeToDelete.nameFirst}"?',
      onConfirm: () {
        bloc.add(
          DeleteEmployee(
            deletedEmployee: employeeToDelete,
            deletedIndex: index,
            employeeId: employeeToDelete.id,
          ),
        );
      },
    );
  }

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;

      // only allow left swipe
      if (newOffset > 0) newOffset = 0;
      _dragOffset[index] = newOffset;
    });
  }

  void _onHorizontalDragEnd(
    BuildContext context,
    int index,
    DragEndDetails details,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3; // ✅ 30% of screen width
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -screenWidth; // slide fully left
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _safeDeleteEmployee(context, index: index);
        setState(() {
          _dragOffset.remove(index);
        });
      });
    } else {
      // Not far enough → snap back
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Employee List')),
      body: BlocConsumer<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (state.employees.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.employees.isEmpty && _isSelectionMode) {
            setState(() {
              _isSelectionMode = false;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  // Header with Search and Actions
                  _buildSearchBar(),
                  _buildActionButtons(state),
                  // Employee List
                  Expanded(child: _buildEmployeeList(state)),
                ],
              ),

              // Detail Panel
              if (_employeeDetail && _selectedEmployee != null)
                _buildDetailPanel(_selectedEmployee!),
            ],
          );
        },
      ),

      // Floating Action Button for Add
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or email...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _handleSearch,
      ),
    );
  }

  Widget _buildActionButtons(EmployeeState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: state.hasSelection
          ? Row(
              children: [
                Text(
                  '${state.selectedEmployees.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (state.canDelete)
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: () => _safeDeleteEmployee(context),
                    tooltip: 'Delete selected',
                  ),
                if (state.canEdit)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final employee = state.selectedEmployees.first;
                      _navigateToEditScreen(employee);
                    },
                    tooltip: 'Edit employee',
                  ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => _clearSelection(),
                  tooltip: 'Clear selection',
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      builder: (context, state) {
        return FloatingActionButton(
          onPressed: () {
            if (state.canEdit) {
              // Navigate to edit screen with selected employee
              final employee = state.employees.first;
              _navigateToEditScreen(employee);
            } else {
              // Navigate to add screen
              _navigateToAddScreen();
            }
          },
          backgroundColor: Color.fromARGB(255, 28, 66, 146),
          child: Icon(
            state.canEdit ? Icons.edit : Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildEmployeeList(EmployeeState state) {
    if (state.status == EmployeeStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == EmployeeStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Failed to load employees',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<EmployeeBloc>().add(
                LoadEmployees(widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.people, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No employees found'
                  : 'No results for "${state.searchQuery}"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = state.filteredEmployees[index];
        final isSelected = state.selectedEmployees.contains(employee);

        return _buildEmployeeListItem(employee, isSelected, state, index);
      },
    );
  }

  Widget _buildEmployeeListItem(
    Employee employee,
    bool isSelected,
    EmployeeState state,
    int index,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          // In selection mode, single tap toggles selection
          _toggleEmployeeSelection(employee, !isSelected);
        }
      },
      onLongPress: () {
        // Long press enters selection mode and toggles this item
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleEmployeeSelection(employee, !isSelected);
      },
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
      onDoubleTap: () => _showEmployeeDetail(employee),
      child: Stack(
        children: [
          // 🔴 Background (delete indicator)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(offset, 0, 0),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isSelected
                    ? Color.fromARGB(255, 28, 66, 146)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 28, 66, 146)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.profile_circle,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              title: Text(
                employee.nameFirst,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact: ${employee.nameFirst}'),
                  Text('Phone: ${employee.phone}'),
                  Text('Email: ${employee.email}'),
                ],
              ),
              trailing: isSelected
                  ? const Icon(
                      Iconsax.tick_circle,
                      color: Color.fromARGB(255, 28, 66, 146),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(Employee employee) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<EmployeeBloc>()),
        BlocProvider.value(value: widget.userBloc), // Use the passed UserBloc
      ],
      child: BlocConsumer<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (state.status == EmployeeStatus.success && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final isUser = _isEmployeeUser(employee);
          final userWithRole = _getUserForEmployee(employee);
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final panelHeight = screenHeight * 0.7.clamp(0.5, 0.8);
                final useHorizontalLayout = screenWidth > 600;
                final useCompactLayout = screenWidth < 400;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: panelHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey[50]!],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 32,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Section
                      _buildDetailHeader(
                        employee,
                        state,
                        userWithRole,
                        useCompactLayout,
                        useHorizontalLayout,
                      ),

                      // Content Section
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(useCompactLayout ? 12 : 20),
                          child: state.isRoleManagementMode
                              ? _buildRoleManagementView(
                                  employee,
                                  userWithRole,
                                  state,
                                  useHorizontalLayout,
                                  useCompactLayout,
                                )
                              : _buildEmployeeInfoView(
                                  employee,
                                  state,
                                  useHorizontalLayout,
                                  useCompactLayout,
                                ),
                        ),
                      ),

                      // Footer Actions
                      // if (!state.isRoleManagementMode)
                      //  _buildDetailFooter(employee, useCompactLayout),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailHeader(
    Employee employee,
    EmployeeState state,
    UserWithRole? userWithRole,
    bool isUser,
    bool isCompact,
  ) {
    final roleNames =
        userWithRole?.roles.map((r) => r.name).join(', ') ?? 'No roles';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: isCompact ? 40 : 60,
            height: 4,
            margin: EdgeInsets.only(bottom: isCompact ? 4 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Row(
            children: [
              // Avatar and basic info
              Expanded(
                child: Row(
                  children: [
                    // Avatar with user status indicator
                    Stack(
                      children: [
                        Container(
                          width: isCompact ? 40 : 50,
                          height: isCompact ? 40 : 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: employee.isUser
                                  ? [Color(0xFF10b981), Color(0xFF059669)]
                                  : [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${employee.nameFirst[0]}${employee.nameLast[0]}',
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (isUser)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: isCompact ? 12 : 16,
                              height: isCompact ? 12 : 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.check,
                                size: isCompact ? 8 : 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(width: isCompact ? 8 : 12),

                    // Name and user status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${employee.nameFirst} ${employee.nameLast}',
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isUser ? 'System User' : 'Employee Only',
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 14,
                              color: isUser ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              if (state.isRoleManagementMode)
                BlocConsumer<UserBloc, UserState>(
                  listener: (context, userState) {
                    if (userState.status == UserStatus.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Roles updated successfully'),
                        ),
                      );
                      context.read<EmployeeBloc>().add(
                        ToggleRoleManagement(employee.id),
                      );
                    }
                  },
                  builder: (context, userState) {
                    return ElevatedButton(
                      onPressed: userState.isLoading
                          ? null
                          : () {
                              // Save will be handled by the role assignment in the body
                              context.read<EmployeeBloc>().add(
                                ToggleRoleManagement(employee.id),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: 8,
                        ),
                      ),
                      child: userState.isLoading
                          ? SizedBox(
                              width: isCompact ? 16 : 20,
                              height: isCompact ? 16 : 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Back to Info',
                              style: TextStyle(fontSize: isCompact ? 12 : 14),
                            ),
                    );
                  },
                )
              else
                ElevatedButton(
                  onPressed: employee.isUser
                      ? () => context.read<EmployeeBloc>().add(
                          ToggleRoleManagement(employee.id),
                        )
                      : () => _showConvertToUserDialog(employee),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: employee.isUser
                        ? Colors.blue
                        : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    employee.isUser ? 'Show Roles' : 'Convert to User',
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ),

              SizedBox(width: 8),

              // Close button
              Container(
                width: isCompact ? 32 : 36,
                height: isCompact ? 32 : 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close, size: isCompact ? 16 : 18),
                  onPressed: _hideEmployeeDetail,
                  padding: EdgeInsets.zero,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfoView(
    Employee employee,
    EmployeeState state,
    bool useHorizontal,
    bool isCompact,
  ) {
    if (useHorizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information
          Expanded(
            child: _buildInfoSection(
              title: 'Personal Information',
              icon: Iconsax.profile_circle,
              color: Color(0xFF667eea),
              isCompact: isCompact,
              children: [
                _buildInfoItem(
                  'Employee ID',
                  employee.employeeId ?? 'N/A',
                  Iconsax.card,
                  isCompact,
                ),
                _buildInfoItem(
                  'First Name',
                  employee.nameFirst,
                  Iconsax.user,
                  isCompact,
                ),
                _buildInfoItem(
                  'Last Name',
                  employee.nameLast,
                  Iconsax.user,
                  isCompact,
                ),
                if (employee.nameMiddle.isNotEmpty)
                  _buildInfoItem(
                    'Middle Name',
                    employee.nameMiddle,
                    Iconsax.user,
                    isCompact,
                  ),
                _buildInfoItem(
                  'Gender',
                  employee.gender ?? 'Not specified',
                  Iconsax.people,
                  isCompact,
                ),
                _buildInfoItem(
                  'Birth Date',
                  _formatDate(employee.birthDate),
                  Iconsax.calendar,
                  isCompact,
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 12 : 20),
          // Contact Information
          Expanded(
            child: _buildInfoSection(
              title: 'Contact Information',
              icon: Iconsax.call,
              color: Color(0xFFf093fb),
              isCompact: isCompact,
              children: [
                _buildInfoItem('Email', employee.email, Iconsax.sms, isCompact),
                _buildInfoItem(
                  'Phone',
                  employee.phone,
                  Iconsax.call,
                  isCompact,
                ),
                _buildInfoItem(
                  'Country',
                  employee.country ?? 'Ethiopia',
                  Iconsax.location,
                  isCompact,
                ),
                _buildInfoItem(
                  'City',
                  employee.city ?? 'N/A',
                  Iconsax.buildings,
                  isCompact,
                ),
                _buildInfoItem(
                  'Address',
                  employee.address ?? 'N/A',
                  Iconsax.home,
                  isCompact,
                ),
                _buildInfoItem(
                  'Hire Date',
                  _formatDate(employee.hireDate),
                  Iconsax.calendar_1,
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoSection(
              title: 'Employee Information',
              icon: Iconsax.profile_circle,
              color: Color(0xFF667eea),
              isCompact: isCompact,
              children: [
                _buildInfoItem(
                  'Employee ID',
                  employee.employeeId ?? 'N/A',
                  Iconsax.card,
                  isCompact,
                ),
                _buildInfoItem(
                  'First Name',
                  employee.nameFirst,
                  Iconsax.user,
                  isCompact,
                ),
                _buildInfoItem(
                  'Last Name',
                  employee.nameLast,
                  Iconsax.user,
                  isCompact,
                ),
                if (employee.nameMiddle.isNotEmpty)
                  _buildInfoItem(
                    'Middle Name',
                    employee.nameMiddle,
                    Iconsax.user,
                    isCompact,
                  ),
                _buildInfoItem('Email', employee.email, Iconsax.sms, isCompact),
                _buildInfoItem(
                  'Phone',
                  employee.phone,
                  Iconsax.call,
                  isCompact,
                ),
                _buildInfoItem(
                  'Hire Date',
                  _formatDate(employee.hireDate),
                  Iconsax.calendar_1,
                  isCompact,
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRoleManagementView(
    Employee employee,
    UserWithRole? userWithRole,
    EmployeeState state,
    bool useHorizontal,
    bool isCompact,
  ) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final assignedRoles = userWithRole?.roles ?? [];
        final allRoles =
            userState.users?.roles ??
            []; // You'll need to load roles in UserBloc
        final availableRoles = allRoles
            .where(
              (role) =>
                  !assignedRoles.any((assigned) => assigned.id == role.id),
            )
            .toList();
        return Column(
          children: [
            // Search bar for roles
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.search_normal,
                    size: isCompact ? 16 : 20,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search roles...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (query) {
                        context.read<EmployeeBloc>().add(SearchRoles(query));
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            Expanded(
              child: useHorizontal
                  ? _buildHorizontalRoleManagement(
                      assignedRoles,
                      availableRoles,
                      state,
                      employee,
                      isCompact,
                    )
                  : _buildVerticalRoleManagement(
                      assignedRoles,
                      availableRoles,
                      state,
                      isCompact,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalRoleManagement(
    List<Role> assignedRoles,
    List<Role> availableRoles,
    EmployeeState state,
    Employee employee,
    bool isCompact,
  ) {
    final filteredAvailableRoles = availableRoles
        .where(
          (role) =>
              role.name.toLowerCase().contains(state.searchQuery.toLowerCase()),
        )
        .toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assigned Roles
        Expanded(
          child: _buildRoleSection(
            title: 'User Roles (${assignedRoles.length})',
            roles: assignedRoles,
            isAssigned: true,
            isCompact: isCompact,
          ),
        ),
        SizedBox(width: isCompact ? 12 : 20),
        // Available Roles
        Expanded(
          child: _buildRoleSection(
            title: 'Available Roles (${filteredAvailableRoles.length})',
            roles: filteredAvailableRoles,
            isAssigned: false,
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalRoleManagement(
    List<Role> assignedRoles,
    List<Role> availableRoles,
    EmployeeState state,
    bool isCompact,
  ) {
    final filteredAvailableRoles = availableRoles
        .where(
          (role) =>
              role.name.toLowerCase().contains(state.searchQuery.toLowerCase()),
        )
        .toList();
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRoleSection(
            title: 'User Roles (${assignedRoles.length})',
            roles: assignedRoles,
            isAssigned: true,
            isCompact: isCompact,
          ),
          SizedBox(height: 16),
          _buildRoleSection(
            title: 'Available Roles (${filteredAvailableRoles.length})',
            roles: filteredAvailableRoles,
            isAssigned: false,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  void _assignRoleToUser(Employee employee, Role role) {
    final userWithRole = _getUserForEmployee(employee);
    if (userWithRole != null) {
      final currentRoleIds = userWithRole.roles.map((r) => r.id).toList();
      final newRoleIds = [...currentRoleIds, role.id];

      context.read<UserBloc>().add(
        AssignRolesToUser(
          userWithRole.user.id!,
          newRoleIds,
          widget.authBloc.state.userId!,
          widget.authBloc.state.companyId!,
        ),
      );
    }
  }

  Widget _buildRoleSection({
    required String title,
    required List<Role> roles,
    required bool isAssigned,
    required bool isCompact,
    List<Role> selectedRoles = const [],
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: isAssigned
                  ? Color(0xFF10b981).withOpacity(0.1)
                  : Color(0xFF3b82f6).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isCompact ? 12 : 16),
                topRight: Radius.circular(isCompact ? 12 : 16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAssigned ? Iconsax.verify : Iconsax.add_circle,
                  size: isCompact ? 16 : 20,
                  color: isAssigned ? Color(0xFF10b981) : Color(0xFF3b82f6),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isAssigned ? Color(0xFF10b981) : Color(0xFF3b82f6),
                  ),
                ),
              ],
            ),
          ),
          // Roles list
          Container(
            constraints: BoxConstraints(minHeight: isCompact ? 120 : 200),
            child: roles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        isAssigned ? 'No roles assigned' : 'No available roles',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      final isSelected = selectedRoles.any(
                        (r) => r.id == role.id,
                      );

                      return _buildRoleItem(
                        role: role,
                        isAssigned: isAssigned,
                        onRoleTap: () => onRoleTap?.call(role),
                        isCompact: isCompact,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem({
    required Role role,
    required bool isAssigned,
    VoidCallback? onRoleTap,
    required bool isCompact,
  }) {
    Color getBackgroundColor() {
      if (isAssigned) return Color(0xFF10b981).withOpacity(0.05);
      return Color(0xFF1e293b).withOpacity(0.8);
    }

    Color getTextColor() {
      if (isAssigned) return Color(0xFF10b981);
      return Colors.white;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: 4,
        ),
        leading: Container(
          width: isCompact ? 32 : 40,
          height: isCompact ? 32 : 40,
          decoration: BoxDecoration(
            color: getTextColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAssigned ? Iconsax.verify : Iconsax.user_tag,
            size: isCompact ? 16 : 20,
            color: getTextColor(),
          ),
        ),
        title: Text(
          role.name,
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: getTextColor(),
          ),
        ),
        subtitle: Text(
          role.description,
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            color: getTextColor().withOpacity(0.7),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: isAssigned ? null : onRoleTap,
        trailing: isAssigned
            ? Icon(Iconsax.add_circle, color: Colors.green)
            : Icon(Iconsax.add_circle, color: Colors.red),
      ),
    );
  }

  // Add the convert to user dialog method
  void _showConvertToUserDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => ConvertToUserDialog(
        employee: employee,
        userBloc: widget.userBloc,
        authBloc: widget.authBloc,
      ),
    );
  }

  // Keep your existing _buildInfoSection, _buildInfoItem, _buildDetailFooter methods
  // ... (they remain the same as in previous implementation)
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isCompact,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    bool isCompact,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, size: 20),
            color: color,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 12,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _navigateToAddScreen() {
    // Navigate to add employee screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<EmployeeBloc>(),
          child: const EmployeeFormPage(),
        ),
      ),
    );
  }

  void _navigateToEditScreen(Employee employee) {
    // Navigate to edit employee screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<EmployeeBloc>(),
          child: EmployeeFormPage(employee: employee),
        ),
      ),
    );
  }
}
