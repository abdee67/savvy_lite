import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:savvy_stock/features/registration/screens/address_form.dart';

class CompanyForm extends StatefulWidget {
  const CompanyForm({super.key});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  String selectedSignupType = "Company";
  String selectedCategory = "Pharmacy";
  bool _submitted = false;

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController tinController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with existing state if available
    final state = context.read<RegistrationBloc>().state;
    if (state.company.companyName.isNotEmpty) {
      companyNameController.text = state.company.companyName;
      tinController.text = state.company.tinNumber ?? '';
      phoneController.text = state.company.phoneNumber1 ?? '';
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    tinController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _saveAndNavigate() {
    setState(() {
      _submitted = true;
    });

    // Validate required fields
    if (companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save company data to BLoC
    final company = Company(
      id: 0,
      companyName: companyNameController.text.trim(),
      tinNumber: tinController.text.trim(),
      phoneNumber1: phoneController.text.trim(),
    );
    context.read<RegistrationBloc>().add(UpdateCompanyData(company));

    // Navigate to address form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<RegistrationBloc>(),
          child: const AddressFormPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isTablet = screen.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0051FF),
              Color(0xFF5093F7),
              Color(0xFF58F8C3),
              Color(0xFF0051FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 🔹 Scrollable Main Form
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 30 : 18,
                  vertical: isTablet ? 60 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Title
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Get started ",
                              style: TextStyle(
                                fontSize: isTablet ? 26 : 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const TextSpan(
                              text: "here",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // 🔹 Step Chips (Top Center)
                    Center(child: _buildStepChips()),

                    const SizedBox(height: 20),

                    // 🔹 Text Fields
                    _buildTextField(
                      "Company Name",
                      controller: companyNameController,
                      required: true,
                      maxLength: 150,
                      onChanged: (_) => setState(() {}),
                    ),
                    _buildTextField(
                      "TIN Number",
                      controller: tinController,
                      maxLength: 10,
                      onChanged: (_) => setState(() {}),
                    ),
                    _buildTextField(
                      "Company Phone",
                      controller: phoneController,
                      maxLength: 15,
                      onChanged: (_) => setState(() {}),
                    ),

                    // 🔹 Company Category Dropdown
                    _buildDropdownField(
                      label: "Company Category",
                      value: selectedCategory,
                      items: const ["Pharmacy", "Spare parts", "Supermarket"],
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                    ),

                    const SizedBox(height: 60),

                    // 🔹 Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _saveAndNavigate,
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
                          child: const Text(
                            "Next",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // 🔹 Bottom Progress Dots
              Positioned(
                bottom: 30,
                left: 40,
                child: Row(
                  children: [
                    _buildProgressDot(true),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Step Chips
  Widget _buildStepChips() {
    final steps = ["Company", "Address", "Branch", "Admin", "Confirm"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.map((step) {
        final isActive = step == "Company";
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            step,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🧾 Text Field
  Widget _buildTextField(
    String label, {
    bool required = false,
    int? maxLength,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    String? errorText;
    if (required && _submitted && (controller?.text.isEmpty ?? true)) {
      errorText = "This field is required";
    } else if (maxLength != null &&
        (controller?.text.length ?? 0) > maxLength) {
      errorText = "Must be $maxLength characters or less";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.amber,
        inputFormatters: [
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: required ? "$label *" : label,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 16),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.amber, width: 1.5),
          ),
          errorText: errorText,
        ),
      ),
    );
  }

  // 🧾 Dropdown Field (inline dropdown)
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.amber, width: 1.5),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.blueGrey.shade900,
            iconEnabledColor: Colors.white,
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // 🔹 Dropdown Row (for "Signing up as")
  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.blueGrey.shade900,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // 🔘 Progress Dots
  Widget _buildProgressDot(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.amber : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
}
