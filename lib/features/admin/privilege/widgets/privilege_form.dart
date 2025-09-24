import 'package:flutter/material.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

class PrivilegeForm extends StatefulWidget {
  final Privilege? privilege;
  const PrivilegeForm({super.key, this.privilege});

  @override
  State<PrivilegeForm> createState() => _PrivilegeFormState();
}

class _PrivilegeFormState extends State<PrivilegeForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.privilege == null ? 'Add Privilege' : 'Edit Privilege',
        ),
      ),
      body: Center(child: Text('Privilege form goes here')),
    );
  }
}
