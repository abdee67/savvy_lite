import 'package:flutter/material.dart';

/// Reusable confirmation dialog for delete actions
Future<void> showDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

/// Dialog for voiding with reason input
Future<void> showVoidDialog(
  BuildContext context, {
  required String title,
  required String content,
  required Function(String reason) onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) => _VoidDialogContent(
      title: title,
      content: content,
      onConfirm: onConfirm,
    ),
  );
}

/// Stateful widget for void dialog to properly manage controller lifecycle
class _VoidDialogContent extends StatefulWidget {
  final String title;
  final String content;
  final Function(String reason) onConfirm;

  const _VoidDialogContent({
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  State<_VoidDialogContent> createState() => _VoidDialogContentState();
}

class _VoidDialogContentState extends State<_VoidDialogContent> {
  late final TextEditingController _reasonController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.content),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for voiding',
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final reason = _reasonController.text.trim();
              Navigator.pop(context);
              widget.onConfirm(reason);
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Void'),
        ),
      ],
    );
  }
}

/// Reusable snackbar with undo action
void showUndoSnackbar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 5),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(label: 'UNDO', onPressed: onUndo),
      duration: duration,
    ),
  );
}
