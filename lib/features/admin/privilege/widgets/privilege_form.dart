import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_event.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

class PrivilegeForm extends StatefulWidget {
  final Privilege? privilege;
  const PrivilegeForm({super.key, this.privilege});

  @override
  State<PrivilegeForm> createState() => _PrivilegeFormState();
}

class _PrivilegeFormState extends State<PrivilegeForm> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _uriController;
  late TextEditingController _linkLabelController;
  late TextEditingController _buttonLabelController;

  String _type = 'link'; // default
  bool _vendorOnly = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _uriController = TextEditingController();
    _linkLabelController = TextEditingController();
    _buttonLabelController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _uriController.dispose();
    _linkLabelController.dispose();
    _buttonLabelController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final privilegeBloc = context.read<PrivilegeBloc>();
      privilegeBloc.add(
        CreatePrivilege(
          _nameController.text,
          _descriptionController.text,
          _type,
          _uriController.text,
          _linkLabelController.text,
          _buttonLabelController.text,
          _vendorOnly,
        ),
      );

      // TODO: Save privilege to DB or Bloc

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Privilege ${widget.privilege == null ? "added" : "updated"}',
          ),
        ),
      );

      Navigator.pop(context); // return to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.privilege != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Privilege' : 'Add Privilege'),
        actions: [
          IconButton(onPressed: _saveForm, icon: const Icon(Icons.save)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Privilege Name',
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 12),

                // Type
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  items: const [
                    DropdownMenuItem(value: 'link', child: Text('Link')),
                    DropdownMenuItem(value: 'button', child: Text('Button')),
                  ],
                  onChanged: (value) {
                    setState(() => _type = value ?? 'link');
                  },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),

                const SizedBox(height: 12),

                // Link (only if type is link or button)
                TextFormField(
                  controller: _uriController,
                  decoration: const InputDecoration(
                    labelText: 'Link URL (optional)',
                  ),
                ),

                const SizedBox(height: 12),

                if (_type == 'link') ...[
                  TextFormField(
                    controller: _linkLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Link Label (unique)',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Required for link type' : null,
                  ),
                ] else if (_type == 'button') ...[
                  TextFormField(
                    controller: _buttonLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Button Label (optional)',
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Vendor Only
                CheckboxListTile(
                  title: const Text('Vendor Only'),
                  value: _vendorOnly,
                  onChanged: (value) {
                    setState(() => _vendorOnly = value ?? false);
                  },
                ),

                const SizedBox(height: 20),

                // Submit
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(isEdit ? 'Update Privilege' : 'Add Privilege'),
                  onPressed: _saveForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
