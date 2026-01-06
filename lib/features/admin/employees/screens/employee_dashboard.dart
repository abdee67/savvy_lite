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
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/admin/role/blocs/role_state.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
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

class _EmployeeListPageState extends State<EmployeeListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};
  Employee? _selectedEmployee;
  bool _employeeDetail = false;

  // Animation controllers
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isEmployeeUser(Employee employee) {
    final userState = context.watch<UserBloc>().state;
    return userState.usersWithRole.any(
      (userWithRole) => userWithRole.user.employeesId == employee.id,
    );
  }

  UserWithRole? _getUserForEmployee(Employee employee) {
    final userState = context.read<UserBloc>().state;
    final matchingUsers = userState.usersWithRole.where(
      (userWithRole) => userWithRole.user.employeesId == employee.id,
    );
    if (matchingUsers.isEmpty) return null; // No linked system user
    return matchingUsers.first;
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Set up animations
    _setupAnimations();

    context.read<EmployeeBloc>().add(
      LoadEmployees(widget.authBloc.state.companyId!),
    );
    context.read<UserBloc>().add(LoadUsers(widget.authBloc.state.companyId!));
    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
  }

  void _setupAnimations() {
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _detailAnimationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _detailAnimationController.dispose();
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

    // Start the animation
    _detailAnimationController.forward(from: 0.0);

    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
  }

  void _hideEmployeeDetail() {
    context.read<EmployeeBloc>().add(ClearSelection());
    context.read<EmployeeBloc>().add(ToggleRoleManagement(0));

    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _employeeDetail = false;
          _selectedEmployee = null;
        });
      }
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
      backgroundColor: Colors.grey,
      appBar: AppBar(title: const Text('Employee List')),
      body: SafeArea(
        child: BlocConsumer<EmployeeBloc, EmployeeState>(
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 12),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EmployeeState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey,
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
                      context.push(
                        AppRoutes.employeeEdit,
                        extra: {'employee': employee},
                      );
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
        return ElevatedButton(
          onPressed: () {
            if (state.canEdit) {
              // Navigate to edit screen with selected employee
              final employee = state.selectedEmployees.first;
              context.push(
                AppRoutes.employeeEdit,
                extra: {'employee': employee},
              );
            } else {
              // Navigate to add screen
              context.push(AppRoutes.employeeCreation);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: Icon(
            state.canEdit ? Icons.edit : Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildEmployeeList(EmployeeState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

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

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: const BoxDecoration(color: Colors.grey),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.filteredEmployees.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final employee = state.filteredEmployees[index];
          final isSelected = state.selectedEmployees.contains(employee);
          final isUser = _isEmployeeUser(employee);

          return _buildEmployeeListItem(
            employee,
            isSelected,
            state,
            index,
            isUser,
            isSmallScreen,
            cardWidth,
          );
        },
      ),
    );
  }

  Widget _buildEmployeeListItem(
    Employee employee,
    bool isSelected,
    EmployeeState state,
    int index,
    bool isUser,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _employeeDetail == true && _selectedEmployee == employee;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight *
              0.2 // phones
        : screenHeight * 0.12; // tablets / wide screens

    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleEmployeeSelection(employee, !isSelected);
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
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) => Container(
          transform: Matrix4.translationValues(offset, 0, 0),
          width: collapsedWidth,
          height: isExpanded ? expandedHeight : collapsedHeight,
          child: Stack(
            children: [
              // 1. DELETE INDICATOR - Should be FIRST in Stack
              if (!isExpanded) // Only show delete indicator when not expanded
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.amber, // Changed to red for delete
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 2),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

              // 2. BACKGROUND LAYERS (only when expanded)
              if (isExpanded) ...[
                // Yellow background
                Positioned.fill(
                  top: 47,
                  child: Container(
                    width: collapsedWidth,
                    height: expandedHeight,
                    decoration: ShapeDecoration(
                      color: state.isRoleManagementMode
                          ? Colors.white
                          : const Color(0xFFFDD105), // Fixed yellow color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],

              // 3. EMPLOYEE CARD - Should come AFTER delete indicator
              AnimatedContainer(
                padding: const EdgeInsets.only(top: 4, left: 10, right: 10),
                width: collapsedWidth,
                height: collapsedHeight,
                duration: const Duration(milliseconds: 400),
                transform: Matrix4.translationValues(offset, 0, 0),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  borderRadius: BorderRadius.circular(30),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Avatar
                        Container(
                          margin: const EdgeInsets.only(top: 20, right: 12),
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
                            size: isCompact ? 20 : 24,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.fullName,
                                style: TextStyle(
                                  color: const Color(0xFF373737),
                                  fontSize: isCompact ? 20 : 24,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                employee.phone,
                                style: TextStyle(
                                  color: const Color(0xFF887F7F),
                                  fontSize: isCompact ? 12 : 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              _buildEmployeeSubtitle(employee, isUser),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // See More / See Less / Role / Main Action logic
                        Row(
                          children: [
                            if (isExpanded) ...[
                              if (state.isRoleManagementMode)
                                _buildRoleManagementButton(
                                  employee,
                                  state,
                                  isCompact,
                                  context,
                                )
                              else
                                _buildMainActionButton(
                                  employee,
                                  isUser,
                                  isCompact,
                                  context,
                                ),
                              const SizedBox(width: 10),
                            ],
                            ElevatedButton(
                              onPressed: () => isExpanded
                                  ? _hideEmployeeDetail()
                                  : _showEmployeeDetail(employee),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF145888),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                isExpanded ? 'See Less' : 'See More',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 10 : 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. ANIMATED EXPANDED CONTENT
              if (isExpanded)
                Positioned(
                  top: collapsedHeight + 10,
                  left: 20,
                  right: 20,
                  child: AnimatedBuilder(
                    animation: _detailAnimationController,
                    builder: (context, child) {
                      final currentHeight =
                          _heightAnimation.value *
                          (expandedHeight - collapsedHeight - 20);
                      final currentOpacity = _opacityAnimation.value;

                      return SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          height: currentHeight > 0 ? currentHeight : 0,
                          decoration: BoxDecoration(color: Colors.transparent),
                          child: Opacity(opacity: currentOpacity, child: child),
                        ),
                      );
                    },
                    child: MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<EmployeeBloc>()),
                        BlocProvider.value(value: widget.userBloc),
                      ],
                      child: BlocBuilder<UserBloc, UserState>(
                        builder: (context, userState) {
                          return BlocConsumer<EmployeeBloc, EmployeeState>(
                            listener: (context, state) {
                              if (state.status == EmployeeStatus.success &&
                                  state.message != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.message!)),
                                );
                              }
                            },
                            builder: (context, state) {
                              return _buildContentSection(
                                employee,
                                state,
                                !isCompact, // useHorizontalLayout
                                isCompact,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Separate method for employee subtitle
  Widget _buildEmployeeSubtitle(Employee employee, bool isUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  // Separate method for role management button
  Widget _buildRoleManagementButton(
    Employee employee,
    EmployeeState state,
    bool isCompact,
    BuildContext context,
  ) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, userState) {
        if (userState.status == UserStatus.success &&
            (userState.message?.toLowerCase().contains('role') == true)) {
          // Roles were updated successfully
          context.read<EmployeeBloc>().add(ToggleRoleManagement(0));
          context.read<EmployeeBloc>().add(ClearRoleSelection());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Roles updated successfully'),
              backgroundColor: Color(0xFF145888),
            ),
          );
        }
      },
      builder: (context, userState) {
        final hasChanges = state.selectedRolesForAssignment.isNotEmpty;

        return ElevatedButton(
          onPressed: userState.isLoading
              ? null
              : () {
                  if (hasChanges) {
                    // Save role changes
                    _saveRoleChanges(employee);
                  } else {
                    // Just go back to info view
                    context.read<EmployeeBloc>().add(
                      ToggleRoleManagement(employee.id),
                    );
                    context.read<EmployeeBloc>().add(ClearRoleSelection());
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasChanges ? Colors.amber : Color(0xFF145888),
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
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF145888),
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
          AppRoutes.employeeConversionToUser,
          extra: {'employee': employee},
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF145888),
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

  // Alternative simplified version
  void _saveRoleChanges(Employee employee) {
    final userWithRole = _getUserForEmployee(employee);
    final state = context.read<EmployeeBloc>().state;

    // Validate inputs
    if (userWithRole?.user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user account found for this employee'),
        ),
      );
      return;
    }

    if (state.selectedRolesForAssignment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one role')),
      );
      return;
    }
    // Calculate final roles: current assigned roles + selected roles (toggle logic)
    final currentAssignedRoles = userWithRole?.roles ?? [];
    final selectedRoles = state.selectedRolesForAssignment;

    // Toggle logic: if role was assigned, remove it; if not assigned, add it
    final finalRoles = <Role>[];

    // Start with currently assigned roles
    for (final assignedRole in currentAssignedRoles) {
      // Keep role if it's NOT in selected roles (not toggled for removal)
      if (!selectedRoles.any((selected) => selected.id == assignedRole.id)) {
        finalRoles.add(assignedRole);
      }
    }

    // Add roles that are selected but not currently assigned
    for (final selectedRole in selectedRoles) {
      if (!currentAssignedRoles.any(
        (assigned) => assigned.id == selectedRole.id,
      )) {
        finalRoles.add(selectedRole);
      }
    }

    // Extract role IDs
    widget.userBloc.add(
      AssignRolesToUser(
        userWithRole!.user.id,
        widget.authBloc.state.companyId!,
        finalRoles,
        widget.authBloc.state.userId!.id,
      ),
    );
    // Clear selection and exit role management mode
    context.read<EmployeeBloc>().add(ClearRoleSelection());
    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
    context.read<UserBloc>().add(LoadUsers(widget.authBloc.state.companyId!));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role changes saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildEmployeeInfoView(
    Employee employee,
    EmployeeState state,
    bool useHorizontal,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Column(
            children: [
              _buildInfoItem(
                'ID : ',
                employee.id.toString(),
                Iconsax.card,
                isCompact,
              ),
              _buildInfoItem(
                'Employee ID : ',
                employee.employeeId ?? 'N/A',
                Iconsax.card,
                isCompact,
              ),
              _buildInfoItem(
                'First Name : ',
                employee.nameFirst,
                Iconsax.user,
                isCompact,
              ),
              _buildInfoItem(
                'Last Name : ',
                employee.nameLast,
                Iconsax.user,
                isCompact,
              ),
              if (employee.nameMiddle.isNotEmpty)
                _buildInfoItem(
                  'Middle Name : ',
                  employee.nameMiddle,
                  Iconsax.user,
                  isCompact,
                ),
              _buildInfoItem(
                'Email : ',
                employee.email,
                Iconsax.sms,
                isCompact,
              ),
              _buildInfoItem(
                'Phone : ',
                employee.phone,
                Iconsax.call,
                isCompact,
              ),
              _buildInfoItem(
                'Hire Date : ',
                _formatDate(employee.hireDate),
                Iconsax.calendar_1,
                isCompact,
              ),
              // Action buttons row
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      Iconsax.call,
                      'Call',
                      () => _callEmployee(employee.phone ?? ''),
                      isCompact,
                    ),
                    _buildActionButton(
                      Iconsax.sms,
                      'Email',
                      () => _emailEmployee(employee.email ?? ''),
                      isCompact,
                    ),
                    _buildActionButton(
                      Iconsax.export,
                      'Export',
                      () => _exportEmployee(employee),
                      isCompact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isCompact,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: isCompact ? 20 : 24),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF145888),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: const Color(0xFF373737),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Replace your entire _buildRoleManagementView method with this:
  Widget _buildRoleManagementView(
    Employee employee,
    UserWithRole? userWithRole,
    EmployeeState state,
    bool useHorizontal,
    bool isCompact,
  ) {
    return BlocConsumer<RoleBloc, RoleState>(
      listener: (context, roleState) {
        // Handle role state changes if needed
      },
      builder: (context, roleState) {
        if (roleState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (roleState.isFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Failed to load roles: ${roleState.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Get current assigned roles from fresh UserBloc state
        return BlocConsumer<UserBloc, UserState>(
          builder: (context, userState) {
            // Get fresh user data for this employee
            final freshUserWithRole = userState.usersWithRole
                .where(
                  (userWithRole) =>
                      userWithRole.user.employeesId == employee.id,
                )
                .firstOrNull;

            // Get current assigned roles from fresh data
            final currentAssignedRoles = freshUserWithRole?.roles ?? [];

            final currentAssignedRoleIds = currentAssignedRoles
                .map((r) => r.id)
                .toSet();

            final selectedRoleIds = state.selectedRolesForAssignment
                .map((r) => r.id)
                .toSet();

            bool willBeAssigned(Role role) {
              final isCurrentlyAssigned = currentAssignedRoleIds.contains(
                role.id,
              );
              final isToggled = selectedRoleIds.contains(role.id);
              return isToggled ? !isCurrentlyAssigned : isCurrentlyAssigned;
            }

            final allRoles = roleState.roles;
            final assignedRoles = allRoles.where(willBeAssigned).toList();
            final availableRoles = allRoles
                .where((r) => !willBeAssigned(r))
                .toList();

            return _buildSimpleRoleManagement(
              assignedRoles,
              availableRoles,
              employee,
              freshUserWithRole,
              state,
              isCompact,
            );
          },
          listener: (context, userState) {
            // Handle user state changes if needed
          },
        );
      },
    );
  }

  Widget _buildSimpleRoleManagement(
    List<Role> assignedRoles,
    List<Role> availableRoles,
    Employee employee,
    UserWithRole? userWithRole,
    EmployeeState state,
    bool isCompact,
  ) {
    return Column(
      children: [
        // Search bar
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Assigned Roles Section
                _buildRoleSection(
                  title: 'Assigned Roles',
                  roles: assignedRoles,
                  isAssigned: true,
                  isCompact: isCompact,
                  selectedRoles: state.selectedRolesForAssignment,
                  onRoleTap: (role) {
                    // Remove role from assigned (will be unassigned on save)
                    context.read<EmployeeBloc>().add(
                      SelectRoleForAssignment(role),
                    );
                  },
                ),

                const SizedBox(height: 6),
                _buildRoleSearchBar(isCompact),
                const SizedBox(height: 6),

                // Available Roles Section
                _buildRoleSection(
                  title: 'Available Roles',
                  roles: availableRoles,
                  isAssigned: false,
                  isCompact: isCompact,
                  selectedRoles: state.selectedRolesForAssignment,
                  onRoleTap: (role) {
                    // Add role to selected (will be assigned on save)
                    context.read<EmployeeBloc>().add(
                      SelectRoleForAssignment(role),
                    );
                  },
                ),

                // Selected Roles Preview (roles to be changed)
                if (state.selectedRolesForAssignment.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSelectedRolesPreview(
                    state.selectedRolesForAssignment,
                    userWithRole?.roles ?? const [],
                    isCompact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSearchBar(bool isCompact) {
    return Container(
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
                context.read<RoleBloc>().add(SearchRoles(query));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRolesPreview(
    List<Role> selectedRoles,
    List<Role> currentAssignedRoles,
    bool isCompact,
  ) {
    // Calculate what will happen to each role
    final rolesToAdd = selectedRoles
        .where((role) => !currentAssignedRoles.any((r) => r.id == role.id))
        .toList();

    final rolesToRemove = selectedRoles
        .where((role) => currentAssignedRoles.any((r) => r.id == role.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Iconsax.info_circle, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Text(
              'Changes to Save (${selectedRoles.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                fontSize: 14,
              ),
            ),
          ],
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roles to Add - Dynamic wrapping
              if (rolesToAdd.isNotEmpty) ...[
                Text(
                  'Adding (${rolesToAdd.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDynamicRolesWrap(rolesToAdd, true, isCompact),
                const SizedBox(height: 12),
              ],

              // Roles to Remove - Dynamic wrapping
              if (rolesToRemove.isNotEmpty) ...[
                Text(
                  'Removing (${rolesToRemove.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDynamicRolesWrap(rolesToRemove, false, isCompact),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Dynamic wrapping based on available width
  Widget _buildDynamicRolesWrap(
    List<Role> roles,
    bool isAdding,
    bool isCompact,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate items per row based on screen width
    int getItemsPerRow() {
      if (screenWidth < 400) return 2; // Very small screens: 2 per row
      if (screenWidth < 600) return 3; // Small screens: 3 per row
      if (screenWidth < 900) return 4; // Medium screens: 4 per row
      return 5; // Large screens: 5 per row
    }

    final itemsPerRow = getItemsPerRow();
    final itemWidth =
        (screenWidth - 48 - (8 * (itemsPerRow - 1))) / itemsPerRow;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: roles.map((role) {
        return SizedBox(
          width: itemWidth.clamp(100, 200), // Clamp between min and max
          child: _buildRolePreviewItem(role, isAdding, isCompact),
        );
      }).toList(),
    );
  }

  // Individual role preview item
  Widget _buildRolePreviewItem(Role role, bool isAdding, bool isCompact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAdding ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdding ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAdding ? Iconsax.add_circle : Iconsax.minus_cirlce,
            size: 14,
            color: isAdding ? Colors.green[800] : Colors.red[800],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              role.name,
              style: TextStyle(
                color: isAdding ? Colors.green[800] : Colors.red[800],
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              isAssigned ? Iconsax.verify : Iconsax.add_circle,
              size: isCompact ? 16 : 20,
              color: isAssigned ? Color(0xFF10b981) : Color(0xFF3b82f6),
            ),
            SizedBox(width: 8),
            Text(
              '$title (${roles.length})',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: isAssigned ? Color(0xFF10b981) : Color(0xFF3b82f6),
              ),
            ),
          ],
        ),

        // Roles as horizontal row
        Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
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
              : _buildDynamicRoleItemsWrap(
                  roles: roles,
                  isAssigned: isAssigned,
                  selectedRoles: selectedRoles,
                  isCompact: isCompact,
                  onRoleTap: onRoleTap,
                ),
        ),
      ],
    );
  }

  Widget _buildDynamicRoleItemsWrap({
    required List<Role> roles,
    required bool isAssigned,
    required List<Role> selectedRoles,
    required bool isCompact,
    required ValueChanged<Role> onRoleTap,
  }) {
    return Wrap(
      spacing: 2, // Horizontal space between items
      runSpacing: 2, // Vertical space between lines
      alignment: WrapAlignment.start,
      children: roles.map((role) {
        return Container(
          child: _buildRoleItem(
            role: role,
            isAssigned: isAssigned,
            isSelected: selectedRoles.any((r) => r.id == role.id),
            isCompact: isCompact,
            onRoleTap: () => onRoleTap(role),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleItem({
    required Role role,
    required bool isAssigned,
    VoidCallback? onRoleTap,
    required bool isCompact,
    required bool isSelected,
  }) {
    // Colors based on Figma design
    Color getBackgroundColor() {
      if (isSelected) {
        return const Color(0xFFFDD105); // Selected - yellow
      }
      if (isAssigned) {
        return const Color(0xFF145888); // Assigned - blue
      }
      return const Color(0xFFD7DDDA); // Available - gray
    }

    Color getTextColor() {
      if (isSelected) {
        return Colors.black; // Yellow background needs black text
      }
      return Colors.white; // Blue and gray backgrounds need white text
    }

    return GestureDetector(
      onTap: onRoleTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: ShapeDecoration(
          color: getBackgroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              width: isSelected ? 1 : 0,
              color: isSelected ? const Color(0xFFFFE468) : Colors.transparent,
            ),
          ),
          shadows: isSelected
              ? [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 3,
                    offset: Offset(1, 1),
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Text(
          role.name,
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
            color: getTextColor(),
          ),
        ),
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
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
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
}
