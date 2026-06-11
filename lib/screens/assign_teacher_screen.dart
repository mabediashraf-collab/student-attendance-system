import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class AssignTeacherScreen extends StatefulWidget {
  const AssignTeacherScreen({super.key});

  @override
  State<AssignTeacherScreen> createState() => _AssignTeacherScreenState();
}

class _AssignTeacherScreenState extends State<AssignTeacherScreen> {
  List teachers = [];
  List subjects = [];
  List classes = [];
  List assignments = [];
  String? selectedTeacherId;
  String? selectedSubjectId;
  String? selectedClassId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadData();
    loadAssignments();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final teachersResult = await ApiService.getUsers();
    if (teachersResult['success'] == true) {
      teachers = teachersResult['users']
              ?.where((u) => u['role'] == 'teacher')
              .toList() ??
          [];
    }

    final subjectsResult = await ApiService.getSubjects();
    if (subjectsResult['success'] == true) {
      subjects = subjectsResult['subjects'] ?? [];
    }

    final classesResult = await ApiService.getClasses();
    if (classesResult['success'] == true) {
      classes = classesResult['classes'] ?? [];
    }

    setState(() => isLoading = false);
  }

  Future<void> loadAssignments() async {
    final result = await ApiService.getTeacherAssignments();
    if (result['success'] == true) {
      setState(() {
        assignments = result['assignments'] ?? [];
      });
    }
  }

  Future<void> assignTeacher() async {
    if (selectedTeacherId == null ||
        selectedSubjectId == null ||
        selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select teacher, subject and class');
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.assignTeacherToSubject(
      int.parse(selectedTeacherId!),
      int.parse(selectedSubjectId!),
      int.parse(selectedClassId!),
    );

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Teacher assigned successfully');
      await loadAssignments();
      selectedTeacherId = null;
      selectedSubjectId = null;
      selectedClassId = null;
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Assignment failed');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Teachers to Subjects',
            style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.green.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'New Assignment',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedTeacherId,
                            decoration: const InputDecoration(
                                labelText: 'Select Teacher'),
                            items: teachers.map((teacher) {
                              return DropdownMenuItem(
                                value: teacher['user_id'].toString(),
                                child: Text(
                                    teacher['full_name'] ?? teacher['email']),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => selectedTeacherId = value),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSubjectId,
                            decoration: const InputDecoration(
                                labelText: 'Select Subject'),
                            items: subjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject['subject_id'].toString(),
                                child: Text(subject['subject_name']),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => selectedSubjectId = value),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedClassId,
                            decoration: const InputDecoration(
                                labelText: 'Select Class'),
                            items: classes.map((cls) {
                              return DropdownMenuItem(
                                value: cls['class_id'].toString(),
                                child: Text(
                                    '${cls['class_name']} ${cls['stream']}'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => selectedClassId = value),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: assignTeacher,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Assign Teacher'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Current Assignments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  assignments.isEmpty
                      ? const Center(child: Text('No assignments yet'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: assignments.length,
                          itemBuilder: (context, index) {
                            final assignment = assignments[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.green),
                                title: Text(
                                    assignment['teacher_email'] ?? 'Unknown'),
                                subtitle: Text(
                                  '${assignment['subject_name']} - ${assignment['class_name']} ${assignment['stream']}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Remove Assignment'),
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
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final result = await ApiService
                                          .removeTeacherAssignment(
                                              assignment['id']);
                                      if (result['success'] == true) {
                                        Fluttertoast.showToast(
                                            msg: 'Assignment removed');
                                        await loadAssignments();
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
