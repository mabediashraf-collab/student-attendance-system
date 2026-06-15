import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class TeacherMarksView extends StatefulWidget {
  final List teacherClasses;
  
  const TeacherMarksView({super.key, this.teacherClasses = const []});

  @override
  State<TeacherMarksView> createState() => _TeacherMarksViewState();
}

class _TeacherMarksViewState extends State<TeacherMarksView> {
  List marksRecords = [];
  List subjects = [];
  bool isLoading = true;
  bool isLoadingRecords = false;
  
  int? selectedClassId;
  int? selectedSubjectId;
  int selectedTerm = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSubjects();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await _loadMarksRecords();
    setState(() => isLoading = false);
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('user_id') ?? 35;
    final result = await ApiService.getTeacherSubjects(teacherId);
    
    if (result['success'] == true) {
      setState(() {
        subjects = result['subjects'] ?? [];
      });
      print("Loaded ${subjects.length} assigned subjects");
    }
  }

  Future<void> _loadMarksRecords() async {
    setState(() => isLoadingRecords = true);
    
    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('user_id');
    
    if (teacherId == null) {
      setState(() => isLoadingRecords = false);
      return;
    }
    
    print("Loading marks for teacher: $teacherId, Class: $selectedClassId, Subject: $selectedSubjectId, Term: $selectedTerm");
    
    final result = await ApiService.getTeacherMarks(
      teacherId,
      classId: selectedClassId,
      subjectId: selectedSubjectId,
      term: selectedTerm,
    );
    
    if (result['success'] == true && result['marks'] != null) {
      setState(() {
        marksRecords = result['marks'] ?? [];
      });
      print("Loaded ${marksRecords.length} marks records");
    } else {
      print("Failed to load marks: ${result['message']}");
      setState(() {
        marksRecords = [];
      });
    }
    
    setState(() => isLoadingRecords = false);
  }

  void _applyFilters() {
    _loadMarksRecords();
  }

  void _resetFilters() {
    setState(() {
      selectedClassId = null;
      selectedSubjectId = null;
      selectedTerm = 1;
    });
    _loadMarksRecords();
  }

  String _getExamTypeDisplay(String examType) {
    switch(examType) {
      case 'BOT': return 'Beginning of Term';
      case 'MOT': return 'Mid-Term';
      case 'EOT': return 'End of Term';
      case 'CAT1': return 'CAT 1';
      case 'CAT2': return 'CAT 2';
      default: return examType;
    }
  }

  String _getGrade(double marks) {
    if (marks >= 80) return 'A';
    if (marks >= 70) return 'B+';
    if (marks >= 60) return 'B';
    if (marks >= 50) return 'C';
    if (marks >= 40) return 'D';
    return 'F';
  }

  Color _getGradeColor(double marks) {
    if (marks >= 80) return Colors.green;
    if (marks >= 60) return Colors.lightGreen;
    if (marks >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Filter Marks Records",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
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
                      const DropdownMenuItem(value: null, child: Text('All Classes')),
                      ...widget.teacherClasses.map((cls) {
                        return DropdownMenuItem<int>(
                          value: cls['class_id'],
                          child: Text('${cls['class_name']} ${cls['stream']}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedClassId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Subject',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      ...subjects.map((subj) {
                        return DropdownMenuItem<int>(
                          value: subj['subject_id'],
                          child: Text(subj['subject_name']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSubjectId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedTerm,
                    decoration: const InputDecoration(
                      labelText: 'Term',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Term 1')),
                      DropdownMenuItem(value: 2, child: Text('Term 2')),
                      DropdownMenuItem(value: 3, child: Text('Term 3')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedTerm = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
          
          // Results
          if (isLoading || isLoadingRecords)
            const Center(child: CircularProgressIndicator())
          else if (marksRecords.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Icon(Icons.edit_note, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No marks records found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select filters and click Apply to view marks',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Records: ${marksRecords.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.edit_note, color: Colors.blue.shade700),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...marksRecords.map((record) {
                  double marks = record['marks_obtained'] ?? 0;
                  String grade = _getGrade(marks);
                  Color gradeColor = _getGradeColor(marks);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: gradeColor.withOpacity(0.2),
                        child: Text(
                          record['subject_code']?.substring(0, 2) ?? '?',
                          style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        record['student_name'] ?? 'Unknown Student',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class: ${record['class_name']} ${record['stream']}'),
                          Text('Subject: ${record['subject_name']}'),
                          Text('Exam: ${_getExamTypeDisplay(record['exam_type'])} - Term ${record['term']}'),
                          Text('Admission: ${record['admission_no'] ?? 'N/A'}'),
                          Text('Marks: ${marks.toStringAsFixed(1)}% - Grade: $grade'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: gradeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          grade,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}