// features/employee/screens/employee_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/users/screens/user_dashboard.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEmployeeForm(context),
          ),
        ],
      ),
      body: BlocBuilder<EmployeeBloc, EmployeeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.isSuccess) {
            return _buildEmployeeList(state.employees, context);
          } else {
            return const Center(child: Text('No employees found'));
          }
        },
      ),
    );
  }

  Widget _buildEmployeeList(List<Employee> employees, BuildContext context) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text('${employee.nameFirst} ${employee.nameLast}'),
            subtitle: Text(
              'ID: ${employee.employeeId} - ${employee.title ?? ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Create User Account',
                  onPressed: () => _createUserForEmployee(context, employee),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editEmployee(context, employee),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createUserForEmployee(BuildContext context, Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCreationScreen(employee: employee),
      ),
    );
  }

  void _showEmployeeForm(BuildContext context, [Employee? employee]) {
    // Implement employee form dialog
  }

  void _editEmployee(BuildContext context, Employee employee) {
    // Implement employee edit
  }
}
