import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  // Track the selected card
  String selectedCard = "Employee";

  // Descriptions for each card
  final Map<String, String> cardDescriptions = {
    "Employee": "Manage employee records and related information here.",
    "Sales": "Track and manage all your sales entries efficiently.",
    "Stock": "Add new items, categories, or services easily.",
    "Orders": "View and manage customer orders seamlessly.",
  };

  // Data sections for each card
  final Map<String, List<String>> cardActions = {
    "Employee": ["Employee Entry", "Employee List"],
    "Sales": ["Sales Entry", "Customer Entry"],
    "Stock": ["Add Product", "Add Customer"],
    "Orders": ["Order Entry", "Order History"],
  };
  // Map cards to icons
  final Map<String, IconData> cardIcons = {
    "Employee": Icons.person,
    "Sales": Icons.sell,
    "Stock": Icons.add_circle,
    "Orders": Icons.shopping_cart,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 375,
            minHeight: 812,
            maxWidth: MediaQuery.of(context).size.width,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(minHeight: 812),
            decoration: BoxDecoration(color: Colors.white),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Stack(
                children: [
                  // Background with radial gradient
                  Container(
                    width: double.infinity,
                    height: 167,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.5, -0.5),
                        radius: 2.5,
                        colors: [Color(0xFF383838), Color(0xFF565555)],
                        stops: [0.46, 1.0],
                      ),
                    ),
                  ),

                  // Main content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      _buildCardSection(),
                      _buildDataSection(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: _buildFooter(),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.black),
              ),
              const SizedBox(width: 16),
              const Text(
                'ABEBA ADMASU',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),

              // Three dot menu
              // Handle the button press, e.g., show a PopupMenuButton
              PopupMenuButton<String>(
                tooltip: 'More',
                iconColor: Colors.white,
                onSelected: (value) {
                  if (value == 'System Constants') {
                    context.push('/system_constants');
                  } else if (value == 'Logout') {
                    context.push('/login');
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    child: const Text('System Constants'),
                    onTap: () => context.push('/system_constants'),
                  ),
                  PopupMenuItem<String>(
                    child: const Text('Logout'),
                    onTap: () => context.push('/login'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 45),
        ],
      ),
    );
  }

  Widget _buildCardSection() {
    final cards = ["Employee", "Sales", "Stock", "Orders"];

    return Container(
      margin: const EdgeInsets.only(top: 0, left: 30, right: 30),
      padding: const EdgeInsets.all(0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0X00000000),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card buttons
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF383838),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: cards.map((card) {
                final isSelected = selectedCard == card;
                return TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCard = card;
                    });
                  },
                  child: isSelected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            card,
                            style: TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Icon(cardIcons[card], color: Colors.white),
                );
              }).toList(),
            ),
          ),

          // Description text
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            decoration: const BoxDecoration(
              color: Color(0xFF155888),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(18),
            child: Text(
              cardDescriptions[selectedCard] ?? "",
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    final actions = cardActions[selectedCard] ?? [];

    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // full width buttons
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed: () => _handleAction(action), // call handler
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                minimumSize: const Size(
                  double.infinity,
                  60,
                ), // full width, fixed height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Handle all button presses here
  void _handleAction(String action) {
    switch (action) {
      case "Sales Entry":
        // Example: Navigate to Sales Entry screen
        context.push('/customer-screen');
        break;

      case "Customer Entry":
        context.push('/customer-list');
        break;

      default:
        // Fallback: show a snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Clicked: $action")));
    }
  }

  Widget _buildFooter() {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: const Center(
        child: Text(
          'POWERED BY TECH EQUATIONS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w200,
          ),
        ),
      ),
    );
  }
}
