import 'package:flutter/material.dart';
import '../dashboard/user_dashboard.dart';

class HomePage extends StatelessWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final blockCategories = [
      {
        'name': 'Motion',
        'icon': Icons.directions_run,
        'color': Colors.orange.shade50
      },
      {'name': 'Events', 'icon': Icons.event, 'color': Colors.purple.shade50},
      {
        'name': 'Sensing',
        'icon': Icons.remove_red_eye,
        'color': Colors.green.shade50
      },
      {'name': 'Logic', 'icon': Icons.memory, 'color': Colors.blue.shade50},
      {'name': 'Math', 'icon': Icons.calculate, 'color': Colors.yellow.shade50},
      {'name': 'Text', 'icon': Icons.text_fields, 'color': Colors.pink.shade50},
      {'name': 'Lists', 'icon': Icons.list, 'color': Colors.teal.shade50},
      {
        'name': 'Variables',
        'icon': Icons.storage,
        'color': Colors.lime.shade50
      },
      {'name': 'Control', 'icon': Icons.settings, 'color': Colors.cyan.shade50},
      {'name': 'Sound', 'icon': Icons.music_note, 'color': Colors.red.shade50},
    ];

    final featureCards = [
      {
        'title': 'Why Drag N Code',
        'description':
            'Drag N Code is the preferred choice for platforms aiming to deliver versatile and intuitive programming experiences.',
        'image': 'assets/images/feature_lightbulb.png'
      },
      {
        'title': 'Robust Library',
        'description':
            'The Drag N Code library offers a comprehensive suite of APIs and tools for a customizable coding environment.',
        'image': 'assets/images/feature_library.png'
      },
      {
        'title': 'Visual Interface',
        'description':
            'Interlocking graphical blocks represent code concepts, helping you learn programming without syntax worries.',
        'image': 'assets/images/feature_interface.png'
      },
      {
        'title': 'Cross-platform',
        'description':
            'Drag N Code works on all major browsers and devices, making learning consistent and flexible.',
        'image': 'assets/images/feature_crossplatform.png'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Drag N Code',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn coding visually with drag-and-drop blocks!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Block categories horizontal scroll
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: blockCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final block = blockCategories[index];
                    return CategoryCard(
                      name: block['name'] as String,
                      icon: block['icon'] as IconData,
                      color: block['color'] as Color,
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Feature cards centered horizontally
              Column(
                children: featureCards
                    .map((card) => Center(
                          child: FeatureCardWithImage(
                            title: card['title'] as String,
                            description: card['description'] as String,
                            image: card['image'] as String,
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 40),

              // Get Started button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => UserDashboard(uid: uid)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 70, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.indigo,
                  elevation: 6,
                  shadowColor: Colors.indigoAccent,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),

              const SizedBox(height: 30),

              // Bottom illustration full width, colorful with gradient overlay
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade100, Colors.purple.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/coding_blocks.png'),
                    fit: BoxFit.cover,
                    opacity: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Horizontal scrollable block cards
class CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  const CategoryCard(
      {super.key, required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 36, color: Colors.indigo.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Feature card with image/illustration
class FeatureCardWithImage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const FeatureCardWithImage(
      {super.key,
      required this.title,
      required this.description,
      required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo)),
                const SizedBox(height: 8),
                Text(description,
                    style:
                        const TextStyle(fontSize: 15, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
