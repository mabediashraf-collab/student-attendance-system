import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class EnterResultsScreen extends StatefulWidget {
  const EnterResultsScreen({super.key});

  @override
  State<EnterResultsScreen> createState() => _EnterResultsScreenState();
}

class _EnterResultsScreenState extends State<EnterResultsScreen> {
  List classes = [];
  List subjects = [];
  List students = [];
  String? selectedClassId;
  String? selectedSubjectId;
  String examType = 'Exam';
  int term = 1;
  Map<String, TextEditingController> marksControllers = {};
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final classesResult = await ApiService.getClasses();
    if (classesResult['success'] == true) {
      classes = classesResult['classes'] ?? [];
    }

    final subjectsResult = await ApiService.getSubjects();
    if (subjectsResult['success'] == true) {
      subjects = subjectsResult['subjects'] ?? [];
    }

    setState(() => isLoading = false);
  }

  Future<void> loadStudents() async {
    if (selectedClassId == null) return;

    setState(() => isLoading = true);
    final result =
        await ApiService.getStudentsByClass(int.parse(selectedClassId!));
    if (result['success'] == true) {
      setState(() {
        students = result['students'] ?? [];
        marksControllers.clear();
        for (var student in students) {
          String studentId = student['student_id'].toString();
          marksControllers[studentId] = TextEditingController();
        }
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> saveMarks() async {
    if (selectedClassId == null || selectedSubjectId == null) {
      Fluttertoast.showToast(msg: 'Select class and subject first');
      return;
    }

    setState(() => isSaving = true);

    Map<String, dynamic> marksData = {};
    marksControllers.forEach((studentId, controller) {
      marksData[studentId] = controller.text.isEmpty ? '0' : controller.text;
    });

    final result = await ApiService.saveMarks(
      int.parse(selectedClassId!),
      int.parse(selectedSubjectId!),
      examType,
      term,
      marksData,
    );

    if (result['success'] == true) {
      Fluttertoast.showToast(
          msg: 'Results saved successfully!', backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to save results',
          backgroundColor: Colors.red);
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Results'),
        backgroundColor: Colors.green.shade700,
        actions: [
          if (students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: isSaving ? null : saveMarks,
            ),
        ],
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
                          DropdownButtonFormField<String>(
                            initialValue: selectedClassId,
                            decoration: const InputDecoration(
                                labelText: 'Select Class'),
                            items: classes.map((cls) {
                              return DropdownMenuItem(
                                value: cls['class_id'].toString(),
                                child: Text(
                                    '${cls['class_name']} ${cls['stream'] ?? ''}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedClassId = value;
                                students = [];
                              });
                              if (value != null) loadStudents();
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSubjectId,
                            decoration: const InputDecoration(
                                labelText: 'Select Subject'),
                            items: subjects.map((subj) {
                              return DropdownMenuItem(
                                value: subj['subject_id'].toString(),
                                child: Text(subj['subject_name']),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => selectedSubjectId = value),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: examType,
                                  decoration: const InputDecoration(
                                      labelText: 'Exam Type'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Exam', child: Text('Exam')),
                                    DropdownMenuItem(
                                        value: 'Test', child: Text('Test')),
                                    DropdownMenuItem(
                                        value: 'Assignment',
                                        child: Text('Assignment')),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => examType = value!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: term,
                                  decoration:
                                      const InputDecoration(labelText: 'Term'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 1, child: Text('Term 1')),
                                    DropdownMenuItem(
                                        value: 2, child: Text('Term 2')),
                                    DropdownMenuItem(
                                        value: 3, child: Text('Term 3')),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => term = value!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (students.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Enter Marks',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                String studentId =
                                    student['student_id'].toString();
                                String studentName =
                                    '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                                        .trim();
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(studentName.isEmpty
                                            ? 'Unknown'
                                            : studentName),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: TextField(
                                          controller:
                                              marksControllers[studentId],
                                          decoration: const InputDecoration(
                                            labelText: 'Marks',
                                            hintText: '0-100',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: students.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: isSaving ? null : saveMarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE RESULTS',
                        style: TextStyle(fontSize: 16)),
              ),
            )
          : null,
    );
  }
}
