import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:savvy_stock/features/registration/screens/registration_confirmation.dart';

class AdminFormScreen extends StatefulWidget {
  const AdminFormScreen({super.key});

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with existing state if available
    final state = context.read<RegistrationBloc>().state;
    if (state.employee.nameFirst.isNotEmpty) {
      final nameParts = <String>[];
      if (state.employee.nameFirst.isNotEmpty) {
        nameParts.add(state.employee.nameFirst);
      }
      if (state.employee.nameMiddle.isNotEmpty) {
        nameParts.add(state.employee.nameMiddle);
      }
      if (state.employee.nameLast.isNotEmpty) {
        nameParts.add(state.employee.nameLast);
      }

      fullNameController.text = nameParts.join(' ');
      emailController.text = state.adminUser.userEmail ?? '';
      phoneController.text = state.employee.phone;
      usernameController.text = state.adminUser.userName ?? '';
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _goToConfirmation() {
    // Validate required fields
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password length
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse full name
    final nameParts = fullNameController.text.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final middleName = nameParts.length > 2
        ? nameParts.sublist(1, nameParts.length - 1).join(' ')
        : '';
    final lastName = nameParts.length > 1 ? nameParts.last : '';

    // Create employee
    final employee = Employee(
      id: 0,
      nameFirst: firstName,
      nameLast: lastName,
      nameMiddle: middleName,
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      title: 'Administrator',
    );

    // Create admin user
    final adminUser = UserModel(
      id: 0,
      userName: usernameController.text.trim(),
      userEmail: emailController.text.trim(),
      password: passwordController.text,
    );

    // Check if email is verified
    // Check if email is verified
    final state = context.read<RegistrationBloc>().state;
    if (state.verifiedEmail != emailController.text.trim()) {
      _showOtpDialog(context, emailController.text.trim());
      return;
    }

    // Check for validation errors
    if (state.validationErrors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fix errors: ${state.validationErrors.values.join(', ')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (state.isValidating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validating... please wait'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Update BLoC with employee and user data
    final bloc = context.read<RegistrationBloc>();
    bloc.add(UpdateEmployeeData(employee));
    bloc.add(
      UpdateAdminUserData(
        adminUser,
        confirmPassword: confirmPasswordController.text,
      ),
    );

    // Navigate to confirmation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const ConfirmationPage()),
      ),
    );
  }

  void _showOtpDialog(BuildContext context, String email) {
    final bloc = context.read<RegistrationBloc>();
    final otpController = TextEditingController();

    // Send OTP immediately
    bloc.add(SendEmailVerificationCode(email));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocConsumer<RegistrationBloc, RegistrationState>(
            listenWhen: (previous, current) {
              return previous.isValidating != current.isValidating ||
                  previous.verifiedEmail != current.verifiedEmail ||
                  previous.message != current.message ||
                  previous.resendCountdown != current.resendCountdown;
            },
            listener: (context, state) {
              if (state.verifiedEmail == email && !state.isValidating) {
                Navigator.pop(dialogContext); // Close dialog
                _goToConfirmation(); // Proceed to confirmation
              }
              if (state.message != null &&
                  state.verifiedEmail != email &&
                  !state.isValidating) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return AlertDialog(
                title: const Text('Verify Email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Enter the code sent to $email'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        border: OutlineInputBorder(),
                        hintText: 'Enter 8-digit code',
                      ),
                      onSubmitted: (value) {
                        if (!state.isValidating && value.isNotEmpty) {
                          bloc.add(
                            VerifyEmailVerificationCode(email, value.trim()),
                          );
                        }
                      },
                    ),
                    if (state.isValidating)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
                actions: [
                  if (state.resendCountdown > 0)
                    TextButton(
                      onPressed: null,
                      child: Text('Resend in ${state.resendCountdown}s'),
                    )
                  else
                    TextButton(
                      onPressed: state.isValidating
                          ? null
                          : () {
                              bloc.add(SendEmailVerificationCode(email));
                            },
                      child: const Text('Resend Code'),
                    ),
                  TextButton(
                    onPressed: state.isValidating
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: state.isValidating
                        ? null
                        : () {
                            if (otpController.text.isNotEmpty) {
                              bloc.add(
                                VerifyEmailVerificationCode(
                                  email,
                                  otpController.text.trim(),
                                ),
                              );
                            }
                          },
                    child: const Text('Verify'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
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
              // 🔹 Scrollable Form
              BlocBuilder<RegistrationBloc, RegistrationState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 30 : 18,
                      vertical: isTablet ? 100 : 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _buildStepDots()),

                        const SizedBox(height: 25),

                        _buildTextField(
                          "Full Name (First Middle Last)",
                          controller: fullNameController,
                          required: true,
                        ),
                        _buildTextField(
                          "Admin Email",
                          controller: emailController,
                          required: true,
                          isEmail: true,
                          errorText: state.validationErrors['email'],
                          onChanged: (value) {
                            context.read<RegistrationBloc>().add(
                              CheckEmailAvailability(value),
                            );
                          },
                        ),
                        _buildTextField(
                          "Admin Phone",
                          controller: phoneController,
                          required: true,
                          isPhone: true,
                        ),
                        _buildTextField(
                          "Username",
                          controller: usernameController,
                          required: true,
                          errorText: state.validationErrors['username'],
                          onChanged: (value) {
                            context.read<RegistrationBloc>().add(
                              CheckUsernameAvailability(value),
                            );
                          },
                        ),
                        _buildTextField(
                          "Password",
                          controller: passwordController,
                          obscure: true,
                          required: true,
                          isPassword: true,
                          showPassword: _showPassword,
                          toggleVisibility: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                        _buildTextField(
                          "Confirm Password",
                          controller: confirmPasswordController,
                          obscure: true,
                          required: true,
                          isPassword: true,
                          showPassword: _showConfirmPassword,
                          toggleVisibility: () {
                            setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Buttons Row (Responsive)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _goBack,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 18,
                                ),
                              ),

                              label: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  state.isValidating ||
                                      state.validationErrors.isNotEmpty
                                  ? null
                                  : _goToConfirmation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                              child: state.isValidating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Text(
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
                  );
                },
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
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(true),
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
        final isActive = step == "Admin";
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

  // 🧾 TextField with floating label + required asterisk inside label
  Widget _buildTextField(
    String label, {
    bool obscure = false,
    bool required = false,
    bool isPassword = false,
    bool isEmail = false,
    bool isPhone = false,
    bool showPassword = false,
    VoidCallback? toggleVisibility,
    TextEditingController? controller,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure && !showPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.amber,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isPhone
            ? TextInputType.phone
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: required ? "$label *" : label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.amber, width: 1.5),
          ),
          errorText: required && controller!.text.isEmpty
              ? 'This field is required'
              : errorText,
          errorMaxLines: 3,
        ),
        onChanged: onChanged,
      ),
    );
  }

  // 🔘 Small progress dot (bottom)
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
