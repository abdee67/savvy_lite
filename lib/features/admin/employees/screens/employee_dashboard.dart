import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/employees/widgets/emloyee_create_and_edit.dart.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class EmployeeListPage extends StatefulWidget {
  final AuthBloc authBloc;
  const EmployeeListPage({super.key, required this.authBloc});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  @override
  void initState() {
    super.initState();
    context.read<EmployeeBloc>().add(
      LoadEmployees(widget.authBloc.state.companyId!),
    );
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
    if (!_isSelectionMode) {
      context.read<EmployeeBloc>().add(ShowEmployeeDetail(employee));
    }
  }

  void _hideEmployeeDetail() {
    context.read<EmployeeBloc>().add(HideEmployeeDetail());
  }

  void _clearSelection() {
    context.read<EmployeeBloc>().add(ClearSelection());
    _isSelectionMode = false;
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
    context.read<EmployeeBloc>().add(ExportEmployee());
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
          bloc.add(
            DeleteSelectedEmployees(
              selectedEmployees: ids,
              deletedEmployees: employeesToDelete,
              deletedIndexes: employeesToDelete
                  .map((emp) => state.employees.indexOf(emp))
                  .toList(),
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
              if (state.showDetailPanel && state.employeeDetail != null)
                _buildDetailPanel(state.employeeDetail!),
            ],
          );
        },
      ),

      // Floating Action Button for Add
      floatingActionButton: BlocBuilder<EmployeeBloc, EmployeeState>(
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
      ),
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
      height: state.isSelectionMode ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: state.isSelectionMode
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
          _isSelectionMode = true;
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _hideEmployeeDetail,
              ),
            ),

            // Employee details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        employee.nameFirst,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildDetailRow(
                      'Employee Full Name',
                      '${employee.nameFirst} ${employee.nameLast}',
                    ),
                    _buildDetailRow('Employee ID', employee.employeeId),
                    _buildDetailRow('Email', employee.email),
                    _buildDetailRow('Phone', employee.phone),
                    _buildDetailRow('Country', employee.country),
                    _buildDetailRow('City', employee.city),
                    _buildDetailRow('Address', employee.address),
                    _buildDetailRow('Hired On', employee.hireDate),
                  ],
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.call, size: 28),
                    onPressed: () => _callEmployee(employee.phone),
                    tooltip: 'Call employee',
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.sms, size: 28),
                    onPressed: () => _emailEmployee(employee.email),
                    tooltip: 'Email employee',
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.export, size: 28),
                    onPressed: () => _exportEmployee(employee),
                    tooltip: 'Export employee data',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
