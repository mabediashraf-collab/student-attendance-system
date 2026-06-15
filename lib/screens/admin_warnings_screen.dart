import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class AdminWarningsScreen extends StatefulWidget {
  const AdminWarningsScreen({super.key});

  @override
  State<AdminWarningsScreen> createState() => _AdminWarningsScreenState();
}

class _AdminWarningsScreenState extends State<AdminWarningsScreen> {
  List studentsWithWarnings = [];
  List classes = [];
  bool isLoading = true;
  int? selectedClassId;
  int warningThreshold = 8;

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
    final result = await ApiService.getStudentsWithWarningsAdmin(
      classId: selectedClassId,
      threshold: warningThreshold,
    );
    
    if (result['success'] == true) {
      setState(() {
        studentsWithWarnings = result['students'] ?? [];
      });
    }
  }

  void _applyFilters() {
    _loadStudentsWithWarnings();
  }

  void _resetFilters() {
    setState(() {
      selectedClassId = null;
      warningThreshold = 8;
    });
    _loadStudentsWithWarnings();
  }

  Future<void> _sendWarning(Map<String, dynamic> student) async {
    final messageController = TextEditingController();
    String warningType = 'Absence';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Warning to Parent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Student: ${student['student_name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Admission: ${student['admission_no']}'),
                    Text('Parent: ${student['parent_name'] ?? 'Not provided'}'),
                    Text('Contact: ${student['parent_contact'] ?? 'Not provided'}'),
                    const Divider(),
                    Text(
                      'Total Absences/Lates: ${student['absent_count']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
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
                  hintText: 'Custom message to parent...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              String message = messageController.text;
              if (message.isEmpty) {
                message = 'Your child has ${student['absent_count']} records of absence/late attendance. Please ensure regular attendance.';
              }
              
              final result = await ApiService.sendWarningAdmin(
                studentId: student['student_id'],
                message: message,
                warningType: warningType,
              );
              
              if (result['success'] == true) {
                Fluttertoast.showToast(msg: 'Warning sent to ${student['parent_name'] ?? 'parent'}');
                _loadStudentsWithWarnings();
              } else {
                Fluttertoast.showToast(msg: result['message'] ?? 'Failed to send warning');
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
    String message = 'Students with $warningThreshold or more absences/lates will appear here';
    
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
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedClassId,
                      decoration: const InputDecoration(labelText: 'Filter by Class'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Classes')),
                        ...classes.map((cls) {
                          return DropdownMenuItem<int>(
                            value: cls['class_id'],
                            child: Text('${cls['class_name']} ${cls['stream']}'),
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
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Icon(Icons.check_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    Text('No students with $warningThreshold+ absences/lates'),
                    const Text('All students are within acceptable attendance range'),
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
                        Text('Class: ${student['class_name']} ${student['stream']}'),
                        Text('Total: ${student['absent_count']} (Absent: ${student['absent_only']}, Late: ${student['late_only']})'),
                        if (student['parent_contact'] != null)
                          Text('Parent: ${student['parent_name'] ?? 'N/A'} - ${student['parent_contact']}'),
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _sendWarning(student),
                      icon: const Icon(Icons.warning_amber),
                      label: const Text('Send Warning'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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