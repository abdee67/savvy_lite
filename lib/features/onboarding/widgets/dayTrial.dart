import 'package:flutter/material.dart';

class TrialPage extends StatefulWidget {
  const TrialPage({super.key});

  @override
  State<TrialPage> createState() => _TrialPageState();
}

class _TrialPageState extends State<TrialPage> {
  bool isEnglish = true;
  bool isFormExpanded = false;
  int currentFormStep = 0;
  String? selectedUserType;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Dark Header Section
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              top: 0,
              left: 0,
              right: 0,
              height: isFormExpanded
                  ? 0 // Completely hide black container when expanded
                  : screenHeight * 0.5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Color(0xFF383838)),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40.0 : 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 40),

                      // SIGN UP AND ENJOY text
                      Text(
                        'SIGN UP AND ENJOY',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // FREE 7-DAYS TRIAL
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isTablet ? 40 : (isSmallScreen ? 28 : 34),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          children: const [
                            TextSpan(
                              text: 'FREE ',
                              style: TextStyle(color: Color(0xFF4DE89F)),
                            ),
                            TextSpan(text: '7 - DAYS TRIAL'),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Include 1 branch + up to 5 users
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.white70,
                          ),
                          children: const [
                            TextSpan(text: 'Include 1'),
                            TextSpan(
                              text: ' branch',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(text: ' + up to'),
                            TextSpan(
                              text: ' 5 users',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // White Form Section
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              top: isFormExpanded
                  ? 0 // Start from top when expanded
                  : screenHeight * 0.5,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40.0 : 24.0,
                  vertical: isFormExpanded ? 20.0 : 0.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (!isFormExpanded) ...[
                        SizedBox(height: isSmallScreen ? 40 : 60),

                        // Get started here with language toggle
                        Row(
                          children: [
                            Text(
                              isEnglish ? 'Get Started Here' : 'ابدأ من هنا',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isEnglish = !isEnglish;
                                });
                              },
                              child: Container(
                                width: 100,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: const Color(0xFF4DE89F),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      left: isEnglish ? 8 : 56,
                                      top: 8,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 12,
                                      top: 10,
                                      child: Text(
                                        'EN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isEnglish
                                              ? const Color(0xFF4DE89F)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 12,
                                      top: 10,
                                      child: Text(
                                        'عر',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: !isEnglish
                                              ? const Color(0xFF4DE89F)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // User/Company Selection Dropdown
                        Container(
                          width: double.infinity,
                          height: isTablet ? 56 : 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4DE89F),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 28 : 25,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _showUserTypeDropdown(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4DE89F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 28 : 25,
                                ),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedUserType ??
                                      (isEnglish
                                          ? 'Select User Type'
                                          : 'اختر نوع المستخدم'),
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: isTablet ? 24 : 20,
                                  height: isTablet ? 24 : 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 12 : 10,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: const Color(0xFF4DE89F),
                                    size: isTablet ? 18 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Expanded state: Show language toggle, dropdown, and wizard
                        SizedBox(height: 20),

                        // Language toggle at the top
                        Row(
                          children: [
                            Text(
                              isEnglish ? 'Get Started Here' : 'ابدأ من هنا',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isEnglish = !isEnglish;
                                });
                              },
                              child: Container(
                                width: 100,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: const Color(0xFF4DE89F),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      left: isEnglish ? 8 : 56,
                                      top: 8,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 12,
                                      top: 10,
                                      child: Text(
                                        'EN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isEnglish
                                              ? const Color(0xFF4DE89F)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 12,
                                      top: 10,
                                      child: Text(
                                        'عر',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: !isEnglish
                                              ? const Color(0xFF4DE89F)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // User Type Dropdown
                        Container(
                          width: double.infinity,
                          height: isTablet ? 56 : 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4DE89F),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 28 : 25,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _showUserTypeDropdown(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4DE89F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 28 : 25,
                                ),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedUserType ??
                                      (isEnglish
                                          ? 'Select User Type'
                                          : 'اختر نوع المستخدم'),
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: isTablet ? 24 : 20,
                                  height: isTablet ? 24 : 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 12 : 10,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: const Color(0xFF4DE89F),
                                    size: isTablet ? 18 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Page Indicators
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: currentFormStep == index ? 12 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: currentFormStep == index
                                    ? const Color(0xFF4DE89F)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 20),

                        // Swipeable Wizard Pages
                        SizedBox(
                          height:
                              screenHeight * 0.6, // Fixed height for PageView
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentFormStep = index;
                              });
                            },
                            children: [
                              // Page 1: Personal Information
                              _buildWizardPage(
                                title: isEnglish
                                    ? 'Personal Information'
                                    : 'معلومات شخصية',
                                children: [
                                  _buildTextField(
                                    isEnglish ? 'Full Name' : 'الاسم الكامل',
                                    isTablet,
                                    false,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTextField(
                                    isEnglish ? 'Email' : 'البريد الإلكتروني',
                                    isTablet,
                                    false,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTextField(
                                    isEnglish ? 'Phone Number' : 'رقم الهاتف',
                                    isTablet,
                                    false,
                                  ),
                                ],
                                isTablet: isTablet,
                                isSmallScreen: isSmallScreen,
                              ),

                              // Page 2: Account Setup
                              _buildWizardPage(
                                title: isEnglish
                                    ? 'Account Setup'
                                    : 'إعداد الحساب',
                                children: [
                                  _buildTextField(
                                    isEnglish ? 'Username' : 'اسم المستخدم',
                                    isTablet,
                                    false,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTextField(
                                    isEnglish ? 'Password' : 'كلمة المرور',
                                    isTablet,
                                    false,
                                    isPassword: true,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTextField(
                                    isEnglish
                                        ? 'Confirm Password'
                                        : 'تأكيد كلمة المرور',
                                    isTablet,
                                    false,
                                    isPassword: true,
                                  ),
                                ],
                                isTablet: isTablet,
                                isSmallScreen: isSmallScreen,
                              ),

                              // Page 3: Business Information
                              _buildWizardPage(
                                title: isEnglish
                                    ? 'Business Information'
                                    : 'معلومات العمل',
                                children: [
                                  _buildTextField(
                                    isEnglish ? 'Business Name' : 'اسم العمل',
                                    isTablet,
                                    false,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTextField(
                                    isEnglish ? 'Business Type' : 'نوع العمل',
                                    isTablet,
                                    false,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTextField(
                                    isEnglish ? 'Industry' : 'الصناعة',
                                    isTablet,
                                    false,
                                  ),
                                ],
                                isTablet: isTablet,
                                isSmallScreen: isSmallScreen,
                              ),

                              // Page 4: Confirmation
                              _buildWizardPage(
                                title: isEnglish ? 'Confirmation' : 'تأكيد',
                                children: [
                                  Text(
                                    isEnglish
                                        ? 'Review your information and submit'
                                        : 'راجع معلوماتك وأرسل',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isTablet ? 40 : 30),
                                  SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 56 : 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Handle form submission
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4DE89F,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            isTablet ? 28 : 25,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isEnglish
                                            ? 'Submit Application'
                                            : 'إرسال الطلب',
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                isTablet: isTablet,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ),

                        // Navigation Buttons
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Button
                            if (currentFormStep > 0)
                              TextButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEnglish
                                          ? Icons.arrow_back_ios
                                          : Icons.arrow_forward_ios,
                                      size: 16,
                                      color: const Color(0xFF4DE89F),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      isEnglish ? 'Previous' : 'السابق',
                                      style: TextStyle(
                                        color: const Color(0xFF4DE89F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const SizedBox.shrink(),

                            // Next Button
                            if (currentFormStep < 3)
                              TextButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isEnglish ? 'Next' : 'التالي',
                                      style: TextStyle(
                                        color: const Color(0xFF4DE89F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      isEnglish
                                          ? Icons.arrow_forward_ios
                                          : Icons.arrow_back_ios,
                                      size: 16,
                                      color: const Color(0xFF4DE89F),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Up/Down Arrow Button positioned between containers
            Positioned(
              top: isFormExpanded
                  ? -32 // Position at very top when expanded
                  : screenHeight * 0.5 - 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFormExpanded = !isFormExpanded;
                      if (!isFormExpanded) {
                        currentFormStep = 0; // Reset wizard when collapsing
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: isTablet ? 40 : 34,
                    height: isTablet ? 70 : 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 17),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 500),
                      turns: isFormExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_double_arrow_up,
                        color: const Color(0xFF383838),
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardPage({
    required String title,
    required List<Widget> children,
    required bool isTablet,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40.0 : 24.0,
        vertical: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String labelText,
    bool isTablet,
    bool isDarkTheme, {
    bool isPassword = false,
  }) {
    return SizedBox(
      height: isTablet ? 60 : 56,
      child: TextField(
        obscureText: isPassword,
        style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: isDarkTheme ? Colors.white70 : Colors.grey[600],
            fontSize: isTablet ? 18 : 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkTheme ? Colors.white54 : Colors.grey[300]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkTheme ? Colors.white54 : Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4DE89F), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 20 : 16,
          ),
        ),
      ),
    );
  }

  void _showUserTypeDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(isEnglish ? 'Individual User' : 'مستخدم فردي'),
                onTap: () {
                  setState(() {
                    selectedUserType = isEnglish
                        ? 'Individual User'
                        : 'مستخدم فردي';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(isEnglish ? 'Business Owner' : 'صاحب عمل'),
                onTap: () {
                  setState(() {
                    selectedUserType = isEnglish
                        ? 'Business Owner'
                        : 'صاحب عمل';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(isEnglish ? 'Company Admin' : 'مسؤول شركة'),
                onTap: () {
                  setState(() {
                    selectedUserType = isEnglish
                        ? 'Company Admin'
                        : 'مسؤول شركة';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
