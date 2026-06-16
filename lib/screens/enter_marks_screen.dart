import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EnterMarksScreen extends StatefulWidget {
  const EnterMarksScreen({super.key});

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];
  List<dynamic> _students = [];
  int? _selectedClassId;
  int? _selectedSubjectId;
  String _selectedExamType = 'EOT';
  int _selectedTerm = 1;
  bool _isLoading = false;
  bool _isALevel = false;
  String _currentSubjectName = '';
  bool _isSubsidiary = false;
  final Map<int, Map<String, dynamic>> _studentMarks = {};
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id') ?? 0;
    await _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(
          'http://localhost/sms_api/teacher_marks_api.php?action=get_classes&user_id=$_userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _classes = data['classes'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubjects() async {
    if (_selectedClassId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(
          'http://localhost/sms_api/teacher_marks_api.php?action=get_subjects&class_id=$_selectedClassId&user_id=$_userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _subjects = data['subjects'];
            _selectedSubjectId = null;
            _students = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(
          'http://localhost/sms_api/teacher_marks_api.php?action=get_students&class_id=$_selectedClassId&subject_id=$_selectedSubjectId&term=$_selectedTerm&exam_type=$_selectedExamType&user_id=$_userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _students = data['students'];
            _isALevel = data['is_alevel'] == true;
            _currentSubjectName = data['subject_name'] ?? '';
            _isSubsidiary = data['is_subsidiary'] == true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

    Future<void> _saveMarks() async {
    setState(() => _isLoading = true);
    
    final marks = [];
    for (int i = 0; i < _students.length; i++) {
      final student = _students[i];
      final percentage = student['percentage'] ?? 0;
      marks.add({
        'student_id': student['student_id'],
        'percentage': percentage,
      });
    }
    
    if (marks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No marks to save'))
      );
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final payload = {
        'subject_id': _selectedSubjectId,
        'class_id': _selectedClassId,
        'term': _selectedTerm,
        'exam_type': _selectedExamType,
        'marks': marks,
        'user_id': _userId
      };
      
      print('Saving marks: ${jsonEncode(payload)}');
      
      final response = await http.post(
        Uri.parse('http://localhost/sms_api/teacher_marks_api.php?action=save_marks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved ${data['saved']} marks successfully!'))
          );
          await _loadStudents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Error saving marks'))
          );
        }
      }
    } catch (e) {
      print('Error saving marks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
    
    setState(() => _isLoading = false);
  }

  void _updateStudentMark(int index, double value) {
    setState(() {
      _students[index]['percentage'] = value;
      _calculateGrade(index);
    });
  }

  void _calculateGrade(int index) {
    final percentage = _students[index]['percentage'] ?? 0;
    String grade = 'F';
    int points = 0;

    if (_isALevel && !_isSubsidiary) {
      if (percentage >= 80) {
        grade = 'A';
        points = 6;
      } else if (percentage >= 70) {
        grade = 'B+';
        points = 5;
      } else if (percentage >= 60) {
        grade = 'B';
        points = 4;
      } else if (percentage >= 50) {
        grade = 'C';
        points = 3;
      } else if (percentage >= 40) {
        grade = 'D';
        points = 2;
      } else if (percentage >= 30) {
        grade = 'E';
        points = 1;
      } else {
        grade = 'F';
        points = 0;
      }
    } else if (_isALevel && _isSubsidiary) {
      if (percentage >= 40) {
        grade = 'P';
        points = 1;
      } else {
        grade = 'F';
        points = 0;
      }
    } else {
      if (percentage >= 80) {
        grade = 'A';
      } else if (percentage >= 70)
        grade = 'B+';
      else if (percentage >= 60)
        grade = 'B';
      else if (percentage >= 50)
        grade = 'C';
      else if (percentage >= 40)
        grade = 'D';
      else
        grade = 'F';
    }

    setState(() {
      _students[index]['grade'] = grade;
      if (_isALevel) {
        _students[index]['points'] = points;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Marks'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Select Class'),
              initialValue: _selectedClassId,
              items: _classes.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['class_id'],
                  child: Text('${c['class_name']} ${c['stream']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  _selectedSubjectId = null;
                  _students = [];
                });
                _loadSubjects();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Select Subject'),
              initialValue: _selectedSubjectId,
              items: _subjects.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem<int>(
                  value: s['subject_id'],
                  child: Text(s['subject_name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubjectId = value;
                  _students = [];
                });
                _loadStudents();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Exam Type'),
                    initialValue: _selectedExamType,
                    items: const [
                      DropdownMenuItem(value: 'BOT', child: Text('BOT')),
                      DropdownMenuItem(value: 'MOT', child: Text('MOT')),
                      DropdownMenuItem(value: 'EOT', child: Text('EOT')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedExamType = value!;
                        _students = [];
                      });
                      if (_selectedSubjectId != null) _loadStudents();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Term'),
                    initialValue: _selectedTerm,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Term 1')),
                      DropdownMenuItem(value: 2, child: Text('Term 2')),
                      DropdownMenuItem(value: 3, child: Text('Term 3')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTerm = value!;
                        _students = [];
                      });
                      if (_selectedSubjectId != null) _loadStudents();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isALevel)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      'A-LEVEL POINTS SYSTEM',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_isSubsidiary)
                      Text(
                        'Subsidiary: 1 point if passed',
                        style: TextStyle(
                            color: Colors.orange.shade700, fontSize: 12),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Expanded(
                      flex: 2,
                      child: Text('Student',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  const Expanded(
                      flex: 1,
                      child: Text('Score %',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  const Expanded(
                      flex: 1,
                      child: Text('Grade',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  if (_isALevel)
                    const Expanded(
                        flex: 1,
                        child: Text('Points',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const Center(
                          child: Text(
                              'No students found. Select a class and subject first.'))
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(student['name'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500)),
                                          Text(student['admission_no'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: SizedBox(
                                        width: 70,
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: student['percentage']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Score',
                                            suffixText: '%',
                                          ),
                                          onChanged: (value) {
                                            final double val =
                                                double.tryParse(value) ?? 0;
                                            _updateStudentMark(index, val);
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getGradeColor(
                                                student['grade'] ?? 'F'),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            student['grade'] ?? '-',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_isALevel)
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            student['points']?.toString() ??
                                                '-',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),
            if (_students.isNotEmpty)
              ElevatedButton(
                onPressed: _saveMarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text('Save Marks', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B+':
        return Colors.lightGreen;
      case 'B':
        return Colors.lightGreen.shade700;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'E':
        return Colors.orange.shade300;
      case 'P':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
}






