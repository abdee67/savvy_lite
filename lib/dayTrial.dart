import 'package:flutter/material.dart';

class TrialPage extends StatefulWidget {
  const TrialPage({super.key});

  @override
  State<TrialPage> createState() => _TrialPageState();
}

class _TrialPageState extends State<TrialPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Dark Header Section
                Container(
                  width: double.infinity,
                  height: isSmallScreen ? 320 : (isTablet ? 450 : 405),
                  decoration: const BoxDecoration(color: Color(0xFF383838)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40.0 : 24.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 40 : 60),

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
                              fontSize: isTablet
                                  ? 40
                                  : (isSmallScreen ? 28 : 34),
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

                        const Spacer(),

                        // Up Arrow Icon
                        Container(
                          width: isTablet ? 40 : 34,
                          height: isTablet ? 70 : 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 20 : 17,
                            ),
                          ),
                          child: Icon(
                            Icons.keyboard_double_arrow_up,
                            color: const Color(0xFF383838),
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                      ],
                    ),
                  ),
                ),

                // White Content Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Get started here
                      Row(
                        children: [
                          const Text(
                            'Get Started Here',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 100,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: const Color(0xFF4DE89F),
                            ),
                            child: Stack(
                              children: [
                                // Toggle background with "EN" and "عر" text
                                Positioned(
                                  left: 8,
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
                                const Positioned(
                                  left: 12,
                                  top: 10,
                                  child: Text(
                                    'EN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4DE89F),
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  right: 12,
                                  top: 10,
                                  child: Text(
                                    'عر',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Form Fields
                      _buildTextField('Name', isTablet),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildTextField('Email', isTablet),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildTextField('Password', isTablet),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildTextField('Confirm Password', isTablet),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Sign Up Button
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
                            // Handle sign up logic
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
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Divider with "or"
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.grey, thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.grey, thickness: 1),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Company Button
                      Container(
                        width: double.infinity,
                        height: isTablet ? 56 : 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 28 : 25,
                          ),
                          border: Border.all(
                            color: const Color(0xFF4DE89F),
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle company sign up
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4DE89F),
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
                                'Company',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4DE89F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: isTablet ? 24 : 20,
                                height: isTablet ? 24 : 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4DE89F),
                                  borderRadius: BorderRadius.circular(
                                    isTablet ? 12 : 10,
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: isTablet ? 18 : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, bool isTablet) {
    return SizedBox(
      height: isTablet ? 60 : 56,
      child: TextField(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: isTablet ? 18 : 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
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
}
