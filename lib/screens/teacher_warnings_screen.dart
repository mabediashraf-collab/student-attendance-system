import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class TeacherWarningsScreen extends StatefulWidget {
  const TeacherWarningsScreen({super.key});

  @override
  State<TeacherWarningsScreen> createState() => _TeacherWarningsScreenState();
}

class _TeacherWarningsScreenState extends State<TeacherWarningsScreen> {
  List studentsWithWarnings = [];
  List classes = [];
  bool isLoading = true;
  int? selectedClassId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadClasses();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await _loadStudentsWithWarnings();
    setState(() => isLoading = false);
  }

  Future<void> _loadClasses() async {
    final result = await ApiService.getClasses();
    if (result['success'] == true) {
      setState(() {
        classes = result['classes'] ?? [];
      });
    }
  }

  Future<void> _loadStudentsWithWarnings() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('user_id');

    if (teacherId != null) {
      final result =
          await ApiService.getStudentsWithWarnings(teacherId, selectedClassId);
      if (result['success'] == true) {
        setState(() {
          studentsWithWarnings = result['students'] ?? [];
        });
      }
    }
  }

  void _applyFilters() {
    _loadStudentsWithWarnings();
  }

  void _resetFilters() {
    setState(() {
      selectedClassId = null;
    });
    _loadStudentsWithWarnings();
  }

  Future<void> _sendWarning(Map<String, dynamic> student) async {
    final messageController = TextEditingController();
    String warningType = 'Absence';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Warning'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${student['student_name']}'),
              Text('Admission: ${student['admission_no']}'),
              Text(
                  'Absences: ${student['absent_count']} (Absent: ${student['absent_only']}, Late: ${student['late_only']})'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: warningType,
                decoration: const InputDecoration(labelText: 'Warning Type'),
                items: const [
                  DropdownMenuItem(value: 'Absence', child: Text('Absence')),
                  DropdownMenuItem(value: 'Late', child: Text('Late')),
                  DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                  DropdownMenuItem(value: 'Behavior', child: Text('Behavior')),
                ],
                onChanged: (value) => warningType = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              final teacherId = prefs.getInt('user_id');

              String message = messageController.text;
              if (message.isEmpty) {
                message =
                    'Your child has ${student['absent_count']} records of absence/late attendance. Please ensure regular attendance.';
              }

              final result = await ApiService.sendWarning(
                student['student_id'],
                teacherId!,
                message,
                warningType,
              );

              if (result['success'] == true) {
                Fluttertoast.showToast(
                    msg: 'Warning sent to ${student['student_name']}');
                _loadStudentsWithWarnings();
              } else {
                Fluttertoast.showToast(
                    msg: result['message'] ?? 'Failed to send warning');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Warnings to Parents'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedClassId,
                      decoration:
                          const InputDecoration(labelText: 'Filter by Class'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Classes')),
                        ...classes.map((cls) {
                          return DropdownMenuItem<int>(
                            value: cls['class_id'],
                            child:
                                Text('${cls['class_name']} ${cls['stream']}'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => selectedClassId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
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
            else if (studentsWithWarnings.isEmpty)
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Icon(Icons.warning, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No students with 3+ absences/lates'),
                    Text('Students appear here when they exceed the limit'),
                  ],
                ),
              )
            else
              ...studentsWithWarnings.map((student) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade200,
                      child: Text(
                        student['absent_count'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      student['student_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admission: ${student['admission_no']}'),
                        Text(
                            'Total: ${student['absent_count']} (Absent: ${student['absent_only']}, Late: ${student['late_only']})'),
                        if (student['parent_contact'] != null)
                          Text(
                              'Parent: ${student['parent_name']} - ${student['parent_contact']}'),
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _sendWarning(student),
                      icon: const Icon(Icons.warning_amber),
                      label: const Text('Send Warning'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
