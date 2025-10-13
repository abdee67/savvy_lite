import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class EmployeeDetailPanel extends StatefulWidget {
  final Employee employee;
  final VoidCallback onClose;
  final AuthBloc authBloc;
  final UserBloc userBloc;

  const EmployeeDetailPanel({
    super.key,
    required this.employee,
    required this.onClose,
    required this.authBloc,
    required this.userBloc,
  });

  @override
  State<EmployeeDetailPanel> createState() => _EmployeeDetailPanelState();
}

class _EmployeeDetailPanelState extends State<EmployeeDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

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
    if (matchingUsers.isEmpty) return null;
    return matchingUsers.first;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closePanel() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _toggleRoleManagement() {
    final employeeBloc = context.read<EmployeeBloc>();
    final state = employeeBloc.state;

    if (state.isRoleManagementMode) {
      employeeBloc.add(ToggleRoleManagement(0));
      employeeBloc.add(ClearRoleSelection());
    } else {
      employeeBloc.add(ToggleRoleManagement(widget.employee.id));
      context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375;
    final isUser = _isEmployeeUser(widget.employee);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, (1 - _slideAnimation.value) * screenHeight * 0.3),
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                height: screenHeight * 0.7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: BlocBuilder<EmployeeBloc, EmployeeState>(
                  builder: (context, state) {
                    return _buildPanelContent(
                      state,
                      isUser,
                      isSmallScreen,
                      screenWidth,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelContent(
    EmployeeState state,
    bool isUser,
    bool isSmallScreen,
    double screenWidth,
  ) {
    return Column(
      children: [
        // Header with drag handle
        _buildPanelHeader(state, isUser, isSmallScreen),

        // Main content
        Expanded(
          child: state.isRoleManagementMode && isUser
              ? _buildRoleManagementView(
                  widget.employee,
                  isSmallScreen,
                  screenWidth,
                )
              : _buildEmployeeInfoView(
                  widget.employee,
                  isSmallScreen,
                  screenWidth,
                ),
        ),
      ],
    );
  }

  Widget _buildPanelHeader(
    EmployeeState state,
    bool isUser,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Row(
            children: [
              // Employee avatar and basic info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employee.id.toString(),
                      style: TextStyle(
                        color: const Color(0xFF887F7F),
                        fontSize: isSmallScreen ? 12 : 14,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.employee.nameFirst} ${widget.employee.nameLast}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isSmallScreen ? 20 : 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.employee.title ?? 'Employee',
                      style: TextStyle(
                        color: const Color(0xFF4C3737),
                        fontSize: isSmallScreen ? 12 : 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                children: [
                  // Edit date info
                  Container(
                    width: 102,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Edited on ',
                            style: TextStyle(
                              color: const Color(0xFF887F7F),
                              fontSize: isSmallScreen ? 8 : 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          TextSpan(
                            text: _getEditedDate(),
                            style: TextStyle(
                              color: const Color(0xFF887F7F),
                              fontSize: isSmallScreen ? 8 : 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Main action button
                  GestureDetector(
                    onTap: _toggleRoleManagement,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF145888),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        state.isRoleManagementMode
                            ? 'See Less'
                            : (isUser ? 'Show Roles' : 'See More'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfoView(
    Employee employee,
    bool isSmallScreen,
    double screenWidth,
  ) {
    final isUser = _isEmployeeUser(employee);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFCBCBCB),
            const Color(0xFFFDD105).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic information section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Role:', employee.title ?? 'Employee'),
                  _buildInfoRow(
                    'Nationality:',
                    employee.country ?? 'Ethiopian',
                  ),
                  _buildInfoRow('City:', employee.city ?? 'Addis Ababa'),
                  _buildInfoRow('Phone number:', employee.phone),
                  _buildInfoRow('Email:', employee.email),
                  _buildInfoRow('Address:', employee.address ?? 'N/A'),
                  _buildInfoRow('Hired on:', _formatDate(employee.hireDate)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User status and conversion button
            if (!isUser) _buildConvertToUserSection(employee, isSmallScreen),

            // Privileges section for users
            if (isUser) _buildPrivilegesSection(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              text: ' $value',
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
    );
  }

  Widget _buildConvertToUserSection(Employee employee, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'This employee is not a system user',
            style: TextStyle(
              color: const Color(0xFF373737),
              fontSize: isSmallScreen ? 14 : 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Navigate to convert to user screen
              // context.push(AppRoutes.employeeConversionToUser, extra: {'employee': employee});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF145888),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Convert to User',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegesSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privileges',
            style: TextStyle(
              color: const Color(0xFF373737),
              fontSize: isSmallScreen ? 16 : 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Privilege buttons grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPrivilegeButton('Report Access', isSmallScreen),
              _buildPrivilegeButton('Main inbox', isSmallScreen),
              _buildPrivilegeButton('Price leads', isSmallScreen),
              _buildPrivilegeButton('Store Price', isSmallScreen),
              _buildPrivilegeButton('Voided rec.', isSmallScreen),
              _buildPrivilegeButton('Change profile', isSmallScreen),
            ],
          ),

          const SizedBox(height: 20),

          // Role management section
          _buildRoleManagementPreview(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildPrivilegeButton(String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFF145888),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFA9A9A9)),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 10 : 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRoleManagementPreview(bool isSmallScreen) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final userWithRole = _getUserForEmployee(widget.employee);
        final roles = userWithRole?.roles ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Roles',
              style: TextStyle(
                color: const Color(0xFF373737),
                fontSize: isSmallScreen ? 14 : 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (roles.isEmpty)
              Text(
                'No roles assigned',
                style: TextStyle(
                  color: const Color(0xFF887F7F),
                  fontSize: isSmallScreen ? 12 : 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w300,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles
                    .map((role) => _buildRoleChip(role.name, isSmallScreen))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRoleChip(String roleName, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E5E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF145888),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            roleName,
            style: TextStyle(
              color: const Color(0xFF8E8E93),
              fontSize: isSmallScreen ? 10 : 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleManagementView(
    Employee employee,
    bool isSmallScreen,
    double screenWidth,
  ) {
    final userWithRole = _getUserForEmployee(employee);

    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, roleState) {
        final assignedRoles = userWithRole?.roles ?? [];
        final allRoles = roleState.roles;
        final availableRoles = allRoles
            .where((role) => !assignedRoles.any((r) => r.id == role.id))
            .toList();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFCBCBCB),
                const Color(0xFFFDD105).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Security role section
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E5E5),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF145888),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Security',
                          style: TextStyle(
                            color: const Color(0xFF8E8E93),
                            fontSize: isSmallScreen ? 12 : 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 35,
                      height: 35,
                      decoration: const ShapeDecoration(
                        color: Color(0xFFFDD105),
                        shape: OvalBorder(),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assigned roles section
                        _buildRoleSection(
                          'Assigned Roles',
                          assignedRoles,
                          true,
                          isSmallScreen,
                        ),
                        const SizedBox(height: 20),

                        // Available roles section
                        _buildRoleSection(
                          'Available Roles',
                          availableRoles,
                          false,
                          isSmallScreen,
                        ),
                        const SizedBox(height: 20),

                        // Action buttons
                        _buildRoleActionButtons(isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleSection(
    String title,
    List<Role> roles,
    bool isAssigned,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF373737),
            fontSize: isSmallScreen ? 14 : 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        if (roles.isEmpty)
          Text(
            'No ${title.toLowerCase()}',
            style: TextStyle(
              color: const Color(0xFF887F7F),
              fontSize: isSmallScreen ? 12 : 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w300,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles
                .map((role) => _buildRoleItem(role, isAssigned, isSmallScreen))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildRoleItem(Role role, bool isAssigned, bool isSmallScreen) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      builder: (context, state) {
        final isSelected = state.selectedRolesForAssignment.any(
          (r) => r.id == role.id,
        );

        return GestureDetector(
          onTap: () {
            context.read<EmployeeBloc>().add(SelectRoleForAssignment(role));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFDD105)
                  : const Color(0xFF145888),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.name,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: isSmallScreen ? 10 : 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleActionButtons(bool isSmallScreen) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      builder: (context, state) {
        final hasChanges = state.selectedRolesForAssignment.isNotEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: hasChanges ? () => _saveRoleChanges() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF145888),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _toggleRoleManagement,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7DDDA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveRoleChanges() {
    final userWithRole = _getUserForEmployee(widget.employee);
    final state = context.read<EmployeeBloc>().state;

    if (userWithRole?.user.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user account found')));
      return;
    }

    final currentAssignedRoles = userWithRole!.roles;
    final selectedRoles = state.selectedRolesForAssignment;

    // Calculate final roles using toggle logic
    final finalRoles = <Role>[];

    // Keep roles that are not selected for removal
    for (final assignedRole in currentAssignedRoles) {
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

    widget.userBloc.add(
      AssignRolesToUser(
        userWithRole.user.id,
        widget.authBloc.state.companyId!,
        finalRoles,
        widget.authBloc.state.userId!,
      ),
    );

    context.read<EmployeeBloc>().add(ClearRoleSelection());
    _toggleRoleManagement();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role changes saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getEditedDate() {
    // This would typically come from your employee data
    return 'April 12'; // Placeholder
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
