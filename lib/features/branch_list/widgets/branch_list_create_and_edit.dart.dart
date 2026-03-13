import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:flutter/services.dart';

class BranchFormPage extends StatefulWidget {
  final Branch? branch;
  final AuthBloc authBloc;

  const BranchFormPage({super.key, this.branch, required this.authBloc});

  @override
  State<BranchFormPage> createState() => _BranchFormPageState();
}

class _BranchFormPageState extends State<BranchFormPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _storeNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _regionController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.branch != null) {
      context.read<BranchBloc>().add(SetBranchForm(widget.branch!));
    }
  }

  void _initializeControllers() {
    final branch = widget.branch ?? Branch.empty();

    _storeNumberController = TextEditingController(
      text: branch.referenceId ?? '',
    );
    _descriptionController = TextEditingController(
      text: branch.description ?? '',
    );
    _addressLineController = TextEditingController(
      text: branch.addressLine ?? '',
    );
    _cityController = TextEditingController(text: branch.city ?? '');
    _stateController = TextEditingController(text: branch.state ?? '');
    _regionController = TextEditingController(text: branch.region ?? '');
    _phoneController = TextEditingController(text: branch.branchPhone ?? '');
  }

  @override
  void dispose() {
    _storeNumberController.dispose();
    _descriptionController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveBranch() {
    if (_formKey.currentState!.validate()) {
      // FIX: Check if description is not null since it's required
      final description = _descriptionController.text;
      if (description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Description is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // FIX: Check if branch phone is not null since it's required
      final branchPhone = _phoneController.text;
      if (branchPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final branch = Branch(
        id: widget.branch?.id ?? 0,
        referenceId: _storeNumberController.text.isEmpty
            ? null
            : _storeNumberController.text,
        description: description,
        state: _stateController.text.isEmpty ? null : _stateController.text,
        region: _regionController.text.isEmpty ? null : _regionController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        addressLine: _addressLineController.text.isEmpty
            ? null
            : _addressLineController.text,
        branchPhone: branchPhone,
        country: 'Ethiopia',
        company: widget.authBloc.state.companyId,
      );
      //if there is an error creating or updating
      final state = context.read<BranchBloc>().state;
      if (state.status == BranchStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (widget.branch == null) {
        context.read<BranchBloc>().add(CreateBranch(branch));
      } else {
        context.read<BranchBloc>().add(UpdateBranch(branch));
      }
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(
          widget.branch == null
              ? 'Branch created successfully!'
              : 'Branch updated successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch == null ? 'Create Branch' : 'Edit Branch'),
        backgroundColor: Color(0xFF145888),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocListener<BranchBloc, BranchState>(
          listener: (context, state) {
            if (state.status == BranchStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? 'An error occurred'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(child: _buildForm()),
              _buildBottomNavigation(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              _storeNumberController,
              'Store Number *',
              Icons.person,
              TextInputType.number,
              1,
              10, // reference_id as int, 10 digits is usually safe
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _descriptionController,
              'Description *',
              Icons.person_outline,
              TextInputType.text,
              1,
              45,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _addressLineController,
              'Address Line',
              Icons.location_on_rounded,
              TextInputType.text,
              1,
              200,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _cityController,
              'City',
              Icons.location_city,
              TextInputType.text,
              1,
              45,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _stateController,
              'State *',
              Icons.location_on_rounded,
              TextInputType.text,
              1,
              45,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _regionController,
              'Region',
              Icons.location_city,
              TextInputType.text,
              1,
              45,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _phoneController,
              'Phone *',
              Icons.phone,
              TextInputType.phone,
              1,
              14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _saveBranch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF145888),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  ]) {
    return CustomTextField(
      controller: controller,
      keyboardType: keyboardType,
      labelText: label,
      prefixIcon: Icon(icon),
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        if (maxLength != null && value != null && value.length > maxLength) {
          return 'Must be $maxLength characters or less';
        }
        return null;
      },
    );
  }
}
