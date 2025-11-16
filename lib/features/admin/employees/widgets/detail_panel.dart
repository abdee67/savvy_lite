import 'package:flutter/material.dart';

class RolesAddPage01 extends StatefulWidget {
  const RolesAddPage01({super.key});

  @override
  State<RolesAddPage01> createState() => _RolesAddPage01State();
}

class _RolesAddPage01State extends State<RolesAddPage01> {
  final List<Employee> employees = [
    Employee(
      id: 'ESR 021',
      name: 'Meklit Mamo',
      role: 'Salesperson',
      editedDate: 'April 12',
      nationality: 'Ethiopian',
      city: 'Addis Ababa',
      phone: '(+251) 923 50 50 51',
      email: 'Meklitmamushet@gmail.com',
      address: 'Kolfe Keranio, W12',
      hireDate: 'September 12, 2024',
    ),
  ];

  int? expandedEmployeeIndex;

  void _toggleEmployee(int index) {
    setState(() {
      if (expandedEmployeeIndex == index) {
        expandedEmployeeIndex = null;
      } else {
        expandedEmployeeIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375;
    final cardWidth = screenWidth * 0.85;
    final cardSpacing = screenHeight * 0.02;

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          // Header Section
          _buildHeaderSection(isSmallScreen, screenWidth),

          // Search and Add Section
          _buildSearchSection(isSmallScreen, screenWidth),

          // Employees List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: cardSpacing),
              itemCount: employees.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: cardSpacing),
              itemBuilder: (context, index) {
                return _buildEmployeeCard(
                  employees[index],
                  index,
                  cardWidth,
                  isSmallScreen,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen, double screenWidth) {
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'EMPLOYEES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF145888),
                  fontSize: isSmallScreen ? 14 : 17,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                width: 106,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD9D9D9)),
              ),
            ],
          ),
          Text(
            'ROLES',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF145888),
              fontSize: isSmallScreen ? 7 : 9,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'USERS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF145888),
              fontSize: isSmallScreen ? 7 : 9,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isSmallScreen, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 12, right: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFE6E5E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: const Color(0xFF8E8E93), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: const Color(0xFF8E8E93),
                          fontSize: isSmallScreen ? 14 : 17,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    width: 35,
                    height: 35,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD5D5D5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'GO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
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
          const SizedBox(width: 12),
          Container(
            width: 65,
            height: 39,
            decoration: ShapeDecoration(
              color: const Color(0xFF145888),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                'ADD +',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 11 : 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(
    Employee employee,
    int index,
    double cardWidth,
    bool isSmallScreen,
  ) {
    final isExpanded = expandedEmployeeIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: cardWidth,
      height: isExpanded ? 500 : 156.49,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // Background layers (only visible when expanded)
          if (isExpanded) ...[
            // Gray background
            Positioned(
              top: 20,
              child: Container(
                width: cardWidth,
                height: 144,
                decoration: ShapeDecoration(
                  color: const Color(0xFFCBCBCB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39),
                  ),
                ),
              ),
            ),
            // Yellow background
            Positioned(
              top: 47,
              child: Container(
                width: cardWidth,
                height: 387,
                decoration: ShapeDecoration(
                  color: const Color(0xFFFDD105),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
          ],

          // Main white card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            top: isExpanded ? 0 : 0,
            child: Container(
              width: cardWidth,
              height: 156.49,
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.id,
                              style: TextStyle(
                                color: const Color(0xFF887F7F),
                                fontSize: isSmallScreen ? 12 : 14,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              employee.name,
                              style: TextStyle(
                                color: const Color(0xFF373737),
                                fontSize: isSmallScreen ? 20 : 24,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              employee.role,
                              style: TextStyle(
                                color: const Color(0xFF4C3737),
                                fontSize: isSmallScreen ? 12 : 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Edited on ',
                              style: TextStyle(
                                color: const Color(0xFF887F7F),
                                fontSize: isSmallScreen ? 8 : 10,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            TextSpan(
                              text: employee.editedDate,
                              style: TextStyle(
                                color: const Color(0xFF887F7F),
                                fontSize: isSmallScreen ? 8 : 10,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleEmployee(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF145888),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isExpanded ? 'See Less' : 'See More',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 10 : 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            Positioned(
              top: 180,
              left: 30,
              right: 30,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isExpanded ? 1.0 : 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Role:', employee.role),
                    _buildDetailRow('Nationality:', employee.nationality),
                    _buildDetailRow('City:', employee.city),
                    _buildDetailRow('Phone number:', employee.phone),
                    _buildDetailRow('Email:', employee.email),
                    _buildDetailRow('Address:', employee.address),
                    _buildDetailRow('Hired on:', employee.hireDate),

                    const SizedBox(height: 20),

                    // Privileges Section
                    _buildPrivilegesSection(isSmallScreen),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                color: Color(0xFF373737),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' $value',
              style: const TextStyle(
                color: Color(0xFF373737),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegesSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privileges',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF373737),
            fontSize: isSmallScreen ? 14 : 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // Privilege Buttons - Row 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPrivilegeButton('Report Access', isSmallScreen),
            _buildPrivilegeButton('Main inbox', isSmallScreen),
            _buildPrivilegeButton('Price leads', isSmallScreen),
          ],
        ),
        const SizedBox(height: 8),

        // Privilege Buttons - Row 2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPrivilegeButton('Store Price', isSmallScreen),
            _buildPrivilegeButton('Voided rec.', isSmallScreen),
            _buildPrivilegeButton('Change profile', isSmallScreen),
          ],
        ),
        const SizedBox(height: 16),

        // Role Management Section
        _buildRoleManagementSection(isSmallScreen),
      ],
    );
  }

  Widget _buildPrivilegeButton(String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFF145888),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFA9A9A9)),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 8 : 9,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRoleManagementSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security Role Chip
        Container(
          width: double.infinity,
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: const Color(0xFFE6E5E5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF145888),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Security',
                    style: TextStyle(
                      color: const Color(0xFF8E8E93),
                      fontSize: isSmallScreen ? 12 : 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                width: 35,
                height: 35,
                decoration: const ShapeDecoration(
                  color: Color(0xFFFDD105),
                  shape: CircleBorder(),
                ),
                child: const Icon(Icons.check, size: 20, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Role Action Buttons - Row 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRoleActionButton(
              'change Password',
              const Color(0xFF145888),
              isSmallScreen,
            ),
            _buildRoleActionButton(
              'Access to inbox',
              const Color(0xFFD7DDDA),
              isSmallScreen,
            ),
            _buildRoleActionButton(
              'Update price',
              const Color(0xFF145888),
              isSmallScreen,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Role Action Buttons - Row 2
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildRoleActionButton(
              'Store Price',
              const Color(0xFFD7DDDA),
              isSmallScreen,
            ),
            const SizedBox(width: 12),
            _buildRoleActionButton(
              'Dividend markup list',
              const Color(0xFFD7DDDA),
              isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleActionButton(String text, Color color, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 8 : 9,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String role;
  final String editedDate;
  final String nationality;
  final String city;
  final String phone;
  final String email;
  final String address;
  final String hireDate;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.editedDate,
    required this.nationality,
    required this.city,
    required this.phone,
    required this.email,
    required this.address,
    required this.hireDate,
  });
}
