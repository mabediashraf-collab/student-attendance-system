import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class EnrollStudentScreen extends StatefulWidget {
  const EnrollStudentScreen({super.key});

  @override
  State<EnrollStudentScreen> createState() => _EnrollStudentScreenState();
}

class _EnrollStudentScreenState extends State<EnrollStudentScreen> {
  List students = [];
  List classes = [];
  List enrollments = [];
  String? selectedStudentId;
  String? selectedClassId;
  final TextEditingController academicYearController =
      TextEditingController(text: DateTime.now().year.toString());
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    await loadStudents();
    await loadClasses();
    await loadEnrollments();
    setState(() => isLoading = false);
  }

  Future<void> loadStudents() async {
    try {
      final result = await ApiService.getUsers();
      if (result['success'] == true) {
        setState(() {
          students =
              result['users']?.where((u) => u['role'] == 'student').toList() ??
                  [];
        });
        print('Loaded ${students.length} students');
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> loadClasses() async {
    try {
      final result = await ApiService.getClasses();
      if (result['success'] == true) {
        setState(() {
          classes = result['classes'] ?? [];
        });
        print('Loaded ${classes.length} classes');
      }
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  Future<void> loadEnrollments() async {
    try {
      final result = await ApiService.getEnrollments();
      if (result['success'] == true) {
        setState(() {
          enrollments = result['enrollments'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading enrollments: $e');
    }
  }

  Future<void> enrollStudent() async {
    if (selectedStudentId == null || selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select student and class');
      return;
    }

    setState(() => isLoading = true);

    print(
        'Enrolling - Student ID: $selectedStudentId, Class ID: $selectedClassId');

    final result = await ApiService.enrollStudent(
      int.parse(selectedStudentId!),
      int.parse(selectedClassId!),
      academicYearController.text,
    );

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Student enrolled successfully');
      await loadEnrollments();
      setState(() {
        selectedStudentId = null;
        selectedClassId = null;
      });
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Enrollment failed');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Students to Classes',
            style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadAllData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'New Enrollment',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStudentId,
                      decoration:
                          const InputDecoration(labelText: 'Select Student'),
                      items: students.isEmpty
                          ? [
                              const DropdownMenuItem(
                                  value: null, child: Text('No students found'))
                            ]
                          : students.map((student) {
                              return DropdownMenuItem(
                                value: student['user_id'].toString(),
                                child: Text(
                                    student['full_name'] ?? student['email']),
                              );
                            }).toList(),
                      onChanged: students.isEmpty
                          ? null
                          : (value) =>
                              setState(() => selectedStudentId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClassId,
                      decoration:
                          const InputDecoration(labelText: 'Select Class'),
                      items: classes.isEmpty
                          ? [
                              const DropdownMenuItem(
                                  value: null, child: Text('No classes found'))
                            ]
                          : classes.map((cls) {
                              return DropdownMenuItem(
                                value: cls['class_id'].toString(),
                                child: Text(
                                    '${cls['class_name']} ${cls['stream']}'),
                              );
                            }).toList(),
                      onChanged: classes.isEmpty
                          ? null
                          : (value) => setState(() => selectedClassId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: academicYearController,
                      decoration:
                          const InputDecoration(labelText: 'Academic Year'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (students.isEmpty || classes.isEmpty)
                          ? null
                          : enrollStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Enroll Student'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Current Enrollments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: enrollments.isEmpty
                  ? const Center(child: Text('No enrollments yet'))
                  : ListView.builder(
                      itemCount: enrollments.length,
                      itemBuilder: (context, index) {
                        final enrollment = enrollments[index];
                        return Card(
                          child: ListTile(
                            leading:
                                const Icon(Icons.school, color: Colors.green),
                            title:
                                Text(enrollment['student_name'] ?? 'Unknown'),
                            subtitle: Text(
                              '${enrollment['class_name']} ${enrollment['stream']} - ${enrollment['academic_year']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Enrollment'),
                                    content: const Text('Are you sure?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Remove',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final result =
                                      await ApiService.removeEnrollment(
                                          enrollment['enrollment_id']);
                                  if (result['success'] == true) {
                                    Fluttertoast.showToast(
                                        msg: 'Enrollment removed');
                                    await loadEnrollments();
                                  }
                                }
                              },
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
