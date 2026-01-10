import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:savvy_stock/features/registration/screens/admin_form.dart';

class BranchFormScreen extends StatefulWidget {
  const BranchFormScreen({super.key});

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  bool sameAsCompany = false;

  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchPhoneController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with existing state if available
    final state = context.read<RegistrationBloc>().state;
    if (state.branch.description?.isNotEmpty == true) {
      branchNameController.text = state.branch.description ?? '';
      branchPhoneController.text = state.branch.branchPhone ?? '';
      regionController.text = state.branch.region ?? '';
      cityController.text = state.branch.city ?? '';
      addressController.text = state.branch.addressLine ?? '';
    }
  }

  @override
  void dispose() {
    branchNameController.dispose();
    branchPhoneController.dispose();
    regionController.dispose();
    cityController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _copyFromCompany() {
    if (sameAsCompany) {
      final company = context.read<RegistrationBloc>().state.company;
      setState(() {
        regionController.text = company.region ?? '';
        cityController.text = company.city ?? '';
        addressController.text = company.addressLine ?? '';
      });
    }
  }

  void _saveAndNavigate() {
    // Validate required fields
    if (branchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save branch data to BLoC
    final bloc = context.read<RegistrationBloc>();
    final branch = Branch(
      id: 0,
      description: branchNameController.text.trim(),
      branchPhone: branchPhoneController.text.trim(),
      region: regionController.text.trim(),
      city: cityController.text.trim(),
      addressLine: addressController.text.trim(),
      country: bloc.state.company.country,
    );
    bloc.add(UpdateBranchData(branch));

    // Navigate to admin form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const AdminFormScreen()),
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
              // 🔹 Scrollable Content
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 80 : 28,
                  vertical: isTablet ? 60 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Top Step Indicator
                    Center(child: _buildStepDots()),

                    const SizedBox(height: 25),

                    // 🔹 Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: sameAsCompany,
                          onChanged: (val) {
                            setState(() => sameAsCompany = val!);
                            _copyFromCompany();
                          },
                          activeColor: Colors.amber,
                          checkColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Branch address same as company",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // 🔹 Input Fields
                    _buildTextField(
                      "Branch Name",
                      controller: branchNameController,
                      required: true,
                    ),
                    _buildTextField(
                      "Branch Phone",
                      controller: branchPhoneController,
                    ),
                    _buildTextField(
                      "Region",
                      controller: regionController,
                      required: true,
                    ),
                    _buildTextField(
                      "City",
                      controller: cityController,
                      required: true,
                    ),
                    _buildTextField(
                      "Specific Address / Landmark",
                      controller: addressController,
                    ),

                    const SizedBox(height: 60),

                    // 🔹 Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _goBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Back",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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

              // 🔹 Bottom Progress Dots under Back Button
              Positioned(
                bottom: 30,
                left: 40,
                child: Row(
                  children: [
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(true),
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

  // 🌟 Step Dots (Top Center)
  Widget _buildStepDots() {
    final steps = ["Company", "Address", "Branch", "Admin", "Confirm"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.map((step) {
        final isActive = step == "Branch";
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  // 🧾 Text Field (Floating Label with Inline Required Asterisk)
  Widget _buildTextField(
    String label, {
    bool required = false,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.amber,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: required ? "$label *" : label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
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
      ),
    );
  }

  // 🔘 Progress Dots (Bottom Left)
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
