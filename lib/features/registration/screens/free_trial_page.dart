import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:savvy_stock/features/registration/screens/registration_wrapper.dart';

class TrialOptionScreen extends StatefulWidget {
  const TrialOptionScreen({super.key});

  @override
  State<TrialOptionScreen> createState() => _TrialOptionScreenState();
}

class _TrialOptionScreenState extends State<TrialOptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showNextPage = false;

  bool get isExpanded => _controller.value == 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _togglePanel() {
    if (isExpanded) {
      _controller.reverse();
      setState(() => _showNextPage = false);
    } else {
      _controller.forward();
      setState(() => _showNextPage = true);
    }
  }

  void _onVerticalDrag(DragEndDetails details) {
    if (details.primaryVelocity! < -100 && !_showNextPage) {
      _togglePanel();
    } else if (details.primaryVelocity! > 100 && _showNextPage) {
      _togglePanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onVerticalDragEnd: _onVerticalDrag,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double slideOffset =
                screenSize.height * (1 - _animation.value);

            return Stack(
              alignment: Alignment.center,
              children: [
                // 🔹 Background gradient for trial page
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 0, 81, 255),
                          Color.fromARGB(255, 80, 147, 247),
                          Color.fromARGB(255, 88, 248, 195),
                          Color.fromARGB(255, 0, 81, 255),
                        ],
                        stops: [0.0, 0.33, 0.66, 1.0],
                      ),
                    ),
                  ),
                ),

                // 🔹 Main trial content
                // Free Trial Text Section
                Positioned(
                  top: screenSize.height * 0.2,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SIGN UP AND ENJOY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'FREE ',
                              style: TextStyle(
                                color: Color(0xFFFDD105),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: '5-DAYS TRIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Includes 1 branch + up to 5 users',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // 🔹 Bottom white section with dropdown
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: screenSize.height * 0.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Get started ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'here',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF145888),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Signing up as',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                DropdownButton<String>(
                                  dropdownColor: Colors.blueGrey.shade900,
                                  value: 'Company',
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Company',
                                      child: Text(
                                        'Company',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Individual',
                                      child: Text(
                                        'Individual',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                  onChanged: (_) {},
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 100,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 TrialSetupPage slides up from bottom
                Positioned(
                  top: slideOffset,
                  left: 0,
                  right: 0,
                  height: screenSize.height,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        ignoring: !_showNextPage,
                        child: Transform.translate(
                          offset: Offset(0, slideOffset * 0.1),
                          child:
                              const RegistrationWrapper(), // Registration form with BLoC
                        ),
                      ),

                      // 🔹 Downward Amber Button at bottom center of TrialSetupPage
                      if (_showNextPage)
                        Positioned(
                          bottom:
                              30, // Position at very bottom of TrialSetupPage
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: GestureDetector(
                              onTap: _togglePanel,
                              child: Container(
                                width: 60,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: math.pi, // Points downward
                                  child: const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 🔹 Upward Amber Button (center between pages on trial screen)
                if (!_showNextPage)
                  Positioned(
                    top:
                        screenSize.height * 0.45 -
                        (_animation.value * screenSize.height * 0.3),
                    child: _buildAmberButton(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmberButton() {
    // The button height shrinks as animation moves toward the top
    final double height = 100 - (50 * _animation.value);
    final double borderRadius = 20 - (5 * _animation.value);

    return GestureDetector(
      onTap: _togglePanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: height,
        decoration: BoxDecoration(
          color: Color.lerp(
            Colors.amber.shade400,
            Colors.amber.shade200,
            _animation.value,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: _showNextPage ? math.pi : 0,
          child: Icon(
            Icons.keyboard_double_arrow_up_rounded,
            color: Colors.blueGrey.shade900,
            size: 34,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
