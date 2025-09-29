import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/employees/widgets/convert_to_user.dart';
import 'package:savvy_stock/features/admin/employees/widgets/emloyee_create_and_edit.dart.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/admin/users/screens/user_dashboard.dart';
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
    final userState = context.watch<UserBloc>().state;
    return userState.users.any(
      (userWithRole) => userWithRole.user.employeesId == employee.id,
    );
  }

  UserWithRole? _getUserForEmployee(Employee employee) {
    final userState = context.read<UserBloc>().state;
    final matches = userState.users.where(
      (u) => u.user.employeesId == employee.id,
    );
    if (matches.isEmpty) return null; // No linked system user
    return matches.first;
  }

  @override
  void initState() {
    super.initState();
    context.read<EmployeeBloc>().add(
      LoadEmployees(widget.authBloc.state.companyId!),
    );
    context.read<UserBloc>().add(LoadUsers(widget.authBloc.state.companyId!));
    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
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
    context.read<EmployeeBloc>().add(ClearRoleSelection());
    setState(() {
      _selectedEmployee = employee;
      _employeeDetail = true;
    });
    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
  }

  void _hideEmployeeDetail() {
    context.read<EmployeeBloc>().add(ClearSelection());
    context.read<EmployeeBloc>().add(ToggleRoleManagement(0));
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
        final isUser = _isEmployeeUser(employee);
        final screenWidth = MediaQuery.of(context).size.width;
        final useCompactLayout = screenWidth < 700;

        return _buildEmployeeListItem(
          employee,
          isSelected,
          state,
          index,
          isUser,
          useCompactLayout,
        );
      },
    );
  }

  Widget _buildEmployeeListItem(
    Employee employee,
    bool isSelected,
    EmployeeState state,
    int index,
    bool isUser,
    bool isCompact,
  ) {
    final offset = _dragOffset[index] ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleEmployeeSelection(employee, !isSelected);
        } else {
          // Single tap shows detail when not in selection mode
          _showEmployeeDetail(employee);
        }
      },
      onLongPress: () {
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
          // Background (delete indicator)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.amber, // Changed to red for delete action
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
          ),

          // Employee card
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
                    ? const Color.fromARGB(255, 28, 66, 146)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildEmployeeAvatar(
                employee,
                isSelected,
                isUser,
                isCompact,
              ),
              title: Text(
                '${employee.nameFirst} ${employee.nameLast}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: _buildEmployeeSubtitle(employee, isUser),
              trailing: _buildEmployeeTrailing(isSelected, isUser),
            ),
          ),
        ],
      ),
    );
  }

  // Separate method for employee avatar
  Widget _buildEmployeeAvatar(
    Employee employee,
    bool isSelected,
    bool isUser,
    bool isCompact,
  ) {
    // Define colors based on user status
    final Color backgroundColor;
    final Color iconColor;

    if (isSelected) {
      backgroundColor = const Color.fromARGB(255, 28, 66, 146);
      iconColor = Colors.white;
    } else if (isUser) {
      backgroundColor = Colors.green;
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.grey[200]!;
      iconColor = Colors.grey[600]!;
    }

    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.profile_circle,
            color: iconColor,
            size: isCompact ? 20 : 24,
          ),
        ),
        // User status badge
        if (isUser)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.verify, size: 12, color: Colors.green),
            ),
          ),
      ],
    );
  }

  // Separate method for employee subtitle
  Widget _buildEmployeeSubtitle(Employee employee, bool isUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show position/title if available
        if (employee.title != null && employee.title!.isNotEmpty)
          Text(
            employee.title!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

        // Contact information
        Text('📞 ${employee.phone}', style: const TextStyle(fontSize: 12)),
        Text(
          '📧 ${employee.email}',
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),

        // User status badge
        if (isUser)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              'System User',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              'Employee Only',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // Separate method for trailing widget
  Widget _buildEmployeeTrailing(bool isSelected, bool isUser) {
    if (isSelected) {
      return const Icon(
        Iconsax.tick_circle,
        color: Color.fromARGB(255, 28, 66, 146),
      );
    }

    // Show user type indicator when not selected
    return Icon(
      isUser ? Iconsax.user : Iconsax.profile_2user,
      color: isUser ? Colors.green : Colors.grey[400],
      size: 20,
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
            child: Builder(
              builder: (context) {
                final size = MediaQuery.of(context).size;
                final screenWidth = size.width;
                final screenHeight = size.height;
                final panelHeight = screenHeight * 0.7; // finite height
                final useHorizontalLayout = screenWidth > 700;
                final useCompactLayout = screenWidth < 700;

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
                        isUser,
                        useCompactLayout,
                      ),

                      // Content Section
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(useCompactLayout ? 12 : 20),
                          child: _buildContentSection(
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

  // Add this new method:
  Widget _buildContentSection(
    Employee employee,
    EmployeeState state,
    bool useHorizontal,
    bool isCompact,
  ) {
    final isUser = _isEmployeeUser(employee);

    if (state.isRoleManagementMode && isUser) {
      // Show role management only for users in role management mode
      return _buildRoleManagementView(
        employee,
        _getUserForEmployee(employee),
        state,
        useHorizontal,
        isCompact,
      );
    } else {
      // Show basic employee info for all employees
      return _buildEmployeeInfoView(employee, state, useHorizontal, isCompact);
    }
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
                              colors: isUser
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

              // Action button - ONLY show role management for users
              if (state.isRoleManagementMode)
                _buildRoleManagementButton(employee, state, isCompact, context)
              else
                _buildMainActionButton(employee, isUser, isCompact, context),

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

  // Separate method for role management button
  Widget _buildRoleManagementButton(
    Employee employee,
    EmployeeState state,
    bool isCompact,
    BuildContext context,
  ) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, userState) {
        if (userState.status == UserStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roles updated successfully')),
          );
          context.read<EmployeeBloc>().add(ToggleRoleManagement(employee.id));
          context.read<EmployeeBloc>().add(ClearRoleSelection());
        }
      },
      builder: (context, userState) {
        final hasChanges = state.hasRoleChanges;

        return ElevatedButton(
          onPressed: userState.isLoading
              ? null
              : () {
                  if (hasChanges) {
                    // Save role changes
                    _saveRoleChanges(employee);
                    context.read<UserBloc>().add(
                      LoadUsers(widget.authBloc.state.companyId!),
                    );
                  } else {
                    // Just go back to info view
                    context.read<EmployeeBloc>().add(
                      ToggleRoleManagement(employee.id),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasChanges ? Colors.amber : Colors.blue,
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
                  hasChanges ? 'Save Changes' : 'Back to Info',
                  style: TextStyle(fontSize: isCompact ? 12 : 14),
                ),
        );
      },
    );
  }

  // Separate method for main action button
  Widget _buildMainActionButton(
    Employee employee,
    bool isUser,
    bool isCompact,
    BuildContext context,
  ) {
    if (isUser) {
      // Employee has user account - show "Show Roles" button
      return ElevatedButton(
        onPressed: () {
          context.read<EmployeeBloc>().add(ToggleRoleManagement(employee.id));
          context.read<UserBloc>().add(
            LoadUsers(widget.authBloc.state.companyId!),
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
        child: Text(
          'Show Roles',
          style: TextStyle(fontSize: isCompact ? 12 : 14),
        ),
      );
    } else {
      // Employee doesn't have user account - show "Convert to User" button
      return ElevatedButton(
        onPressed: () => context.push(
          AppRoutes.userManagement,
          extra: {'employee': employee},
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: 8,
          ),
        ),
        child: Text(
          'Convert to User',
          style: TextStyle(fontSize: isCompact ? 12 : 14),
        ),
      );
    }
  }

  // Helper method for saving role changes
  void _saveRoleChanges(Employee employee) {
    final userWithRole = _getUserForEmployee(employee);
    final state = context.read<EmployeeBloc>().state;
    if (userWithRole?.user.id != null) {
      final currentAssignedRoles = userWithRole!.roles;

      // additions: selected roles not currently assigned
      final additions = state.selectedRolesForAssignment
          .where((r) => !currentAssignedRoles.any((a) => a.id == r.id))
          .map((r) => r.id)
          .toList();

      // removals: selected roles that are currently assigned
      final removals = state.selectedRolesForAssignment
          .where((r) => currentAssignedRoles.any((a) => a.id == r.id))
          .map((r) => r.id)
          .toSet();

      // final = (current - removals) + additions
      final finalRoleIds = [
        ...currentAssignedRoles
            .where((r) => !removals.contains(r.id))
            .map((r) => r.id),
        ...additions,
      ];

      widget.userBloc.add(
        AssignRolesToUser(
          userWithRole.user.id!,
          widget.authBloc.state.companyId!,
          finalRoleIds,
          widget.authBloc.state.userId!,
        ),
      );
    }
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
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, roleState) {
        // Get the SPECIFIC employee's assigned roles
        final assignedRoles = userWithRole?.roles ?? [];

        // Get all available roles in the system
        final allRoles = roleState.roles;

        // Filter to get only roles NOT assigned to this specific employee
        final availableRoles = allRoles
            .where(
              (role) =>
                  !assignedRoles.any((assigned) => assigned.id == role.id),
            )
            .toList();

        // Filter available roles based on search query
        final filteredAvailableRoles = availableRoles
            .where(
              (role) => role.name.toLowerCase().contains(
                roleState.searchQuery.toLowerCase(),
              ),
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
                        context.read<RoleBloc>().add(SearchRoles(query));
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            Expanded(
              child: _buildVerticalRoleManagement(
                assignedRoles,
                filteredAvailableRoles,
                state,
                employee,
                userWithRole,
                isCompact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerticalRoleManagement(
    List<Role> assignedRoles,
    List<Role> availableRoles,
    EmployeeState state,
    Employee employee,
    UserWithRole? userWithRole,
    bool isCompact,
  ) {
    // For the User Roles section: show permanently assigned roles + temporarily selected roles
    final userRolesToShow = [
      ...assignedRoles.where(
        (role) => !state.selectedRolesForAssignment.any(
          (selected) => selected.id == role.id,
        ),
      ),
    ];

    // For the Available Roles section: show available roles excluding temporarily selected ones
    final availableRolesToShow = availableRoles
        .where(
          (role) => !state.selectedRolesForAssignment.any(
            (selected) => selected.id == role.id,
          ),
        )
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRoleSection(
            title: 'Current User Roles',
            roles: userRolesToShow,
            isAssigned: true,
            isCompact: isCompact,
            selectedRoles: state.selectedRolesForAssignment,
            onRoleTap: (role) {
              // Tapping on assigned role: remove it (move to available)
              context.read<EmployeeBloc>().add(SelectRoleForAssignment(role));
            },
          ),
          SizedBox(height: 16),
          _buildRoleSection(
            title: 'Available Roles ',
            roles: availableRolesToShow,
            isAssigned: false,
            isCompact: isCompact,
            selectedRoles: state.selectedRolesForAssignment,
            onRoleTap: (role) {
              // Tapping on available role: select it (will appear in user roles temporarily)
              context.read<EmployeeBloc>().add(SelectRoleForAssignment(role));
            },
          ),

          // Show temporarily selected roles in a separate section or as part of user roles
          if (state.selectedRolesForAssignment.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildRolesToAssignSection(
              roles: state.selectedRolesForAssignment,
              currentAssignedRoles: assignedRoles,
              isCompact: isCompact,
              onRemove: (role) {
                context.read<EmployeeBloc>().add(
                  DeselectRoleForAssignment(role),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRolesToAssignSection({
    required List<Role> roles,
    required List<Role> currentAssignedRoles,
    required bool isCompact,
    required ValueChanged<Role> onRemove,
  }) {
    // Calculate what the final role assignment will look like
    final finalRoles = [
      ...currentAssignedRoles.where(
        (role) => !roles.any((r) => r.id == role.id),
      ),
      ...roles,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(color: Colors.amber[300]!),
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
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isCompact ? 12 : 16),
                topRight: Radius.circular(isCompact ? 12 : 16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.edit,
                  size: isCompact ? 16 : 20,
                  color: Colors.amber[800],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Roles to Assign (${roles.length})',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                      Text(
                        'Final roles: ${finalRoles.length} total',
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          color: Colors.amber[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Roles to assign list
          Container(
            constraints: BoxConstraints(minHeight: isCompact ? 60 : 80),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                final isAdding = !currentAssignedRoles.any(
                  (r) => r.id == role.id,
                );

                return _buildRoleToAssignItem(
                  role: role,
                  isAdding: isAdding,
                  onRemove: () => onRemove(role),
                  isCompact: isCompact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToAssignItem({
    required Role role,
    required bool isAdding,
    required VoidCallback onRemove,
    required bool isCompact,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: isAdding ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdding ? Colors.green[300]! : Colors.orange[300]!,
        ),
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
            color: isAdding ? Colors.green[100]! : Colors.orange[100]!,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAdding ? Iconsax.add_circle : Iconsax.refresh,
            size: isCompact ? 16 : 20,
            color: isAdding ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          role.name,
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: isAdding ? Colors.green[800] : Colors.orange[800],
          ),
        ),
        subtitle: Text(
          isAdding ? 'Adding new role' : 'Replacing existing role',
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            color: isAdding ? Colors.green[600] : Colors.orange[600],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Iconsax.close_circle, size: isCompact ? 16 : 20),
          color: Colors.red,
          onPressed: onRemove,
        ),
        onTap: onRemove,
      ),
    );
  }

  Widget _buildRoleSection({
    required String title,
    required List<Role> roles,
    required bool isAssigned,
    required bool isCompact,
    required List<Role> selectedRoles,
    required ValueChanged<Role> onRoleTap,
  }) {
    // For assigned roles section, show count of permanently assigned + temporarily selected
    final effectiveRoleCount = isAssigned
        ? roles.length + selectedRoles.length
        : roles.length;

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
                  '$title ($effectiveRoleCount)',
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
            child: roles.isEmpty && (!isAssigned || selectedRoles.isEmpty)
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
                        isSelected: isSelected,
                        onRoleTap: () => onRoleTap(role),
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
    required bool isSelected,
  }) {
    Color getBackgroundColor() {
      if (isAssigned) {
        return Color(0xFF10b981).withOpacity(0.1); // Original assigned - green
      }
      if (isSelected) {
        return Colors.amber.withOpacity(0.2); // Selected - amber
      }
      if (isAssigned) {
        return Color(0xFF10b981).withOpacity(0.05); // Assigned but blurred
      }
      return Color(0xFF1e293b).withOpacity(0.8); // Available - blue/black
    }

    Color getTextColor() {
      if (isAssigned) {
        return Color(0xFF10b981); // Original assigned - green
      }
      if (isSelected) {
        return Colors.amber[800]!; // Selected - amber
      }
      return Colors.white; // Available - white
    }

    Color getBorderColor() {
      if (isSelected) {
        return Colors.amber;
      }
      return Colors.transparent;
    }

    String getActionText() {
      if (isAssigned) {
        return 'Tap to remove';
      }
      return 'Tap to assign';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: getBorderColor()),
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
          getActionText(),
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            color: getTextColor().withOpacity(0.7),
          ),
        ),
        onTap: onRoleTap,
        trailing: Icon(
          isAssigned ? Iconsax.arrow_swap_horizontal : Iconsax.add_circle,
          color: Colors.amber,
          size: isCompact ? 16 : 20,
        ),
      ),
    );
  }

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

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
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
