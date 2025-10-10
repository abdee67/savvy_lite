import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/images/onboarding_background.png",
            ), // Replace with your asset path
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content Area - You can add your onboarding content here
              Positioned.fill(
                child: Container(), // Placeholder for main content
              ),

              // Footer Section
              Positioned(
                bottom: isSmallScreen ? 16.0 : 32.0,
                left: 0,
                right: 0,
                child: _buildFooter(context, isSmallScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20.0 : 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contact Section
          _buildContactSection(isSmallScreen),

          SizedBox(height: isSmallScreen ? 16.0 : 24.0),

          // Copyright Section
          _buildCopyrightSection(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'Contact us:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 13.0 : 15.0,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4.0 : 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'info@techequations.com',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 10.0 : 11.0,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 24.0 : 32.0),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '(+251) ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 10.0 : 11.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: '935 72 4920',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 10.0 : 11.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCopyrightSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tech Equations Technology PLC.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12.0 : 14.0,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6.0 : 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmallScreen ? 12.0 : 14.0,
                height: isSmallScreen ? 12.0 : 14.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.0),
                ),
              ),
              SizedBox(width: isSmallScreen ? 6.0 : 8.0),
              Flexible(
                child: Text(
                  '2025 All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12.0 : 14.0,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
