import 'package:flutter/material.dart';

class UserTypeDropdown extends StatelessWidget {
  final String? selectedUserType;
  final bool isEnglish;
  final Function(String) onUserTypeSelected;
  final bool isTablet;

  const UserTypeDropdown({
    super.key,
    required this.selectedUserType,
    required this.isEnglish,
    required this.onUserTypeSelected,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isTablet ? 56 : 50,
      decoration: BoxDecoration(
        color: const Color(0xFF155888),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 25),
      ),
      child: ElevatedButton(
        onPressed: () => _showUserTypeDropdown(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF155888),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 28 : 25),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign up as |',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedUserType ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: isTablet ? 24 : 20,
              height: isTablet ? 24 : 20,
              decoration: BoxDecoration(
                color: Color(0xFF155888),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                border: Border.all(color: Colors.white),
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
    );
  }

  void _showUserTypeDropdown(BuildContext context) {
    final userTypes = [
      {'en': 'Individual User', 'ar': 'مستخدم فردي'},
      {'en': 'Business Owner', 'ar': 'صاحب عمل'},
      {'en': 'Company Admin', 'ar': 'مدير شركة'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEnglish ? 'Select User Type' : 'اختر نوع المستخدم',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...userTypes.map((userType) {
                final displayText = isEnglish
                    ? userType['en']!
                    : userType['ar']!;
                final isSelected = selectedUserType == displayText;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      displayText,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF155888)
                            : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF155888),
                          )
                        : null,
                    onTap: () {
                      onUserTypeSelected(displayText);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
