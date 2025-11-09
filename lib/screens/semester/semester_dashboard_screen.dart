import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // for dashboard charts

class SemesterDashboardScreen extends StatefulWidget {
  final String semesterName;
  const SemesterDashboardScreen({super.key, required this.semesterName});

  @override
  State<SemesterDashboardScreen> createState() =>
      _SemesterDashboardScreenState();
}

class _SemesterDashboardScreenState extends State<SemesterDashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {"icon": Icons.dashboard, "label": "Dashboard"},
    {"icon": Icons.check_circle_outline, "label": "Attendance"},
    {"icon": Icons.grade, "label": "Marks"},
    {"icon": Icons.note, "label": "Notes"},
    {"icon": Icons.calendar_month, "label": "Timetable"},
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardTab(),
      const PlaceholderTab(label: "Attendance"),
      const PlaceholderTab(label: "Marks"),
      const PlaceholderTab(label: "Notes"),
      const TimetableTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semesterName),
        backgroundColor: const Color(0xFF283593),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF283593),
        unselectedItemColor: Colors.grey,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab["icon"]),
                label: tab["label"],
              ),
            )
            .toList(),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Semester Overview",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF283593),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "\"Small daily improvements lead to big results.\"",
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          // Attendance section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Attendance",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.78, // example value
                  backgroundColor: Colors.blue.shade100,
                  color: Colors.blueAccent,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                const Text(
                  "78% present this semester",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Progress graph (marks trend)
          const Text(
            "Marks Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.6,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ["Sub1", "Sub2", "Sub3", "Sub4", "Sub5"];
                        return Text(
                          labels[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [BarChartRodData(toY: 85, color: Colors.green)],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [BarChartRodData(toY: 72, color: Colors.green)],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [BarChartRodData(toY: 91, color: Colors.green)],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [BarChartRodData(toY: 64, color: Colors.green)],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [BarChartRodData(toY: 78, color: Colors.green)],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimetableTab extends StatelessWidget {
  const TimetableTab({super.key});

  final List<Map<String, dynamic>> timetable = const [
    {
      "day": "Monday",
      "classes": [
        {"time": "9:00 AM", "subject": "Data Structures", "color": 0xFFBBDEFB},
        {"time": "11:00 AM", "subject": "Maths", "color": 0xFFC8E6C9},
        {
          "time": "2:00 PM",
          "subject": "Operating Systems",
          "color": 0xFFFFF9C4,
        },
      ],
    },
    {
      "day": "Tuesday",
      "classes": [
        {"time": "9:00 AM", "subject": "Python Lab", "color": 0xFFFFECB3},
        {"time": "1:00 PM", "subject": "DBMS", "color": 0xFFDCEDC8},
      ],
    },
    {
      "day": "Wednesday",
      "classes": [
        {"time": "10:00 AM", "subject": "Data Science", "color": 0xFFE1BEE7},
        {"time": "1:00 PM", "subject": "Maths", "color": 0xFFFFCDD2},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timetable.length,
      itemBuilder: (context, index) {
        final day = timetable[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ExpansionTile(
            title: Text(
              day["day"],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
            ),
            children: (day["classes"] as List).map<Widget>((cls) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(cls["color"]),
                  radius: 8,
                ),
                title: Text(cls["subject"]),
                subtitle: Text(cls["time"]),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  final String label;
  const PlaceholderTab({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$label page coming soon!",
        style: const TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
