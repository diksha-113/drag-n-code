import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'secrets.dart'; // <-- API key & CX

class LearnBlocksPage extends StatefulWidget {
  const LearnBlocksPage({super.key});

  @override
  State<LearnBlocksPage> createState() => _LearnBlocksPageState();
}

class _LearnBlocksPageState extends State<LearnBlocksPage> {
  final TextEditingController _searchController = TextEditingController();

  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Colors.black87;
  static const Color appBarColor = Color(0xFF6B8CE3);

  int? _selectedBlockIndex;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  final List<Map<String, dynamic>> blocks = const [
    {
      "title": "Motion",
      "emoji": "🏃",
      "icon": Icons.directions_run,
      "color": Color(0xFF4C97FF),
      "description": "Move sprites, turn, glide.",
      "details": [
        "Move sprite forward/backward",
        "Turn sprite left/right",
        "Go to x, y position",
        "Glide smoothly to a location",
        "Combine motion with events for dynamic scripts"
      ]
    },
    {
      "title": "Looks",
      "emoji": "🎨",
      "icon": Icons.brush,
      "color": Color(0xFFFFD966),
      "description": "Change costumes, say messages.",
      "details": [
        "Say or think messages",
        "Change size/color effects",
        "Switch costumes",
        "Show/hide sprite",
        "Use effects to enhance storytelling"
      ]
    },
    {
      "title": "Sound",
      "emoji": "🎵",
      "icon": Icons.volume_up,
      "color": Color(0xFF3CDA99),
      "description": "Play sounds, control volume.",
      "details": [
        "Play sound until done",
        "Stop all sounds",
        "Change volume",
        "Add background music or effects"
      ]
    },
    {
      "title": "Events",
      "emoji": "⚡",
      "icon": Icons.flash_on,
      "color": Color(0xFFFF6B6B),
      "description": "Start scripts using events.",
      "details": [
        "Start when green flag clicked",
        "Start on key press",
        "Broadcast messages",
        "Trigger actions across multiple sprites"
      ]
    },
    {
      "title": "Control",
      "emoji": "🔁",
      "icon": Icons.repeat,
      "color": Color(0xFF845EC2),
      "description": "Loops, waits, conditions.",
      "details": [
        "Repeat blocks",
        "Forever loops",
        "If / else conditions",
        "Wait for seconds",
        "Combine with operators for logic"
      ]
    },
    {
      "title": "Operators",
      "emoji": "➗",
      "icon": Icons.calculate,
      "color": Color(0xFF00CFFF),
      "description": "Math, logic, text operations.",
      "details": [
        "Addition, subtraction",
        "Comparison (>, <, =)",
        "Boolean logic (AND, OR)",
        "Join text",
        "Create dynamic calculations"
      ]
    },
  ];

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final url = Uri.parse(
          "https://www.googleapis.com/customsearch/v1?key=$googleApiKey&cx=$googleCx&q=$query+scratch+blocks");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>?;
        if (items != null) {
          _searchResults = items.map((item) {
            return {
              "title": item['title'] ?? "No title",
              "snippet": item['snippet'] ?? "",
              "link": item['link'] ?? "",
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text("Learn Blocks",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Row(
        children: [
          // ---------------- LEFT SIDE: Block List ----------------
          Container(
            width: 160,
            color: pageBg,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index];
                final selected = _selectedBlockIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBlockIndex = index),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Card(
                      color: selected ? blockColor(block['color']) : cardColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Icon(block['icon'],
                                size: 22,
                                color:
                                    selected ? Colors.white : Colors.black87),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                block['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ---------------- RIGHT SIDE: Details ----------------
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: _selectedBlockIndex == null
                  ? const Center(
                      child: Text(
                        "Select a block to view details",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blocks[_selectedBlockIndex!]['title'],
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            blocks[_selectedBlockIndex!]['description'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          const Text("What you can do:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          ...blocks[_selectedBlockIndex!]['details']
                              .map<Widget>((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            size: 18, color: Colors.black87),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 15))),
                                      ],
                                    ),
                                  )),
                          const SizedBox(height: 20),
                          // ---------------- SEARCH BAR ----------------
                          TextField(
                            controller: _searchController,
                            onSubmitted: _performSearch,
                            decoration: InputDecoration(
                              hintText: "Search blocks on the web...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _searchResults.isEmpty
                                  ? const SizedBox.shrink()
                                  : Column(
                                      children: _searchResults.map((res) {
                                        return GestureDetector(
                                          onTap: () async {
                                            final link = Uri.parse(res['link']);
                                            if (await canLaunchUrl(link))
                                              await launchUrl(link);
                                          },
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                  color: borderColor,
                                                  width: 1.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          res['title'],
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.close),
                                                        onPressed: () {
                                                          setState(() =>
                                                              _searchResults =
                                                                  []);
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(res['snippet'],
                                                      style: const TextStyle(
                                                          fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color blockColor(Color color) {
    // Slightly darken selected block
    return Color.alphaBlend(const Color(0xCC000000), color);
  }
}
