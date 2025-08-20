import 'package:flutter/material.dart';
import '../models/trial_form_data.dart';
import '../utils/form_validators.dart';
import 'custom_text_field.dart';

class TrialWizard extends StatefulWidget {
  final bool isEnglish;
  final bool isTablet;
  final bool isSmallScreen;
  final TrialFormData formData;
  final Function(TrialFormData) onFormDataChanged;
  final VoidCallback? onSubmit;

  const TrialWizard({
    super.key,
    required this.isEnglish,
    required this.isTablet,
    required this.isSmallScreen,
    required this.formData,
    required this.onFormDataChanged,
    this.onSubmit,
  });

  @override
  State<TrialWizard> createState() => TrialWizardState();
}

class TrialWizardState extends State<TrialWizard> {
  late PageController _pageController;
  int currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessTypeController;
  late TextEditingController _industryController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.formData.fullName);
    _emailController = TextEditingController(text: widget.formData.email);
    _phoneController = TextEditingController(text: widget.formData.phoneNumber);
    _usernameController = TextEditingController(text: widget.formData.username);
    _passwordController = TextEditingController(text: widget.formData.password);
    _confirmPasswordController = TextEditingController(
      text: widget.formData.confirmPassword,
    );
    _businessNameController = TextEditingController(
      text: widget.formData.businessName,
    );
    _businessTypeController = TextEditingController(
      text: widget.formData.businessType,
    );
    _industryController = TextEditingController(text: widget.formData.industry);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  void _updateFormData() {
    final updatedData = widget.formData.copyWith(
      fullName: _fullNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      businessName: _businessNameController.text,
      businessType: _businessTypeController.text,
      industry: _industryController.text,
    );
    widget.onFormDataChanged(updatedData);
  }

  void _nextPage() {
    if (currentStep < 3) {
      _updateFormData();
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Page Indicators
          _buildPageIndicators(),
          const SizedBox(height: 20),

          // Wizard Pages
          SizedBox(
            height: widget.isSmallScreen ? 400 : 500,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              children: [
                _buildPersonalInfoPage(),
                _buildAccountSetupPage(),
                _buildBusinessInfoPage(),
                _buildConfirmationPage(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentStep == index ? 12 : 8,
          height: currentStep == index ? 12 : 8,
          decoration: BoxDecoration(
            color: currentStep == index
                ? const Color(0xFF4DE89F)
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildPersonalInfoPage() {
    return _buildWizardPage(
      title: widget.isEnglish ? 'Personal Information' : 'المعلومات الشخصية',
      children: [
        CustomTextField(
          labelText: widget.isEnglish ? 'Full Name' : 'الاسم الكامل',
          controller: _fullNameController,
          isTablet: widget.isTablet,
          validator: (value) => FormValidators.validateRequired(
            value,
            widget.isEnglish ? 'Full Name' : 'الاسم الكامل',
            widget.isEnglish,
          ),
          onChanged: (_) => _updateFormData(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: widget.isEnglish ? 'Email' : 'البريد الإلكتروني',
          controller: _emailController,
          isTablet: widget.isTablet,
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              FormValidators.validateEmail(value, widget.isEnglish),
          onChanged: (_) => _updateFormData(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: widget.isEnglish ? 'Phone Number' : 'رقم الهاتف',
          controller: _phoneController,
          isTablet: widget.isTablet,
          keyboardType: TextInputType.phone,
          validator: (value) =>
              FormValidators.validatePhone(value, widget.isEnglish),
          onChanged: (_) => _updateFormData(),
        ),
      ],
    );
  }

  Widget _buildAccountSetupPage() {
    return _buildWizardPage(
      title: widget.isEnglish ? 'Account Setup' : 'إعداد الحساب',
      children: [
        CustomTextField(
          labelText: widget.isEnglish ? 'Username' : 'اسم المستخدم',
          controller: _usernameController,
          isTablet: widget.isTablet,
          validator: (value) =>
              FormValidators.validateUsername(value, widget.isEnglish),
          onChanged: (_) => _updateFormData(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: widget.isEnglish ? 'Password' : 'كلمة المرور',
          controller: _passwordController,
          isTablet: widget.isTablet,
          isPassword: true,
          validator: (value) =>
              FormValidators.validatePassword(value, widget.isEnglish),
          onChanged: (_) => _updateFormData(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: widget.isEnglish
              ? 'Confirm Password'
              : 'تأكيد كلمة المرور',
          controller: _confirmPasswordController,
          isTablet: widget.isTablet,
          isPassword: true,
          validator: (value) => FormValidators.validateConfirmPassword(
            value,
            _passwordController.text,
            widget.isEnglish,
          ),
          onChanged: (_) => _updateFormData(),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoPage() {
    return _buildWizardPage(
      title: widget.isEnglish ? 'Business Information' : 'معلومات العمل',
      children: [
        CustomTextField(
          labelText: widget.isEnglish ? 'Business Name' : 'اسم العمل',
          controller: _businessNameController,
          isTablet: widget.isTablet,
          validator: (value) => FormValidators.validateRequired(
            value,
            widget.isEnglish ? 'Business Name' : 'اسم العمل',
            widget.isEnglish,
          ),
          onChanged: (_) => _updateFormData(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: widget.isEnglish ? 'Business Type' : 'نوع العمل',
          controller: _businessTypeController,
          isTablet: widget.isTablet,
          validator: (value) => FormValidators.validateRequired(
            value,
            widget.isEnglish ? 'Business Type' : 'نوع العمل',
            widget.isEnglish,
          ),
          onChanged: (_) => _updateFormData(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: widget.isEnglish ? 'Industry' : 'الصناعة',
          controller: _industryController,
          isTablet: widget.isTablet,
          validator: (value) => FormValidators.validateRequired(
            value,
            widget.isEnglish ? 'Industry' : 'الصناعة',
            widget.isEnglish,
          ),
          onChanged: (_) => _updateFormData(),
        ),
      ],
    );
  }

  Widget _buildConfirmationPage() {
    return _buildWizardPage(
      title: widget.isEnglish ? 'Confirmation' : 'تأكيد',
      children: [
        Text(
          widget.isEnglish
              ? 'Review your information and submit'
              : 'راجع معلوماتك وأرسل',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.isTablet ? 40 : 30),
        SizedBox(
          width: double.infinity,
          height: widget.isTablet ? 56 : 50,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _updateFormData();
                widget.onSubmit?.call();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DE89F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.isTablet ? 28 : 25),
              ),
            ),
            child: Text(
              widget.isEnglish ? 'Submit Application' : 'إرسال الطلب',
              style: TextStyle(
                fontSize: widget.isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardPage({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 40.0 : 24.0,
        vertical: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: widget.isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: widget.isSmallScreen ? 20 : 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (currentStep > 0)
          Expanded(
            child: SizedBox(
              height: widget.isTablet ? 50 : 44,
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4DE89F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.isTablet ? 25 : 22,
                    ),
                  ),
                ),
                child: Text(
                  widget.isEnglish ? 'Previous' : 'السابق',
                  style: TextStyle(
                    color: const Color(0xFF4DE89F),
                    fontSize: widget.isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (currentStep > 0 && currentStep < 3) const SizedBox(width: 16),
        if (currentStep < 3)
          Expanded(
            child: SizedBox(
              height: widget.isTablet ? 50 : 44,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DE89F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.isTablet ? 25 : 22,
                    ),
                  ),
                ),
                child: Text(
                  widget.isEnglish ? 'Next' : 'التالي',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void resetWizard() {
    setState(() {
      currentStep = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
