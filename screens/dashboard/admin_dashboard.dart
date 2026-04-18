import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'admin_users_page.dart';
import 'admin_projects_page.dart';
import 'admin_analytics_page.dart';
import 'admin_settings_page.dart';

/* ================= DASHBOARD ================= */
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  bool sidebarCollapsed = false;

  static const Color sidebarBg = Color(0xFFF8F9FA);
  static const Color contentBg = Color(0xFFF7F9FC);
  static const Color accentColor = Color(0xFF367CF7);

  final menuLabels = [
    "Dashboard",
    "Users",
    "Projects",
    "Analytics",
    "Settings"
  ];

  final menuIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.folder,
    Icons.insights,
    Icons.settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          const _AdminHeader(),
          Expanded(
            child: Row(
              children: [
                _AdminSidebar(
                  collapsed: sidebarCollapsed,
                  toggleCollapse: () =>
                      setState(() => sidebarCollapsed = !sidebarCollapsed),
                  selectedIndex: selectedIndex,
                  onSelect: (i) => setState(() => selectedIndex = i),
                  onLogout: _logout,
                  menuLabels: menuLabels,
                  menuIcons: menuIcons,
                  bgColor: sidebarBg,
                  accentColor: accentColor,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Container(
                    color: contentBg,
                    padding: const EdgeInsets.all(24),
                    child: IndexedStack(
                      index: selectedIndex,
                      children: const [
                        AdminHomePage(),
                        AdminUsersPage(),
                        AdminProjectsPage(),
                        AdminAnalyticsPage(),
                        AdminSettingsPage(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}

/* ================= HEADER ================= */
class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFF4C97FF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "Admin Panel",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

/* ================= SIDEBAR ================= */
class _AdminSidebar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback toggleCollapse;
  final int selectedIndex;
  final Function(int) onSelect;
  final VoidCallback onLogout;
  final List<String> menuLabels;
  final List<IconData> menuIcons;
  final Color bgColor;
  final Color accentColor;

  const _AdminSidebar({
    required this.collapsed,
    required this.toggleCollapse,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.menuLabels,
    required this.menuIcons,
    required this.bgColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: collapsed ? 70 : 260,
      color: bgColor,
      child: Column(
        children: [
          IconButton(
            icon: Icon(collapsed ? Icons.arrow_right : Icons.arrow_left),
            onPressed: toggleCollapse,
            color: accentColor,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                ...menuLabels.asMap().entries.map((entry) {
                  final i = entry.key;
                  final active = selectedIndex == i;

                  return ListTile(
                    leading: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 40),
                      child: Icon(
                        menuIcons[i],
                        color: active ? accentColor : Colors.black54,
                      ),
                    ),
                    title: collapsed ? null : Text(menuLabels[i]),
                    selected: active,
                    selectedTileColor: accentColor.withOpacity(0.12),
                    onTap: () => onSelect(i),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  );
                }),
                const SizedBox(height: 16),
                ListTile(
                  leading: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 40),
                    child: const Icon(Icons.logout, color: Colors.redAccent),
                  ),
                  title: collapsed ? null : const Text("Logout"),
                  onTap: onLogout,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= ADMIN HOME ================= */
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _db = FirebaseFirestore.instance;

  int totalUsers = 0;
  int activeUsersToday = 0;
  int publicProjects = 0;
  int privateProjects = 0;
  List<int> last7DaysUsers = List.filled(7, 0);

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    debugPrint("🔵 FETCH STATS START");

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool isAdmin = false;
      final doc = await _db.collection('users').doc(user.uid).get();
      isAdmin = doc.data()?['role'] == 'admin';

      final publicSnap = await _db.collection('publicProjects').get();
      publicProjects = publicSnap.size;

      if (isAdmin) {
        final usersSnap = await _db.collection('users').get();
        totalUsers = usersSnap.size;

        privateProjects = 0;
        for (final u in usersSnap.docs) {
          try {
            final p = await _db
                .collection('users')
                .doc(u.id)
                .collection('projects')
                .get();
            privateProjects += p.size;
          } catch (_) {}
        }

        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day);
        final activeSnap = await _db
            .collection('users')
            .where('lastLogin',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .get();
        activeUsersToday = activeSnap.size;

        final base = DateTime(today.year, today.month, today.day);
        for (int i = 0; i < 7; i++) {
          final s = base.subtract(Duration(days: 6 - i));
          final e = s.add(const Duration(days: 1));
          final snap = await _db
              .collection('users')
              .where('lastLogin', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
              .where('lastLogin', isLessThan: Timestamp.fromDate(e))
              .get();
          last7DaysUsers[i] = snap.size;
        }
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 28,
          runSpacing: 28,
          children: [
            _statCard("Total Users", totalUsers, Colors.blue),
            _statCard("Total Projects", publicProjects + privateProjects,
                Colors.purple),
            _statCard("Active Users Today", activeUsersToday, Colors.green),
            _projectsChart(),
            _activeUsersLineChart(),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, Color accent) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _projectsChart() => _chartContainer(
        "Projects Distribution",
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (publicProjects + privateProjects + 5).toDouble(),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: ((publicProjects + privateProjects + 5) / 5)
                  .ceilToDouble(), // dynamic interval
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: ((publicProjects + privateProjects + 5) / 5)
                      .ceilToDouble(),
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    String label = value == 0 ? "Public" : "Private";
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: publicProjects.toDouble(),
                    width: 28,
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Colors.greenAccent, Colors.green],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (publicProjects + privateProjects + 5).toDouble(),
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
                showingTooltipIndicators: [0],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: privateProjects.toDouble(),
                    width: 28,
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.deepOrange],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (publicProjects + privateProjects + 5).toDouble(),
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
                showingTooltipIndicators: [0],
              ),
            ],
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String label = groupIndex == 0 ? 'Public' : 'Private';
                  return BarTooltipItem(
                    '$label\n${rod.toY.toInt()} Projects',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            borderData: FlBorderData(show: false),
            groupsSpace: 40,
          ),
          swapAnimationDuration: const Duration(milliseconds: 700),
          swapAnimationCurve: Curves.easeInOut,
        ),
      );

  Widget _activeUsersLineChart() => _chartContainer(
        "User Activity (Last 7 Days)",
        LineChart(
          LineChartData(
            minY: 0,
            maxY:
                (last7DaysUsers.reduce((a, b) => a > b ? a : b) + 3).toDouble(),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 1,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString()))),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text("D${v.toInt() + 1}"),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: last7DaysUsers
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                barWidth: 4,
                dotData: FlDotData(show: true),
                color: Colors.indigo,
              ),
            ],
          ),
        ),
      );

  Widget _chartContainer(String title, Widget chart) {
    return Container(
      width: 520,
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }
}
