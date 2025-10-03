// features/privilege/screens/privilege_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_event.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_state.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class PrivilegeManagementScreen extends StatefulWidget {
  final AuthBloc authBloc;
  const PrivilegeManagementScreen({super.key, required this.authBloc});

  @override
  State<PrivilegeManagementScreen> createState() =>
      _PrivilegeManagementScreenState();
}

class _PrivilegeManagementScreenState extends State<PrivilegeManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load available privileges
    context.read<PrivilegeBloc>().add(
      LoadPrivileges(widget.authBloc.state.companyId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privilege Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.createPrivilege),
          ),
        ],
      ),
      body: BlocBuilder<PrivilegeBloc, PrivilegeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.isSuccess) {
            return _buildPrivilegeList(state.privileges, context);
          } else if (state.isFailure) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return const Center(child: Text('No privileges found'));
          }
        },
      ),
    );
  }

  Widget _buildPrivilegeList(List<Privilege> privileges, BuildContext context) {
    return ListView.builder(
      itemCount: privileges.length,
      itemBuilder: (context, index) {
        final privilege = privileges[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              privilege.type == 'link' ? Icons.link : Icons.touch_app,
              color: Colors.blue,
            ),
            title: Text(privilege.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(privilege.description),
                Text('URI: ${privilege.uri}'),
                Text('Type: ${privilege.type}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push(
                    AppRoutes.editPrivilege,
                    extra: {'privilege': privilege},
                  ),
                ),
                if (context.read<AuthBloc>().state.hasAccessToPrivilege(
                  AppRoutes.deletePrivilege,
                ))
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePrivilege(context, privilege.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deletePrivilege(BuildContext context, int privilegeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Privilege'),
        content: const Text('Are you sure you want to delete this privilege?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PrivilegeBloc>().add(DeletePrivilege(privilegeId));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
