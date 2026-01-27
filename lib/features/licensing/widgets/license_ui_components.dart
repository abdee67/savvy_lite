import 'package:flutter/material.dart';

class LicenseWarningBanner extends StatelessWidget {
  final int daysRemaining;
  final VoidCallback? onRenewPressed;

  const LicenseWarningBanner({
    super.key,
    required this.daysRemaining,
    this.onRenewPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (daysRemaining > 15) return const SizedBox.shrink();

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (daysRemaining <= 0) {
      backgroundColor = Colors.red[900]!;
      textColor = Colors.white;
      icon = Icons.error;
      message = 'Your license has expired!';
    } else if (daysRemaining <= 7) {
      backgroundColor = Colors.orange[900]!;
      textColor = Colors.white;
      icon = Icons.warning;
      message = 'Your license expires in $daysRemaining days';
    } else {
      backgroundColor = Colors.blue[900]!;
      textColor = Colors.white;
      icon = Icons.info;
      message = 'Your license expires in $daysRemaining days';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRenewPressed != null && daysRemaining <= 15)
            ElevatedButton(
              onPressed: onRenewPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: backgroundColor,
              ),
              child: const Text('Renew Now'),
            ),
        ],
      ),
    );
  }
}

class LicenseStatusBadge extends StatelessWidget {
  final bool isValid;
  final bool isAboutToExpire;
  final int daysRemaining;

  const LicenseStatusBadge({
    super.key,
    required this.isValid,
    required this.isAboutToExpire,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (!isValid) {
      color = Colors.red;
      text = 'Invalid';
    } else if (daysRemaining <= 0) {
      color = Colors.red;
      text = 'Expired';
    } else if (isAboutToExpire) {
      color = Colors.orange;
      text = 'Expiring Soon';
    } else {
      color = Colors.green;
      text = 'Valid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const LicenseInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
