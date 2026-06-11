import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ViewEnrollmentsScreen extends StatefulWidget {
  const ViewEnrollmentsScreen({super.key});

  @override
  State<ViewEnrollmentsScreen> createState() => _ViewEnrollmentsScreenState();
}

class _ViewEnrollmentsScreenState extends State<ViewEnrollmentsScreen> {
  List enrollments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEnrollments();
  }

  Future<void> loadEnrollments() async {
    setState(() => isLoading = true);
    final result = await ApiService.getEnrollments();
    if (result['success'] == true) {
      setState(() {
        enrollments = result['enrollments'] ?? [];
      });
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Enrollments', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadEnrollments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : enrollments.isEmpty
              ? const Center(child: Text('No student enrollments found'))
              : ListView.builder(
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = enrollments[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.school, color: Colors.white),
                        ),
                        title: Text(enrollment['student_name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Class: ${enrollment['class_name']} ${enrollment['stream']}'),
                            Text('Academic Year: ${enrollment['academic_year']}'),
                          ],
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
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final result = await ApiService.removeEnrollment(enrollment['enrollment_id']);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enrollment removed')),
                                );
                                await loadEnrollments();
                              }
                            }
                          },
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
