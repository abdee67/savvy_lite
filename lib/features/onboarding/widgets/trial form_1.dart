import 'package:flutter/material.dart';

class TrialSetupPage extends StatelessWidget {
  const TrialSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController companyName = TextEditingController();
    final TextEditingController tinNumber = TextEditingController();
    final TextEditingController phone = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 🔹 Blue-black top section
                Container(
                  width: double.infinity,
                  color: const Color(0xFF145888),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Start your free ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '7-day trial',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: ' / package includes ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '1 branch',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: ' and up to ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '5 users',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: ' at no cost.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 🔸 White profile form section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Profile Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Company Name
                        TextField(
                          controller: companyName,
                          decoration: const InputDecoration(
                            labelText: "Company Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Tin Number
                        TextField(
                          controller: tinNumber,
                          decoration: const InputDecoration(
                            labelText: "TIN Number",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Company Phone
                        TextField(
                          controller: phone,
                          decoration: const InputDecoration(
                            labelText: "Company Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Company Category Dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Company Category",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: "Retail", child: Text("Retail")),
                            DropdownMenuItem(
                                value: "Wholesale", child: Text("Wholesale")),
                            DropdownMenuItem(
                                value: "Service", child: Text("Service")),
                          ],
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ⬇️ Amber Downward Button
            Positioned(
              bottom: 30,
              right: MediaQuery.of(context).size.width / 2 - 25,
              child: FloatingActionButton(
                backgroundColor: Colors.amber,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
