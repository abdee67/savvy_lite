import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:savvy_stock/features/registration/screens/branch_form.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final TextEditingController regionController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController woredaController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with existing state if available
    final state = context.read<RegistrationBloc>().state;
    if (state.company.region?.isNotEmpty == true) {
      regionController.text = state.company.region ?? '';
      cityController.text = state.company.city ?? '';
      stateController.text = state.company.state ?? '';
      woredaController.text = state.company.woreda ?? '';
      addressController.text = state.company.addressLine ?? '';
    }
  }

  @override
  void dispose() {
    regionController.dispose();
    cityController.dispose();
    stateController.dispose();
    woredaController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _saveAndNavigate() {
    if (regionController.text.isEmpty || cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }
    // Save address data to company in BLoC
    final bloc = context.read<RegistrationBloc>();
    final updatedCompany = bloc.state.company.copyWith(
      region: regionController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      woreda: woredaController.text.trim(),
      addressLine: addressController.text.trim(),
    );
    bloc.add(UpdateCompanyData(updatedCompany));

    // Navigate to branch form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const BranchFormScreen()),
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
              // 🔹 Scrollable main content
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 80 : 20,
                  vertical: isTablet ? 100 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Step indicators (Top)
                    Center(child: _buildStepDots()),

                    const SizedBox(height: 35),

                    // 🔹 Input fields
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
                    _buildTextField("State", controller: stateController),
                    _buildTextField("Woreda", controller: woredaController),
                    _buildTextField(
                      "Specific Address / Landmark",
                      controller: addressController,
                    ),

                    const SizedBox(height: 30),

                    // 🔹 Navigation buttons
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
                              horizontal: 60,
                              vertical: 16,
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

              // 🔹 Bottom progress dots
              Positioned(
                bottom: 30,
                left: 40,
                child: Row(
                  children: [
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(true),
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

  // 🌟 Step Dots (Top Center)
  Widget _buildStepDots() {
    final steps = ["Company", "Address", "Branch", "Admin", "Confirm"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.map((step) {
        final isActive = step == "Address";
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

  // 🧾 Text Field (Floating Label + Required)
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
          errorText: required && controller!.text.isEmpty
              ? "This field is required"
              : null,
        ),
      ),
    );
  }

  // 🔘 Bottom Progress Dots
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
