import 'package:flutter/material.dart';


class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLanguage;
  String _searchQuery = "";

  final List<Map<String, String>> _languages = [
    {"name": "English (UK)", "region": "United Kingdom"},
    {"name": "English (US)", "region": "United States"},
    {"name": "English (Ireland)", "region": "Ireland"},
    {"name": "Português (PT)", "region": "Portugal"},
    {"name": "Deutsch (DE)", "region": "Germany"},
    {"name": "Italiano (IT)", "region": "Italy"},
    {"name": "Español (ES)", "region": "Spain"},
    {"name": "Français (FR)", "region": "France"},
    {"name": "Amharic (ET)", "region": "Ethiopia"},
    {"name": "Arabic (SA)", "region": "Saudi Arabia"},
  ];

  void _onGoPressed() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 7, 69, 204), // Bright blue top-left
                      Color.fromARGB(255, 14, 103, 236), // Light blue-white
                      Color.fromARGB(255, 111, 172, 151), // Aqua
                      Color.fromARGB(255, 2, 71, 219), // Bright blue bottom-right
                    ],
                    stops: [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 70),
              const SizedBox(height: 16),
              const Text(
                "Language Selected!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You selected $_selectedLanguage.",
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/free-trial-page');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 5, 94, 247),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Continue", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = _languages
        .where((lang) => lang["name"]!
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 81, 255), // Bright blue top-left
              Color.fromARGB(255, 80, 147, 247), // Light blue-white
              Color.fromARGB(255, 88, 248, 195), // Light blue-white
              Color.fromARGB(255, 0, 81, 255), // Bright blue bottom-right
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                const Text(
                  "Select Language",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Search and Go button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: "Search",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: _selectedLanguage == null
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF002244),
                                  Color(0xFF00B4FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: _selectedLanguage == null
                            ? Colors.grey.shade400
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed:
                            _selectedLanguage == null ? null : _onGoPressed,
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        tooltip: "Go",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Scrollable Language List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: filteredLanguages.map((lang) {
                        final selected = _selectedLanguage == lang["name"];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedLanguage = lang["name"];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (selected)
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected
                                      ? Colors.blueAccent
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang["name"]!,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      lang["region"]!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
