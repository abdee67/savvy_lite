import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerCreateEdit extends StatefulWidget {
  final Customer? customer;
  final AuthBloc authBloc;

  const CustomerCreateEdit({super.key, this.customer, required this.authBloc});

  @override
  State<CustomerCreateEdit> createState() => _CustomerCreateEditState();
}

class _CustomerCreateEditState extends State<CustomerCreateEdit> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  // Controllers
  late TextEditingController _customerNameController;
  late TextEditingController _customerIDController;
  late TextEditingController _contactTitleController;
  late TextEditingController _tinNumberController;
  late TextEditingController _stateController;
  late TextEditingController _addressController;
  late TextEditingController _customerCityController;
  late TextEditingController _regionController;
  late TextEditingController _contacrNameController;
  late TextEditingController _contactPhone1Controller;
  late TextEditingController _contactPhone2Controller;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _address3Controller;
  late TextEditingController _address4Controller;
  late TextEditingController _faxController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.customer != null) {
      context.read<CustomerBloc>().add(SetCustomerForm(widget.customer!));
    }
  }

  void _initializeControllers() {
    final customer = widget.customer ?? Customer.empty;

    _customerNameController = TextEditingController(
      text: customer.customerName,
    );
    _customerIDController = TextEditingController(
      text: customer.customerId.toString(),
    );
    _contactTitleController = TextEditingController(
      text: customer.contactTitle,
    );
    _tinNumberController = TextEditingController(text: customer.tinNumber);
    _stateController = TextEditingController(text: customer.state);
    _addressController = TextEditingController(text: customer.address);
    _customerCityController = TextEditingController(text: customer.city);
    _regionController = TextEditingController(text: customer.region);
    _contacrNameController = TextEditingController(text: customer.contactName);
    _contactPhone1Controller = TextEditingController(
      text: customer.phoneNumber,
    );
    _contactPhone2Controller = TextEditingController(text: customer.phone2);
    _address1Controller = TextEditingController(text: customer.address1);
    _address2Controller = TextEditingController(text: customer.address2);
    _address3Controller = TextEditingController(text: customer.address3);
    _address4Controller = TextEditingController(text: customer.address4);
    _faxController = TextEditingController(text: customer.fax);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerIDController.dispose();
    _contactTitleController.dispose();
    _tinNumberController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _customerCityController.dispose();
    _regionController.dispose();
    _contacrNameController.dispose();
    _contactPhone1Controller.dispose();
    _contactPhone2Controller.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _address4Controller.dispose();
    _faxController.dispose();
    super.dispose();
  }

  void _previousSlide() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: widget.customer?.id ?? 0,
        customerId: _customerIDController.text.isEmpty
            ? null
            : int.parse(_customerIDController.text),
        customerName: _customerNameController.text,
        contactTitle: _contactTitleController.text.isEmpty
            ? ''
            : _contactTitleController.text,
        tinNumber: _tinNumberController.text,
        state: _stateController.text,
        address: _addressController.text,
        city: _customerCityController.text,
        region: _regionController.text,
        contactName: _contacrNameController.text,
        phoneNumber: _contactPhone1Controller.text,
        phone2: _contactPhone2Controller.text,
        address1: _address1Controller.text,
        address2: _address2Controller.text,
        address3: _address3Controller.text,
        address4: _address4Controller.text,
        fax: _faxController.text,
        company: widget.authBloc.state.companyId, // Get from auth bloc
      );

      if (widget.customer == null) {
        context.read<CustomerBloc>().add(AddCustomer(customer));
      } else {
        context.read<CustomerBloc>().add(UpdateCustomer(customer));
      }

      _showSuccessDialog();
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
          widget.customer == null
              ? 'Customer created successfully!'
              : 'Customer updated successfully!',
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
        title: Text(
          widget.customer == null ? 'Create Customer' : 'Edit Customer',
        ),
        backgroundColor: Color(0xFF145888),
        elevation: 0,
      ),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state.status == CustomerStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressStep(1, 'Customer Info', _currentPage >= 0),
                  _buildProgressStep(2, 'Contact Details', _currentPage >= 1),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [_buildSlide1(), _buildSlide2()],
                ),
              ),
            ),
          ],
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
            color: isActive ? Color(0xFF145888) : Colors.grey.shade300,
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
            color: isActive ? Color(0xFF145888) : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSlide1() {
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
            _customerNameController,
            'Customer Name *',
            Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _customerIDController,
            'Customer ID *',
            Icons.numbers,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _contactPhone1Controller,
            'Customer Phone 1 *',
            Icons.phone,
            TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _tinNumberController,
            'TIN Number',
            Icons.numbers,
            TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _stateController,
            'State',
            Icons.location_city,
            TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _regionController,
            'Region',
            Icons.location_city,
            TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _customerCityController,
            'City',
            Icons.location_city,
            TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _addressController,
            'Address',
            Icons.streetview_sharp,
            TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    final screen = MediaQuery.of(context).size;
    final bool isTablet = screen.width > 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60 : 30,
        vertical: isTablet ? 40 : 20,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildTextField(_contacrNameController, 'Contact Name', Icons.person),
          const SizedBox(height: 16),
          _buildTextField(
            _contactPhone2Controller,
            'Contact Phone 2',
            Icons.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _contactTitleController,
            'Contact Title',
            Icons.title,
          ),
          const SizedBox(height: 16),
          _buildTextField(_faxController, 'Fax', Icons.fax),
          const SizedBox(height: 16),
          _buildTextField(
            _address1Controller,
            'Address 1',
            Icons.streetview_sharp,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _address2Controller,
            'Address 2',
            Icons.streetview_sharp,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _address3Controller,
            'Address 3',
            Icons.streetview_sharp,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _address4Controller,
            'Address 4',
            Icons.streetview_sharp,
          ),
          const SizedBox(height: 16),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
  ]) {
    return CustomTextField(
      controller: controller,
      keyboardType: keyboardType,
      labelText: label,
      prefixIcon: Icon(icon),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                _currentPage == 0 ? Navigator.pop(context) : _previousSlide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: const Text('Back'),
            ),

            ElevatedButton(
              onPressed: _currentPage == 0 ? _nextSlide : _saveCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentPage == 0
                    ? Colors.amber
                    : Color(0xFF145888),
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _currentPage == 0 ? 'Next' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Positioned(
          bottom: 30,
          left: 40,
          child: Row(
            children: [
              _buildProgressDot(_currentPage == 0),
              const SizedBox(width: 8),
              _buildProgressDot(_currentPage == 1),
            ],
          ),
        ),
      ],
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
}
