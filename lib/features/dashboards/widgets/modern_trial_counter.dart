import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

class ModernTrialCounter extends StatelessWidget {
  final int daysRemaining;
  final DateTime validTo;

  const ModernTrialCounter({
    super.key,
    required this.daysRemaining,
    required this.validTo,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = daysRemaining <= 2;
    // Gradient colors
    final List<Color> gradientColors = isLow
        ? [
            const Color(0xFFD32F2F), // Red 700
            const Color(0xFFB71C1C), // Red 900
          ]
        : [
            const Color(0xFF1976D2), // Blue 700
            const Color(0xFF0D47A1), // Blue 900
          ];

    // Accent/Text color
    final Color accentColor = isLow
        ? const Color(0xFFFFC107)
        : Colors.amber; // Amber

    return Container(
          margin: const EdgeInsets.only(right: 8),
          // Container structure for the "Card" look
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: const ColorFilter.mode(
                Colors.transparent,
                BlendMode.srcOver,
              ), // Placeholder for glass if needed later
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon with Pulse
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLow ? Iconsax.timer_1 : Iconsax.calendar_tick,
                            color: accentColor,
                            size: 22,
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          duration: 2000.ms,
                        ),

                    const SizedBox(width: 12),

                    // Text Column
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIAL STATUS',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Horizontal Layout for Content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (daysRemaining < 1) ...[
                              Text(
                                'Ends',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ).animate().shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              Text(
                                DateFormat('hh:mm a').format(validTo),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ).animate().shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ],
                            if (daysRemaining > 0) ...[
                              Text(
                                '$daysRemaining',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ).animate().shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${daysRemaining == 1 ? 'Day' : 'Days'} Left',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ).animate().shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .slideY(
          begin: -1.5, // Start from above
          end: 0,
          duration: 800.ms,
          curve: Curves.elasticOut, // Bounce effect
        )
        .fadeIn(duration: 500.ms);
  }
}
