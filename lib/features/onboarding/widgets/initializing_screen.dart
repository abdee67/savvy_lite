import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _imageController;
  late Animation<double> _centerGlowAnimation;
  late Animation<Offset> _imageDropAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // 🌈 Center glow background animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _centerGlowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    // 🪂 Drop + bounce animation for image
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _imageDropAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5), // start from above
      end: Offset.zero, // end at center
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeOutBack, // natural soft bounce
    ));

    // Small scale bounce when landing
    _bounceAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _imageController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Run the drop after frame build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _imageController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Animated background
          AnimatedBuilder(
            animation: _centerGlowAnimation,
            builder: (context, _) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 0, 81, 255), // Bright blue top-left
                      Color.fromARGB(255, 80, 147, 247), // Light blue-white
                      Color.fromARGB(255, 88, 248, 195), // Light blue-white
                      Color.fromARGB(255, 0, 81, 255), // Bright blue bottom-right
                    ],
                    stops: [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: screenSize.width * 0.8,
                    height: screenSize.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(_centerGlowAnimation.value),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 🪂 Image drops + bounce
          Center(
            child: SlideTransition(
              position: _imageDropAnimation,
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/onboarding_background.png',
                    fit: BoxFit.contain,
                    width: isSmallScreen ? 100 : 150,
                  ),
                ),
              ),
            ),
          ),

          // 📄 Footer text — no background, but shadowed for readability
          Positioned(
            bottom: isSmallScreen ? 16.0 : 32.0,
            left: 0,
            right: 0,
            child: _buildFooter(context, isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20.0 : 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContactSection(isSmallScreen),
          SizedBox(height: isSmallScreen ? 16.0 : 24.0),
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
            fontSize: isSmallScreen ? 14.0 : 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'info@techequations.com',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 11.0 : 13.0,
                  shadows: const [
                    Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
                  ],
                ),
              ),
            ),
            SizedBox(width: 24),
            Flexible(
              child: Text(
                '(+251) 935 72 4920',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 11.0 : 13.0,
                  shadows: const [
                    Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCopyrightSection(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'Tech Equations Technology PLC.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 12.0 : 14.0,
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          '© 2025 All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isSmallScreen ? 12.0 : 14.0,
            shadows: const [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }
}
