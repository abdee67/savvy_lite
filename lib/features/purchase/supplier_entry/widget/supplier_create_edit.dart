// lib/features/purchase/supplier/ui/supplier_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_event.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_state.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SupplierEntryScreen extends StatefulWidget {
  final SupplierModel? supplier;
  final AuthBloc authBloc;

  const SupplierEntryScreen({super.key, this.supplier, required this.authBloc});

  @override
  State<SupplierEntryScreen> createState() => _SupplierEntryScreenState();
}

class _SupplierEntryScreenState extends State<SupplierEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Text controllers
  late TextEditingController _supplierNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactTitleController;
  late TextEditingController _phoneNo1Controller;
  late TextEditingController _phoneNo2Controller;
  late TextEditingController _emailController;
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _regionController;
  late TextEditingController _stateController;
  late TextEditingController _tinNumberController;

  // Country selection
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Load UDC details for countries
    context.read<UdcDetailsBloc>().add(
      const LoadUdcDetailsByGroup('CN'),
    ); // Assuming 'CNTRY' is the UDC header for countries

    // Set selected supplier if editing
    if (widget.supplier != null) {
      context.read<SupplierBloc>().add(SetSelectedSupplier(widget.supplier));
    }
  }

  void _initializeControllers() {
    final supplier = widget.supplier ?? SupplierModel.empty();

    _supplierNameController = TextEditingController(
      text: supplier.supplierName,
    );
    _contactPersonController = TextEditingController(
      text: supplier.contactPerson,
    );
    _contactTitleController = TextEditingController(
      text: supplier.contactTitle,
    );
    _phoneNo1Controller = TextEditingController(text: supplier.phoneNo1);
    _phoneNo2Controller = TextEditingController(text: supplier.phoneNo2);
    _emailController = TextEditingController(text: supplier.email);
    _addressLineController = TextEditingController(text: supplier.addressLine);
    _cityController = TextEditingController(text: supplier.city);
    _regionController = TextEditingController(text: supplier.region);
    _stateController = TextEditingController(text: supplier.state);
    _tinNumberController = TextEditingController(text: supplier.tinNumber);

    _selectedCountry = supplier.country;
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _contactPersonController.dispose();
    _contactTitleController.dispose();
    _phoneNo1Controller.dispose();
    _phoneNo2Controller.dispose();
    _emailController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _stateController.dispose();
    _tinNumberController.dispose();
    super.dispose();
  }

  void _saveSupplier() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final companyId = widget.authBloc.state.companyId;
      if (companyId == null) {
        _showErrorDialog('Authentication error: Company ID not found');
        setState(() => _isSaving = false);
        return;
      }

      final supplier = SupplierModel(
        id: widget.supplier?.id,
        supplierName: _supplierNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        contactTitle: _contactTitleController.text.trim().isEmpty
            ? null
            : _contactTitleController.text.trim(),
        phoneNo1: _phoneNo1Controller.text.trim(),
        phoneNo2: _phoneNo2Controller.text.trim().isEmpty
            ? null
            : _phoneNo2Controller.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        addressLine: _addressLineController.text.trim().isEmpty
            ? null
            : _addressLineController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        region: _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        country: _selectedCountry,
        tinNumber: _tinNumberController.text.trim().isEmpty
            ? null
            : _tinNumberController.text.trim(),
        company: companyId,
        dateCreated: widget.supplier?.dateCreated ?? DateTime.now(),
        dateUpdated: DateTime.now(),
      );

      if (widget.supplier == null) {
        context.read<SupplierBloc>().add(CreateSupplier(supplier));
      } else {
        context.read<SupplierBloc>().add(UpdateSupplier(supplier));
      }
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
          widget.supplier == null
              ? 'Supplier created successfully!'
              : 'Supplier updated successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryField() {
    return BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
      builder: (context, state) {
        if (state.status == UdcDetailsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.details.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No countries available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final countryList = state.details.toList();
        final countryOptions = countryList
            .map((udc) => udc.description1 ?? '')
            .where((desc) => desc.isNotEmpty)
            .toList();

        if (countryOptions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No valid countries found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Get current selected country from UDC details
        String? currentCountry;
        if (_selectedCountry != null) {
          // Try to find by ID first
          final byId = countryList.firstWhere(
            (c) => c.id.toString() == _selectedCountry,
            orElse: () => UdcDetails.empty(),
          );

          // If not found by ID, try by description
          currentCountry = byId.description1;
        }

        return CustomSearchableDropdown(
          labelText: 'Country *',
          options: countryOptions,
          value: currentCountry,
          prefixIcon: Icons.flag,
          allowCustomEntries: false, // Don't allow custom countries for now
          enabled: true,
          onChanged: (value) {
            if (value == null) {
              setState(() {
                _selectedCountry = null;
              });
            } else {
              // Find the UDC detail that matches the selected description
              final selectedUdc = countryList.firstWhere(
                (c) => c.description1 == value,
                orElse: () => UdcDetails.empty(),
              );

              setState(() {
                // Store either the ID or description based on your preference
                _selectedCountry = selectedUdc.id
                    ?.toString(); // or selectedUdc.description1
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a country';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? customValidator,
  ]) {
    return CustomTextField(
      controller: controller,
      keyboardType: keyboardType,
      labelText: label,
      prefixIcon: Icon(icon),
      validator: (value) {
        if (customValidator != null) {
          return customValidator(value);
        }
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state.status == SupplierStatus.success && _isSaving) {
          setState(() => _isSaving = false);
          _showSuccessDialog();
        }
        if (state.status == SupplierStatus.failure && _isSaving) {
          setState(() => _isSaving = false);
          _showErrorDialog(state.errorMessage);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.supplier == null ? 'Create Supplier' : 'Edit Supplier',
          ),
          backgroundColor: const Color(0xFF145888),
          elevation: 0,
          actions: [
            if (widget.supplier != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Supplier'),
                      content: const Text(
                        'Are you sure you want to delete this supplier?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<SupplierBloc>().add(
                              DeleteSupplier(
                                deletedItem: widget.supplier!,
                                deletedIndex: 0,
                              ),
                            );
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close screen
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Basic Information Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF145888),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _supplierNameController,
                          'Supplier Name *',
                          Icons.business,
                          TextInputType.text,
                          true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _contactPersonController,
                          'Contact Person *',
                          Icons.person,
                          TextInputType.text,
                          true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _contactTitleController,
                          'Contact Title',
                          Icons.title,
                          TextInputType.text,
                          false,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _tinNumberController,
                          'TIN Number',
                          Icons.numbers,
                          TextInputType.number,
                          false,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Contact Information Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF145888),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _phoneNo1Controller,
                          'Phone Number 1 *',
                          Icons.phone,
                          TextInputType.phone,
                          true,
                          (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!RegExp(r'^[0-9+]{10,}$').hasMatch(value)) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _phoneNo2Controller,
                          'Phone Number 2',
                          Icons.phone_android,
                          TextInputType.phone,
                          false,
                          (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                !RegExp(r'^[0-9+]{10,}$').hasMatch(value)) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _emailController,
                          'Email',
                          Icons.email,
                          TextInputType.emailAddress,
                          false,
                          (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                !RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Address Information Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF145888),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _addressLineController,
                          'Address Line',
                          Icons.location_on,
                          TextInputType.text,
                          false,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _cityController,
                          'City',
                          Icons.location_city,
                          TextInputType.text,
                          false,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _regionController,
                                'Region',
                                Icons.map,
                                TextInputType.text,
                                false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _stateController,
                                'State',
                                Icons.location_pin,
                                TextInputType.text,
                                false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCountryField(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSupplier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF145888),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            widget.supplier == null
                                ? 'Create Supplier'
                                : 'Update Supplier',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
