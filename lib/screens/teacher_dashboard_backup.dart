import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  String teacherName = '';
  Map<String, dynamic>? teacherData;

  List classes = [];
  List subjects = [];
  List students = [];
  List teacherClasses = [];

  int? selectedClassId;
  int? selectedSubjectId;
  String selectedExamType = 'CAT1';
  int selectedTerm = 1;
  String selectedDate = '';
  String selectedSession = 'Morning';

  Map<int, String> attendanceStatus = {};
  Map<int, double> marksValues = {};

  bool isLoading = true;

  final List<String> _tabs = [
    'Profile',
    'My Classes',
    'Attendance',
    'Enter Marks'
  ];

  String getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    selectedDate = DateTime.now().toString().split(' ')[0];
  }

  Future<void> _loadTeacherData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    teacherName = prefs.getString('name') ?? 'Teacher';

    if (userId != null) {
      final profileResult = await ApiService.getUserDetails(userId);
      if (profileResult['success'] == true) {
        setState(() {
          teacherData = profileResult['user'];
        });
      }
    }

    await _loadClasses();
    await _loadTeacherClasses();
    await _loadSubjects();

    setState(() => isLoading = false);
  }

  Future<void> _loadClasses() async {
    final prefs = await SharedPreferences.getInstance();
    int teacherId = prefs.getInt('user_id') ?? 35;

    final result = await ApiService.getTeacherClasses(teacherId);

    if (result['success'] == true) {
      List rawClasses = result['classes'] ?? [];
      setState(() {
        classes = rawClasses.map((cls) {
          int classId;
          if (cls['class_id'] is int) {
            classId = cls['class_id'];
          } else if (cls['class_id'] is String) {
            classId = int.parse(cls['class_id']);
          } else {
            classId = int.parse(cls['class_id'].toString());
          }
          return {
            'class_id': classId,
            'class_name': cls['class_name'],
            'stream': cls['stream']
          };
        }).toList();
      });
    }
  }

  Future<void> _loadTeacherClasses() async {
    final prefs = await SharedPreferences.getInstance();
    int teacherId = prefs.getInt('user_id') ?? 35;

    final result = await ApiService.getTeacherClasses(teacherId);

    if (result['success'] == true) {
      List rawClasses = result['classes'] ?? [];
      setState(() {
        teacherClasses = rawClasses.map((cls) {
          int classId;
          if (cls['class_id'] is int) {
            classId = cls['class_id'];
          } else if (cls['class_id'] is String) {
            classId = int.parse(cls['class_id']);
          } else {
            classId = int.parse(cls['class_id'].toString());
          }
          return {
            'class_id': classId,
            'class_name': cls['class_name'],
            'stream': cls['stream'],
            'student_count': cls['student_count'] ?? 0
          };
        }).toList();
      });
    }
  }

  Future<void> _loadSubjects() async {
    final result = await ApiService.getSubjects();

    if (result['success'] == true) {
      List rawSubjects = result['subjects'] ?? [];
      setState(() {
        subjects = rawSubjects.map((subj) {
          int subjectId;
          if (subj['subject_id'] is int) {
            subjectId = subj['subject_id'];
          } else if (subj['subject_id'] is String) {
            subjectId = int.parse(subj['subject_id']);
          } else {
            subjectId = int.parse(subj['subject_id'].toString());
          }
          return {
            'subject_id': subjectId,
            'subject_code': subj['subject_code'],
            'subject_name': subj['subject_name']
          };
        }).toList();
      });
    }
  }

  Future<void> _loadStudents() async {
    if (selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select a class first');
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.getStudentsByClass(selectedClassId!);
    if (result['success'] == true) {
      setState(() {
        students = result['students'] ?? [];
        for (var student in students) {
          int studentId = student['student_id'] is int
              ? student['student_id']
              : int.parse(student['student_id'].toString());
          attendanceStatus[studentId] = 'Present';
          marksValues[studentId] = 0;
        }
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveAttendance() async {
    if (selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select a class');
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.saveAttendance(
      selectedClassId!,
      selectedDate,
      selectedSession,
      attendanceStatus,
    );

    if (result['success'] == true) {
      Fluttertoast.showToast(
          msg: 'Attendance saved! Saved: ${result['saved']}');
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Failed');
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveMarks() async {
    if (selectedClassId == null || selectedSubjectId == null) {
      Fluttertoast.showToast(msg: 'Select class and subject');
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.saveMarks(
      selectedClassId!,
      selectedSubjectId!,
      selectedExamType,
      selectedTerm,
      marksValues,
    );

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Marks saved! Saved: ${result['saved']}');
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Failed');
    }

    setState(() => isLoading = false);
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ApiService.clearUserSession();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabs[_currentIndex],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeacherData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentIndex == 0
              ? _buildProfileTab()
              : _currentIndex == 1
                  ? _buildMyClassesTab()
                  : _currentIndex == 2
                      ? _buildAttendanceTab()
                      : _buildMarksTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.school), label: 'My Classes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Attendance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.edit_note), label: 'Enter Marks'),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (teacherData == null) {
      return const Center(child: Text('No profile data found'));
    }

    String firstName = teacherData!['full_name'] ?? teacherName;
    String firstLetter =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: teacherData!['photo'] != null &&
                            teacherData!['photo']!.isNotEmpty
                        ? NetworkImage(teacherData!['photo'])
                        : null,
                    child: teacherData!['photo'] == null ||
                            teacherData!['photo']!.isEmpty
                        ? Text(
                            firstLetter,
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    teacherData!['full_name'] ?? teacherName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teacherData!['role']?.toString().toUpperCase() ??
                          'TEACHER',
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(Icons.email, 'Email',
                      teacherData!['email'] ?? 'Not provided'),
                  _buildInfoRow(Icons.badge, 'Staff Number',
                      teacherData!['staff_no'] ?? 'Not assigned'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(Icons.school, 'Classes Assigned',
                      teacherClasses.length.toString()),
                  _buildInfoRow(Icons.book, 'Subjects Available',
                      subjects.length.toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyClassesTab() {
    if (teacherClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Classes Assigned',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'You have not been assigned to any classes yet',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teacherClasses.length,
      itemBuilder: (context, index) {
        final classItem = teacherClasses[index];
        int studentCount = classItem['student_count'] ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                classItem['class_name']?.substring(0, 1) ?? '?',
                style: TextStyle(
                    color: Colors.green.shade800, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${classItem['class_name']} ${classItem['stream']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class ID: ${classItem['class_id']}'),
                Text(
                  'Students Enrolled: $studentCount',
                  style: TextStyle(
                    color: studentCount > 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                selectedClassId = classItem['class_id'];
                _currentIndex = 2;
              });
              _loadStudents();
              Fluttertoast.showToast(
                  msg:
                      'Selected ${classItem['class_name']} ${classItem['stream']}');
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
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
                        const InputDecoration(labelText: 'Select Class'),
                    items: classes.map((cls) {
                      return DropdownMenuItem<int>(
                        value: cls['class_id'],
                        child: Text('${cls['class_name']} ${cls['stream']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedClassId = value);
                      _loadStudents();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Date'),
                    controller: TextEditingController(text: selectedDate),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() =>
                            selectedDate = picked.toString().split(' ')[0]);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSession,
                    decoration: const InputDecoration(labelText: 'Session'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Morning', child: Text('Morning')),
                      DropdownMenuItem(
                          value: 'Afternoon', child: Text('Afternoon')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedSession = value!),
                  ),
                  const SizedBox(height: 24),
                  if (students.isNotEmpty)
                    ElevatedButton(
                      onPressed: _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save Attendance',
                          style: TextStyle(fontSize: 16)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Students List',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...students.map((student) {
                      int studentId = student['student_id'] is int
                          ? student['student_id']
                          : int.parse(student['student_id'].toString());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                              child: Text(
                                  getFirstLetter(student['first_name'] ?? ''))),
                          title: Text(
                              '${student['first_name']} ${student['last_name']}'),
                          subtitle:
                              Text(student['admission_no'] ?? 'No admission'),
                          trailing: DropdownButton<String>(
                            value: attendanceStatus[studentId] ?? 'Present',
                            items: const [
                              DropdownMenuItem(
                                  value: 'Present',
                                  child: Text('Present',
                                      style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(
                                  value: 'Absent',
                                  child: Text('Absent',
                                      style: TextStyle(color: Colors.red))),
                              DropdownMenuItem(
                                  value: 'Late',
                                  child: Text('Late',
                                      style: TextStyle(color: Colors.orange))),
                            ],
                            onChanged: (value) => setState(
                                () => attendanceStatus[studentId] = value!),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarksTab() {
    return SingleChildScrollView(
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
                        const InputDecoration(labelText: 'Select Class'),
                    items: classes.map((cls) {
                      return DropdownMenuItem<int>(
                        value: cls['class_id'],
                        child: Text('${cls['class_name']} ${cls['stream']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedClassId = value);
                      _loadStudents();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubjectId,
                    decoration:
                        const InputDecoration(labelText: 'Select Subject'),
                    items: subjects.map((subj) {
                      return DropdownMenuItem<int>(
                        value: subj['subject_id'],
                        child: Text(subj['subject_name']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedSubjectId = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedExamType,
                    decoration: const InputDecoration(labelText: 'Exam Type'),
                    items: const [
                      DropdownMenuItem(value: 'CAT1', child: Text('CAT 1')),
                      DropdownMenuItem(value: 'CAT2', child: Text('CAT 2')),
                      DropdownMenuItem(
                          value: 'END_TERM', child: Text('End Term')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedExamType = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedTerm,
                    decoration: const InputDecoration(labelText: 'Term'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Term 1')),
                      DropdownMenuItem(value: 2, child: Text('Term 2')),
                      DropdownMenuItem(value: 3, child: Text('Term 3')),
                    ],
                    onChanged: (value) => setState(() => selectedTerm = value!),
                  ),
                  const SizedBox(height: 24),
                  if (students.isNotEmpty)
                    ElevatedButton(
                      onPressed: _saveMarks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save Marks',
                          style: TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (students.isNotEmpty && selectedSubjectId != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Marks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...students.map((student) {
                      int studentId = student['student_id'] is int
                          ? student['student_id']
                          : int.parse(student['student_id'].toString());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                              child: Text(
                                  getFirstLetter(student['first_name'] ?? ''))),
                          title: Text(
                              '${student['first_name']} ${student['last_name']}'),
                          subtitle:
                              Text(student['admission_no'] ?? 'No admission'),
                          trailing: SizedBox(
                            width: 100,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Marks',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                double marks = double.tryParse(value) ?? 0;
                                setState(() => marksValues[studentId] =
                                    marks.clamp(0, 100));
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
