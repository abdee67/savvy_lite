import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/onboarding/models/trial_model.dart';
import 'package:savvy_stock/features/onboarding/widgets/language_toggle.dart';
import 'package:savvy_stock/features/onboarding/widgets/trial_header.dart';
import 'package:savvy_stock/features/onboarding/widgets/trial_wizard.dart';
import 'package:savvy_stock/features/onboarding/widgets/user_type_dropdown.dart';

class TrialPageRefactored extends StatefulWidget {
  const TrialPageRefactored({super.key});

  @override
  State<TrialPageRefactored> createState() => _TrialPageRefactoredState();
}

class _TrialPageRefactoredState extends State<TrialPageRefactored> {
  bool isEnglish = true;
  bool isFormExpanded = false;
  TrialFormData formData = TrialFormData();
  final GlobalKey<TrialWizardState> _wizardKey = GlobalKey<TrialWizardState>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          height:
              screenHeight -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
          child: Stack(
            children: [
              // Dark Header Section
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                right: 0,
                height: isFormExpanded ? 0 : screenHeight * 0.5,
                child: TrialHeader(
                  isTablet: isTablet,
                  isSmallScreen: isSmallScreen,
                ),
              ),

              // White Form Section
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                top: isFormExpanded ? 0 : screenHeight * 0.5,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40.0 : 24.0,
                    vertical: isFormExpanded ? 40.0 : 0.0,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: isFormExpanded
                              ? 20
                              : (isSmallScreen ? 40 : 60),
                        ),

                        // Language Toggle
                        LanguageToggle(
                          isEnglish: isEnglish,
                          onToggle: () {
                            setState(() {
                              isEnglish = !isEnglish;
                            });
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // User Type Dropdown
                        UserTypeDropdown(
                          selectedUserType: formData.userType,
                          isEnglish: isEnglish,
                          isTablet: isTablet,
                          onUserTypeSelected: (userType) {
                            setState(() {
                              formData = formData.copyWith(userType: userType);
                            });
                          },
                        ),

                        if (isFormExpanded) ...[
                          const SizedBox(height: 30),

                          // Trial Wizard
                          TrialWizard(
                            key: _wizardKey,
                            isEnglish: isEnglish,
                            isTablet: isTablet,
                            isSmallScreen: isSmallScreen,
                            formData: formData,
                            onFormDataChanged: (newFormData) {
                              setState(() {
                                formData = newFormData;
                              });
                            },
                            onSubmit: _handleFormSubmission,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Up/Down Arrow Button
              Positioned(
                top: isFormExpanded ? -32 : screenHeight * 0.5 - 32,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleFormExpansion,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: isTablet ? 40 : 34,
                      height: isTablet ? 70 : 64,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 17),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedRotation(
                          turns: isFormExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_double_arrow_up,
                            color: Colors.blue.shade900,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFormExpansion() {
    setState(() {
      isFormExpanded = !isFormExpanded;
      if (!isFormExpanded) {
        // Reset wizard when collapsing
        _wizardKey.currentState?.resetWizard();
      }
    });
  }

  void _handleFormSubmission() {
    // Handle form submission logic here
    if (kDebugMode) {
      developer.log('Form submitted with data: ${formData.toJson()}');
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnglish
              ? 'Application submitted successfully!'
              : 'تم إرسال الطلب بنجاح!',
        ),
        backgroundColor: const Color(0xFF4DE89F),
      ),
    );

    // Optionally navigate to another page or reset form
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NextPage()));
  }
}
