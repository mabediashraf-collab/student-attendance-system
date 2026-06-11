import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List classes = [];
  List subjects = [];
  List results = [];
  String? selectedClass;
  String? selectedSubject;
  int selectedTerm = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadClasses();
    loadSubjects();
  }

  Future<void> loadClasses() async {
    final result = await ApiService.getClasses();
    if (result['success'] == true) {
      setState(() {
        classes = result['classes'] ?? [];
      });
    }
  }

  Future<void> loadSubjects() async {
    final result = await ApiService.getSubjects();
    if (result['success'] == true) {
      setState(() {
        subjects = result['subjects'] ?? [];
      });
    }
  }

  Future<void> loadResults() async {
    if (selectedClass == null) {
      Fluttertoast.showToast(msg: 'Please select a class');
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.getResultsByClass(
      int.parse(selectedClass!),
      selectedSubject != null ? int.parse(selectedSubject!) : null,
      selectedTerm,
    );

    if (result['success'] == true) {
      setState(() {
        results = result['results'] ?? [];
      });
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'No results found');
    }
    setState(() => isLoading = false);
  }

  String _getGrade(double marks) {
    if (marks >= 80) return 'A';
    if (marks >= 70) return 'B+';
    if (marks >= 60) return 'B';
    if (marks >= 50) return 'C';
    if (marks >= 40) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results Management', style: TextStyle(fontSize: 16)),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Select Subject (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Subjects')),
                ...subjects.map((subj) {
                  return DropdownMenuItem(
                    value: subj['subject_id'].toString(),
                    child: Text(subj['subject_name']),
                  );
                }),
              ],
              onChanged: (value) => setState(() => selectedSubject = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selectedTerm,
              decoration: const InputDecoration(
                labelText: 'Select Term',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Term 1')),
                DropdownMenuItem(value: 2, child: Text('Term 2')),
                DropdownMenuItem(value: 3, child: Text('Term 3')),
              ],
              onChanged: (value) => setState(() => selectedTerm = value!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('View Results'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                      ? const Center(child: Text('No results found'))
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final result = results[index];
                            final marks = result['marks_obtained'] ?? 0;
                            final grade = result['grade'] ?? _getGrade(marks);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(result['student_name']?[0]
                                          ?.toUpperCase() ??
                                      '?'),
                                ),
                                title:
                                    Text(result['student_name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Admission: ${result['admission_no']}'),
                                    Text('Subject: ${result['subject_name']}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$marks%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: marks >= 50
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      'Grade: $grade',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
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
