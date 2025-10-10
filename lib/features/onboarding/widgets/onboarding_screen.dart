import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _bgController;
  late AnimationController _imageController;
  late Animation<double> _centerGlowAnimation;
  late Animation<Offset> _imageDropAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Animated center glow
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _centerGlowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    // Image drop + bounce
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _imageDropAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeOutBack,
    ));

    _bounceAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 80),
    ]).animate(CurvedAnimation(
      parent: _imageController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _imageController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _imageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _imageController.reset();
    _imageController.forward();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      _goToHome();
    }
  }

  void _skip() {
    _goToHome();
  }

  void _goToHome() {
    // Replace this with your real navigation
    Navigator.pushReplacementNamed(context, '/language-selection');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🌈 Animated gradient background
          AnimatedBuilder(
            animation: _centerGlowAnimation,
            builder: (context, _) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 0, 81, 255), // Bright blue top-left
                      Color.fromARGB(255, 80, 147, 247), // Light blue-white
                      Color.fromARGB(255, 88, 248, 195), // Aqua
                      Color.fromARGB(255, 0, 81, 255), // Bright blue bottom-right
                    ],
                    stops: [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
              );
            },
          ),

          // 📜 Swipeable onboarding pages
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildPage(
                image: 'assets/images/onboarding_background.png',
                title: 'Welcome to Tech Equations',
                subtitle:
                    'Innovating technology solutions that empower your business.',
              ),
              _buildPage(
                image: 'assets/images/onboarding_background.png',
                title: 'Seamless Integration',
                subtitle:
                    'Connecting your systems effortlessly across platforms.',
              ),
              _buildPage(
                image: 'assets/images/onboarding_background.png',
                title: 'Grow with Us',
                subtitle:
                    'Transform your ideas into powerful digital experiences.',
              ),
            ],
          ),

          // 🔘 Dots indicator
          Positioned(
            bottom: screenSize.height * 0.20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 10,
                  width: isActive ? 28 : 10,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),

          // 🎯 Buttons (Skip / Next / Get Started)
          Positioned(
            bottom: 90,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage < 2)
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black45)
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        const Color.fromARGB(255, 0, 81, 255), // Primary blue
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    _currentPage < 2 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🧊 Footer (always visible)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: _buildFooter(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String title,
    required String subtitle,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideTransition(
            position: _imageDropAnimation,
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: Image.asset(
                image,
                width: isSmall ? 200 : 260,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black45)
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
              color: Colors.white,
              height: 1.4,
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black38)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: const [
        Text(
          'Contact: info@techequations.com | (+251) 935 72 4920',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          '© 2025 Tech Equations Technology PLC. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }
}
