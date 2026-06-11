import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  const TeacherSubjectsScreen({super.key});

  @override
  State<TeacherSubjectsScreen> createState() => _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  List subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    setState(() => isLoading = true);
    final result = await ApiService.getSubjects();
    if (result['success'] == true) {
      setState(() {
        subjects = result['subjects'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadSubjects,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subjects.isEmpty
              ? const Center(child: Text('No subjects found'))
              : ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.book, color: Colors.green),
                        ),
                        title: Text(subject['subject_name'] ?? 'Unknown'),
                        subtitle:
                            Text('Code: ${subject['subject_code'] ?? ''}'),
                        trailing: const Icon(Icons.arrow_forward),
                      ),
                    );
                  },
                ),
    );
  }
}
