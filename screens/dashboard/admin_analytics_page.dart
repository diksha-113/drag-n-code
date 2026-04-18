import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  bool loading = true;
  int currentYear = DateTime.now().year;

  final Map<DateTime, Map<String, int>> dailyActionCounts = {};
  final Map<DateTime, int> dailyUsersCount = {};
  final Map<DateTime, int> dailyProjectsCount = {};
  final Map<DateTime, List<String>> dailyUsersMap = {};
  final Map<DateTime, List<String>> dailyProjectsMap = {};

  StreamSubscription<QuerySnapshot>? _userSub;
  StreamSubscription<QuerySnapshot>? _projectSub;

  final List<String> actionTypes = ['like', 'comment', 'view', 'share'];
  String? activeType;
  Map<String, int> maxCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchAllStats();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _projectSub?.cancel();
    super.dispose();
  }

  /// ===================== DATA FETCH =====================
  Future<void> _fetchAllStats() async {
    loading = true;
    setState(() {});

    // USERS
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snap) {
      dailyUsersCount.clear();
      dailyUsersMap.clear();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Skip if no timestamp
        final ts = (data['createdAt'] as Timestamp?)?.toDate().toUtc();
        if (ts == null) continue;

        final key = DateTime.utc(ts.year, ts.month, ts.day);

        dailyUsersCount[key] = (dailyUsersCount[key] ?? 0) + 1;

        // Safe name
        final name = data['name'] ?? "Unknown";
        dailyUsersMap[key] ??= [];
        dailyUsersMap[key]!.add(name);
      }
      if (mounted) setState(() {});
    });

    // PROJECTS + actions
    _projectSub = FirebaseFirestore.instance
        .collection('publicProjects')
        .snapshots()
        .listen((snap) {
      dailyProjectsCount.clear();
      dailyProjectsMap.clear();
      dailyActionCounts.clear();
      maxCounts.clear();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final ts = (data['createdAt'] as Timestamp?)?.toDate().toUtc();
        if (ts == null) continue;

        final key = DateTime.utc(ts.year, ts.month, ts.day);

        dailyProjectsCount[key] = (dailyProjectsCount[key] ?? 0) + 1;

        final title = data['title'] ?? "Untitled";
        dailyProjectsMap[key] ??= [];
        dailyProjectsMap[key]!.add(title);

        dailyActionCounts[key] ??= {
          'like': 0,
          'comment': 0,
          'view': 0,
          'share': 0
        };

        dailyActionCounts[key]!['like'] = dailyActionCounts[key]!['like']! +
            ((data['likesCount'] ?? 0) as num).toInt();
        dailyActionCounts[key]!['comment'] =
            dailyActionCounts[key]!['comment']! +
                ((data['commentsCount'] ?? 0) as num).toInt();
        dailyActionCounts[key]!['view'] = dailyActionCounts[key]!['view']! +
            ((data['viewsCount'] ?? 0) as num).toInt();
        dailyActionCounts[key]!['share'] = dailyActionCounts[key]!['share']! +
            ((data['sharesCount'] ?? 0) as num).toInt();

        for (var type in actionTypes) {
          maxCounts[type] =
              (dailyActionCounts[key]![type]! > (maxCounts[type] ?? 0))
                  ? dailyActionCounts[key]![type]!
                  : maxCounts[type] ?? 0;
        }
      }

      loading = false;
      if (mounted) setState(() {});
    });
  }

  /// ===================== CSV EXPORT =====================
  void _downloadCSV() {
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM for Excel

    buffer.writeln(
        'Date,Users,Projects,Total Likes,Total Comments,Total Views,Total Shares');

    // Collect only dates with activity
    final allDates = <DateTime>{
      ...dailyUsersMap.keys,
      ...dailyProjectsMap.keys,
      ...dailyActionCounts.keys,
    };

    for (var key in allDates.toList()..sort()) {
      final users = dailyUsersMap[key]?.join("\n") ?? "";
      final projects = dailyProjectsMap[key]?.join("\n") ?? "";

      final actions = dailyActionCounts[key] ??
          {'like': 0, 'comment': 0, 'view': 0, 'share': 0};
      final likes = actions['like'] ?? 0;
      final comments = actions['comment'] ?? 0;
      final views = actions['view'] ?? 0;
      final shares = actions['share'] ?? 0;

      // Wrap date in quotes so Excel treats it as text and avoids #######
      final dateStr =
          '"${key.day.toString().padLeft(2, '0')}/${key.month.toString().padLeft(2, '0')}/${key.year}"';

      // Wrap text in quotes for Excel to handle multi-line
      buffer.writeln(
          '$dateStr,"$users","$projects",$likes,$comments,$views,$shares');
    }

    final blob = html.Blob([buffer.toString()], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "daily_activity_$currentYear.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Analytics"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Download CSV",
            onPressed: dailyActionCounts.isEmpty ? null : _downloadCSV,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section("Overview", _overviewRow()),
                const SizedBox(height: 28),
                _section(
                  "Yearly Activity Heatmap",
                  Column(
                    children: [
                      _yearSwitcher(),
                      const SizedBox(height: 12),
                      _monthLabels(),
                      const SizedBox(height: 6),
                      _githubHeatmap(dark),
                      const SizedBox(height: 12),
                      _interactiveLegend(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }

  Widget _overviewRow() {
    final totalUsersSum = dailyUsersCount.values.fold(0, (p, e) => p + e);
    final totalProjectsSum = dailyProjectsCount.values.fold(0, (p, e) => p + e);
    final totalLikes =
        dailyActionCounts.values.fold(0, (p, e) => p + (e['like'] ?? 0));
    final totalComments =
        dailyActionCounts.values.fold(0, (p, e) => p + (e['comment'] ?? 0));
    final totalViews =
        dailyActionCounts.values.fold(0, (p, e) => p + (e['view'] ?? 0));
    final totalShares =
        dailyActionCounts.values.fold(0, (p, e) => p + (e['share'] ?? 0));

    return Row(
      children: [
        _stat("Users", totalUsersSum, Colors.green[300]!),
        const SizedBox(width: 12),
        _stat("Projects", totalProjectsSum, Colors.blue[300]!),
        const SizedBox(width: 12),
        _stat("Likes", totalLikes, Colors.green[200]!),
        const SizedBox(width: 12),
        _stat("Comments", totalComments, Colors.blue[200]!),
        const SizedBox(width: 12),
        _stat("Views", totalViews, Colors.orange[200]!),
        const SizedBox(width: 12),
        _stat("Shares", totalShares, Colors.purple[200]!),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value.toString(),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _yearSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => currentYear--);
              _fetchAllStats();
            }),
        Text("$currentYear",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => currentYear++);
              _fetchAllStats();
            }),
      ],
    );
  }

  Widget _monthLabels() {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return Row(
      children: months
          .map((m) => Expanded(
              child: Text(m,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey))))
          .toList(),
    );
  }

  Widget _githubHeatmap(bool dark) {
    final start = DateTime.utc(currentYear, 1, 1);
    final end = DateTime.utc(currentYear, 12, 31);
    final totalDays = end.difference(start).inDays + 1;
    final weekCount = ((totalDays + start.weekday) / 7).ceil();

    final legendColors = {
      'like': Colors.green,
      'comment': Colors.blue,
      'view': Colors.orange,
      'share': Colors.purple,
    };

    List<Widget> columns = [];

    for (int w = 0; w < weekCount; w++) {
      List<Widget> col = [];
      for (int d = 0; d < 7; d++) {
        final dayIndex = w * 7 + d - (start.weekday - 1);
        if (dayIndex < 0 || dayIndex >= totalDays) {
          col.add(Container(
              width: 16, height: 16, margin: const EdgeInsets.all(2)));
          continue;
        }
        final date = start.add(Duration(days: dayIndex));
        final key = DateTime.utc(date.year, date.month, date.day);
        final counts = dailyActionCounts[key] ??
            {'like': 0, 'comment': 0, 'view': 0, 'share': 0};

        col.add(Tooltip(
          message:
              "${key.day}/${key.month}/${key.year}\nUsers: ${dailyUsersCount[key] ?? 0}, Projects: ${dailyProjectsCount[key] ?? 0}\nLikes: ${counts['like'] ?? 0}, Comments: ${counts['comment'] ?? 0}, Views: ${counts['view'] ?? 0}, Shares: ${counts['share'] ?? 0}",
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: dark ? Colors.black12 : Colors.grey[200]),
            child: Stack(
              children: actionTypes.map((type) {
                if (activeType != null && activeType != type)
                  return const SizedBox();
                final count = counts[type] ?? 0;
                if (count == 0) return const SizedBox();
                final opacity =
                    (count / (maxCounts[type] ?? 1)).clamp(0.2, 1.0);
                return Container(
                  decoration: BoxDecoration(
                      color: legendColors[type]!.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(3)),
                );
              }).toList(),
            ),
          ),
        ));
      }
      columns.add(Column(children: col));
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal, child: Row(children: columns));
  }

  Widget _interactiveLegend() {
    final legendColors = {
      'like': Colors.green[400]!,
      'comment': Colors.blue[400]!,
      'view': Colors.orange[400]!,
      'share': Colors.purple[400]!,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: actionTypes.map((type) {
        return GestureDetector(
          onTap: () =>
              setState(() => activeType = activeType == type ? null : type),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: activeType == type ? Colors.black : Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                    width: 14,
                    height: 14,
                    color: legendColors[type],
                    margin: const EdgeInsets.only(right: 6)),
                Text(type[0].toUpperCase() + type.substring(1)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
