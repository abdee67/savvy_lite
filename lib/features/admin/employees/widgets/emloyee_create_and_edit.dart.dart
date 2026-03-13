import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class EmployeeFormPage extends StatefulWidget {
  final Employee? employee;
  final AuthBloc authBloc;

  const EmployeeFormPage({super.key, this.employee, required this.authBloc});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _employeeIdController;
  late TextEditingController _phoneHomeController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  late TextEditingController _hireDateController;

  String? _selectedTitle;
  String? _selectedGender;
  final String _country = 'Ethiopia';

  final List<String> _titles = ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'];
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.employee != null) {
      context.read<EmployeeBloc>().add(SetEmployeeForm(widget.employee!));
    }
  }

  void _initializeControllers() {
    final employee = widget.employee ?? Employee.empty();

    _firstNameController = TextEditingController(text: employee.nameFirst);
    _lastNameController = TextEditingController(text: employee.nameLast);
    _middleNameController = TextEditingController(text: employee.nameMiddle);
    _employeeIdController = TextEditingController(text: employee.employeeId);
    _phoneHomeController = TextEditingController(text: employee.phoneHome);
    _emailController = TextEditingController(text: employee.email);
    _cityController = TextEditingController(text: employee.city);
    _addressController = TextEditingController(text: employee.address);
    _birthDateController = TextEditingController(text: employee.birthDate);
    _hireDateController = TextEditingController(text: employee.hireDate);

    _selectedTitle = employee.title;
    _selectedGender = employee.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _employeeIdController.dispose();
    _phoneHomeController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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

  void _previousSlide() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final employee = Employee(
        id: widget.employee?.id ?? 0,
        employeeId: _employeeIdController.text.isEmpty
            ? null
            : _employeeIdController.text,
        nameFirst: _firstNameController.text,
        nameLast: _lastNameController.text,
        nameMiddle: _middleNameController.text.isEmpty
            ? ''
            : _middleNameController.text,
        email: _emailController.text,
        phoneHome: _phoneHomeController.text,
        title: _selectedTitle,
        gender: _selectedGender,
        country: _country,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        birthDate: _birthDateController.text.isEmpty
            ? null
            : _birthDateController.text,
        hireDate: _hireDateController.text.isEmpty
            ? null
            : _hireDateController.text,
        company: widget.authBloc.state.companyId, // Get from auth bloc
        branch: widget.authBloc.state.branchId, // Get from auth bloc
      );

      if (widget.employee == null) {
        context.read<EmployeeBloc>().add(CreateEmployee(employee));
      } else {
        context.read<EmployeeBloc>().add(UpdateEmployee(employee));
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
          widget.employee == null
              ? 'Employee created successfully!'
              : 'Employee updated successfully!',
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
          widget.employee == null ? 'Create Employee' : 'Edit Employee',
        ),
        backgroundColor: Color(0xFF145888),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocListener<EmployeeBloc, EmployeeState>(
          listener: (context, state) {
            if (state.status == EmployeeStatus.failure) {
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
              // Progress Indicator
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressStep(1, 'Basic Info', _currentPage >= 0),
                    _buildProgressStep(2, 'Details', _currentPage >= 1),
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
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [_buildSlide1(), _buildSlide2()],
                  ),
                ),
              ),
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
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
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
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade600,
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
        horizontal: isTablet ? 80 : 28,
        vertical: isTablet ? 60 : 40,
      ),
      child: Column(
        children: [
          _buildTextField(
            _firstNameController,
            'First Name *',
            Icons.person,
            TextInputType.text,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _lastNameController,
            'Last Name *',
            Icons.person_outline,
            TextInputType.text,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _middleNameController,
            'Middle Name',
            Icons.person_outlined,
            TextInputType.text,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _employeeIdController,
            'Employee ID',
            Icons.badge,
            TextInputType.text,
            20,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _phoneHomeController,
            'Home Phone *',
            Icons.phone,
            TextInputType.phone,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _emailController,
            'Email *',
            Icons.email,
            TextInputType.emailAddress,
            255,
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
        horizontal: isTablet ? 80 : 28,
        vertical: isTablet ? 60 : 40,
      ),
      child: Column(
        children: [
          _buildDropdown(_titles, _selectedTitle, 'Title', Icons.title, (
            value,
          ) {
            setState(() => _selectedTitle = value);
          }),
          const SizedBox(height: 16),
          _buildDropdown(
            _genders,
            _selectedGender,
            'Gender',
            Icons.transgender,
            (value) {
              setState(() => _selectedGender = value);
            },
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField('Country', _country, Icons.flag),
          const SizedBox(height: 16),
          _buildTextField(
            _cityController,
            'City',
            Icons.location_city,
            TextInputType.text,
            45,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _addressController,
            'Address',
            Icons.home,
            TextInputType.text,
            45,
          ),
          const SizedBox(height: 16),
          _buildDateField(_birthDateController, 'Birth Date'),
          const SizedBox(height: 16),
          _buildDateField(_hireDateController, 'Hire Date'),
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
        if (label.contains('Email') && value!.isNotEmpty) {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String? value,
    String label,
    IconData icon,
    Function(String?) onChanged,
  ) {
    return CustomDropdown<String>(
      value: value,
      labelText: label,
      prefixIcon: Icon(icon),
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return CustomTextField(
      readOnly: true,
      value: value,
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return CustomTextField(
      controller: controller,
      readOnly: true,
      labelText: label,
      prefixIcon: Icon(Icons.calendar_today),
      onTap: () => _selectDate(controller),
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
              onPressed: _currentPage == 0 ? _nextSlide : _saveEmployee,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildProgressDot(_currentPage == 0),
            const SizedBox(width: 8),
            _buildProgressDot(_currentPage == 1),
          ],
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
