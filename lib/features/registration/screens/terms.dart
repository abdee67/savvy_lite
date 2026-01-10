import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/auth/screens/sign_in/login_screen.dart';
import 'package:savvy_stock/features/registration/screens/company_form.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFF145888),
                      fontSize: 21,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '1. Terms',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tellus at sit ante rutrum suspendisse pretium, vitae vel dignissim. '
                    'Nunc, scelerisque adipiscing condimentum massa dignissim tortor leo lacus. '
                    'Sapien felis ultrices fringilla nisi sit nibh. Etiam volutpat nisl ornare '
                    'lorem mus at a, et pulvinar.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '2. Use License',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fermentum erat nisl duis varius risus. Augue ac facilisi porta metus enim. '
                    'Ullamcorper lacus praesent rhoncus, sapien rutrum nulla mattis vitae ultrices.\n\n'
                    'Augue ac facilisi porta metus enim. Ullamcorper lacus praesent rhoncus, sapien rutrum nulla mattis vitae ultrices.\n\n'
                    'Nunc, scelerisque adipiscing condimentum massa dignissim tortor leo lacus.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '3. Limitation',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Aliquam eget purus sit malesuada tempor euismod. Eget commodo ultricies ut elit '
                    'hendrerit risus. Elementum tellus nisl lectus bibendum malesuada orci dui. '
                    'Nunc pharetra.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),

            // Bottom blur and buttons overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.8),
                      Colors.white,
                    ],
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 0,
                    sigmaY: 0,
                    tileMode: TileMode.clamp,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decline Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CompanyForm(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD5D5D5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Decline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Accept Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF145888),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
