import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/company/blocs/company_bloc.dart';
import 'package:savvy_stock/features/company/blocs/company_event.dart';
import 'package:savvy_stock/features/company/blocs/company_state.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';

class CompanyFormPage extends StatefulWidget {
  final Company? company;
  final AuthBloc authBloc;

  const CompanyFormPage({super.key, this.company, required this.authBloc});

  @override
  State<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<CompanyFormPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _tinNumberController;
  late TextEditingController _reorderPointController;
  late TextEditingController _marginRateController;
  late TextEditingController _phoneNumber1Controller;
  late TextEditingController _phoneNumber2Controller;
  late TextEditingController _phoneNumber3Controller;
  late TextEditingController _emailAddress1Controller;
  late TextEditingController _emailAddress2Controller;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _regionController;
  late TextEditingController _addressLineController;
  late TextEditingController _logoCompanyController;

  String? _selectedMarginType;
  final List<String> _marginTypes = [
    'Flat',
    'Percentage',
  ]; // Flat or Percentage
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.company != null) {
      context.read<CompanyBloc>().add(SetCompanyForm(widget.company!));
    }
  }

  void _initializeControllers() {
    final company = widget.company ?? Company.empty();

    _companyNameController = TextEditingController(
      text: company.companyName ?? '',
    );
    _tinNumberController = TextEditingController(text: company.tinNumber ?? '');
    _reorderPointController = TextEditingController(
      text: company.reorderPoint?.toString() ?? '',
    );
    _marginRateController = TextEditingController(
      text: company.marginRate?.toString() ?? '',
    );
    _selectedMarginType = _marginTypes.contains(company.marginType)
        ? company.marginType
        : _marginTypes.first; // Default to first item if invalid or empty
    _phoneNumber1Controller = TextEditingController(
      text: company.phoneNumber1 ?? '',
    );
    _phoneNumber2Controller = TextEditingController(
      text: company.phoneNumber2 ?? '',
    );
    _phoneNumber3Controller = TextEditingController(
      text: company.phoneNumber3 ?? '',
    );
    _emailAddress1Controller = TextEditingController(
      text: company.emailAddress1 ?? '',
    );
    _emailAddress2Controller = TextEditingController(
      text: company.emailAddress2 ?? '',
    );
    _countryController = TextEditingController(
      text: company.country ?? 'Ethiopia',
    );
    _cityController = TextEditingController(text: company.city ?? '');
    _stateController = TextEditingController(text: company.state ?? '');
    _regionController = TextEditingController(text: company.region ?? '');
    _addressLineController = TextEditingController(
      text: company.addressLine ?? '',
    );
    _logoCompanyController = TextEditingController(
      text: company.logoCompany ?? '',
    );
    _logoPath = company.logoCompany;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _tinNumberController.dispose();
    _phoneNumber1Controller.dispose();
    _phoneNumber2Controller.dispose();
    _phoneNumber3Controller.dispose();
    _emailAddress1Controller.dispose();
    _emailAddress2Controller.dispose();
    _reorderPointController.dispose();
    _marginRateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _regionController.dispose();
    _addressLineController.dispose();
    _logoCompanyController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _logoPath = result.files.single.path;
        _logoCompanyController.text = _logoPath!; // Keep controller in sync
      });
    }
  }

  void _previousSlide() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _nextSlide() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveCompany() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final company = Company(
        id: widget.company?.id ?? 0,
        companyName: _companyNameController.text,
        tinNumber: _tinNumberController.text,
        phoneNumber1: _phoneNumber1Controller.text,
        phoneNumber2: _phoneNumber2Controller.text,
        phoneNumber3: _phoneNumber3Controller.text,
        emailAddress1: _emailAddress1Controller.text,
        emailAddress2: _emailAddress2Controller.text,
        reorderPoint: _reorderPointController.text.isEmpty
            ? null
            : double.parse(_reorderPointController.text),
        marginRate: _marginRateController.text.isEmpty
            ? null
            : double.parse(_marginRateController.text),
        marginType: _selectedMarginType == 'Flat' ? 'F' : 'P',
        country: _countryController.text.isEmpty
            ? null
            : _countryController.text,
        state: _stateController.text.isEmpty ? null : _stateController.text,
        region: _regionController.text.isEmpty ? null : _regionController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        addressLine: _addressLineController.text.isEmpty
            ? null
            : _addressLineController.text,
        logoCompany: _logoPath,
        dateUpdated: DateTime.now(),
        dateCreated: DateTime.now(),
      );

      if (widget.company == null) {
        context.read<CompanyBloc>().add(CreateCompany(company));
      } else {
        context.read<CompanyBloc>().add(UpdateCompany(company));
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
          widget.company == null
              ? 'Company created successfully!'
              : 'Company updated successfully!',
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, state) {
        if (state.status == CompanyStatus.success) {
          _showSuccessDialog();
          setState(() => _isSaving = false);
        }
        if (state.status == CompanyStatus.failure) {
          setState(() => _isSaving = false);
          _showErrorDialog(state.message ?? 'An error occurred');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.company == null ? 'Create Company' : 'Edit Company',
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          actions: [
            GestureDetector(
              onTap: _pickLogo,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  backgroundImage: _logoPath != null && _logoPath!.isNotEmpty
                      ? FileImage(File(_logoPath!))
                      : null,
                  child: _logoPath == null || _logoPath!.isEmpty
                      ? const Icon(Icons.add_a_photo, color: Colors.grey)
                      : null,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressStep(1, 'Company Info', _currentPage >= 0),
                    _buildProgressStep(2, 'Contact Info', _currentPage >= 1),
                    _buildProgressStep(3, 'Location', _currentPage >= 2),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _buildCompanyInfoSlide(),
                      _buildContactInfoSlide(),
                      _buildLocationSlide(),
                    ],
                  ),
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoSlide() {
    final screen = MediaQuery.of(context).size;
    final bool isTablet = screen.width > 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60 : 30,
        vertical: isTablet ? 40 : 20,
      ),
      child: Column(
        children: [
          _buildTextField(
            _companyNameController,
            'Company Name *',
            Icons.business,
            null,
            true,
            150,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _tinNumberController,
            'TIN Number *',
            Icons.receipt_long,
            null,
            true,
            10,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _reorderPointController,
            'Reorder Point',
            Icons.reorder,
            TextInputType.number,
            false,
          ),

          const SizedBox(height: 16),
          CustomDropdown(
            labelText: 'Margin Type',
            prefixIcon: const Icon(Icons.trending_up),
            items: _marginTypes
                .map(
                  (marginType) => DropdownMenuItem(
                    value: marginType,
                    child: Text(marginType),
                  ),
                )
                .toList(),
            value: _selectedMarginType,
            onChanged: (value) {
              setState(() {
                _selectedMarginType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _marginRateController,
            'Margin Rate',
            _selectedMarginType == 'Flat' ? Icons.attach_money : Icons.percent,
            TextInputType.number,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSlide() {
    final screen = MediaQuery.of(context).size;
    final bool isTablet = screen.width > 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60 : 30,
        vertical: isTablet ? 40 : 20,
      ),
      child: Column(
        children: [
          _buildTextField(
            _phoneNumber1Controller,
            'Phone Number 1 *',
            Icons.phone,
            TextInputType.phone,
            true,
            15,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _phoneNumber2Controller,
            'Phone Number 2',
            Icons.phone,
            TextInputType.phone,
            false,
            15,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _phoneNumber3Controller,
            'Phone Number 3',
            Icons.phone,
            TextInputType.phone,
            false,
            15,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _emailAddress1Controller,
            'Email Address 1',
            Icons.email,
            TextInputType.emailAddress,
            false,
            255,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _emailAddress2Controller,
            'Email Address 2',
            Icons.email,
            TextInputType.emailAddress,
            false,
            255,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSlide() {
    final screen = MediaQuery.of(context).size;
    final bool isTablet = screen.width > 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60 : 30,
        vertical: isTablet ? 40 : 20,
      ),
      child: Column(
        children: [
          _buildTextField(
            _countryController,
            'Country',
            Icons.public,
            TextInputType.text,
            false,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _stateController,
            'State',
            Icons.map,
            TextInputType.text,
            false,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _cityController,
            'City',
            Icons.location_city,
            TextInputType.text,
            false,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _regionController,
            'Region',
            Icons.landscape,
            TextInputType.text,
            false,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _addressLineController,
            'Address Line',
            Icons.location_on,
            TextInputType.text,
            false,
            200,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final screen = MediaQuery.of(context).size;
    final bool isTablet = screen.width > 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        _currentPage == 0
                            ? Navigator.pop(context)
                            : _previousSlide();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : (_currentPage == 2 ? _saveCompany : _nextSlide),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPage == 2
                      ? const Color(0xFF145888)
                      : Colors.amber,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _currentPage == 2 ? 'Save' : 'Next',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildProgressDot(_currentPage == 0),
              const SizedBox(width: 8),
              _buildProgressDot(_currentPage == 1),
              const SizedBox(width: 8),
              _buildProgressDot(_currentPage == 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.amber : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
    bool isRequired = true,
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
        if (label.contains('*') &&
            isRequired &&
            (value == null || value.isEmpty)) {
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
