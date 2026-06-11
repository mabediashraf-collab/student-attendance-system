import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List classes = [];
  List attendanceRecords = [];
  String? selectedClass;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    final result = await ApiService.getClasses();
    if (result['success'] == true) {
      setState(() {
        classes = result['classes'] ?? [];
      });
    }
  }

  Future<void> loadAttendance() async {
    if (selectedClass == null) {
      Fluttertoast.showToast(msg: 'Please select a class');
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.getAllAttendance(
      int.parse(selectedClass!),
      selectedDate.toString().split(' ')[0],
    );

    if (result['success'] == true) {
      setState(() {
        attendanceRecords = result['attendance'] ?? [];
      });
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'No records found');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Attendance Management', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedClass,
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
              ),
              items: classes.map((cls) {
                return DropdownMenuItem(
                  value: cls['class_id'].toString(),
                  child: Text('${cls['class_name']} ${cls['stream']}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedClass = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Select Date'),
              subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => selectedDate = date);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('View Attendance'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceRecords.isEmpty
                      ? const Center(child: Text('No attendance records found'))
                      : ListView.builder(
                          itemCount: attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = attendanceRecords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: record['status'] == 'present'
                                      ? Colors.green
                                      : record['status'] == 'late'
                                          ? Colors.orange
                                          : Colors.red,
                                  child: Text(
                                    record['student_name']?[0]?.toUpperCase() ??
                                        '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title:
                                    Text(record['student_name'] ?? 'Unknown'),
                                subtitle: Text(
                                    'Admission: ${record['admission_no']}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: record['status'] == 'present'
                                        ? Colors.green
                                        : record['status'] == 'late'
                                            ? Colors.orange
                                            : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record['status']?.toUpperCase() ??
                                        'UNKNOWN',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
