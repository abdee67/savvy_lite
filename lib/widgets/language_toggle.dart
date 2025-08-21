import 'package:flutter/material.dart';

class LanguageToggle extends StatelessWidget {
  final bool isEnglish;
  final VoidCallback onToggle;
  final String? label;
  final bool showLabel;

  const LanguageToggle({
    super.key,
    required this.isEnglish,
    required this.onToggle,
    this.label,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel =
        label ?? (isEnglish ? 'Get Started Here' : 'ابدأ من هنا');

    return Row(
      children: [
        if (showLabel) ...[
          Text(
            displayLabel,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
        ],
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 100,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0xFF155888),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
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
                      color: isEnglish ? const Color(0xFF4DE89F) : Colors.white,
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
    );
  }
}
