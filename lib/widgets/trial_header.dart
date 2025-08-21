import 'package:flutter/material.dart';

class TrialHeader extends StatelessWidget {
  final bool isTablet;
  final bool isSmallScreen;

  const TrialHeader({
    super.key,
    required this.isTablet,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.teal.shade600,
            Colors.lightBlueAccent.shade400,
            Colors.blue.shade900,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 40.0 : 24.0),
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
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // FREE 7-DAYS TRIAL
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: isTablet ? 40 : (isSmallScreen ? 21 : 28),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                children: const [
                  TextSpan(
                    text: 'FREE ',
                    style: TextStyle(color: Colors.amber),
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
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }
}
