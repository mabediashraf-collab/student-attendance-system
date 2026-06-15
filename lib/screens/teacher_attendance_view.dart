import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class TeacherAttendanceView extends StatefulWidget {
  final List teacherClasses;

  const TeacherAttendanceView({super.key, this.teacherClasses = const []});

  @override
  State<TeacherAttendanceView> createState() => _TeacherAttendanceViewState();
}

class _TeacherAttendanceViewState extends State<TeacherAttendanceView> {
  List attendanceRecords = [];
  Map<String, dynamic>? stats;
  bool isLoading = true;

  int? selectedClassId;
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    print(
        "TeacherAttendanceView init - Received ${widget.teacherClasses.length} classes");
    for (var cls in widget.teacherClasses) {
      print(
          "Class: ${cls['class_name']} ${cls['stream']} - ID: ${cls['class_id']}");
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('user_id');

    if (teacherId != null) {
      final statsResult = await ApiService.getTeacherAttendanceStats(teacherId);
      if (statsResult['success'] == true) {
        setState(() {
          stats = statsResult['stats'];
        });
      }

      await _loadAttendanceRecords();
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('user_id');

    print(
        "Loading attendance - Teacher: $teacherId, Class: $selectedClassId, Date: $selectedDate");

    final result = await ApiService.getAttendanceRecords(
      teacherId: teacherId,
      classId: selectedClassId,
      date: selectedDate,
    );

    if (result['success'] == true) {
      setState(() {
        attendanceRecords = result['attendance'] ?? [];
      });
      print("Loaded ${attendanceRecords.length} records");
    } else {
      print("Failed to load: ${result['message']}");
    }
  }

  void _applyFilters() {
    print("Applying filters - Class: $selectedClassId, Date: $selectedDate");
    _loadAttendanceRecords();
  }

  void _resetFilters() {
    setState(() {
      selectedClassId = null;
      selectedDate = null;
    });
    _loadAttendanceRecords();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (stats != null)
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Total',
                        stats!['total_attendance'].toString(),
                        Icons.calendar_today,
                        Colors.blue)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Classes',
                        stats!['classes_covered'].toString(),
                        Icons.class_,
                        Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Students',
                        stats!['students_marked'].toString(),
                        Icons.people,
                        Colors.orange)),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.teacherClasses.isEmpty
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.teacherClasses.isEmpty
                              ? Icons.warning
                              : Icons.check_circle,
                          color: widget.teacherClasses.isEmpty
                              ? Colors.red
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.teacherClasses.isEmpty
                              ? "No classes assigned to you"
                              : "You have ${widget.teacherClasses.length} class(es) assigned",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.teacherClasses.isEmpty
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Class',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Classes')),
                      ...widget.teacherClasses.map((cls) {
                        return DropdownMenuItem<int>(
                          value: cls['class_id'],
                          child: Text('${cls['class_name']} ${cls['stream']}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      print("Class dropdown changed to: $value");
                      setState(() {
                        selectedClassId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: 'Filter by Date',
                        border: OutlineInputBorder()),
                    controller: TextEditingController(text: selectedDate),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() =>
                            selectedDate = picked.toString().split(' ')[0]);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (attendanceRecords.isEmpty)
            const Center(
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No attendance records found for the selected filters'),
                ],
              ),
            )
          else
            ...attendanceRecords.map((record) {
              bool isPresent = record['status'] == 'Present';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isPresent ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(isPresent ? Icons.check : Icons.close,
                        color: isPresent ? Colors.green : Colors.red),
                  ),
                  title: Text(record['student_name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Class: ${record['class_name']} ${record['stream']}'),
                      Text(
                          'Date: ${record['attendance_date']} (${record['attendance_session']})'),
                      Text('Admission: ${record['admission_no'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record['status']?.toUpperCase() ?? 'ABSENT',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
