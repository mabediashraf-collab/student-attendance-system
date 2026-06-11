import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/image_helper.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? studentData;
  List attendanceRecords = [];
  List marksRecords = [];
  int _currentIndex = 0;
  bool isLoading = true;

  final List<String> _tabs = ['Profile', 'Attendance', 'Results'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    print('Student user_id: $userId');

    if (userId != null) {
      final studentResult = await ApiService.getStudentDetails(userId);
      if (studentResult['success'] == true) {
        setState(() {
          studentData = studentResult['student'];
        });
      }

      final attendanceResult = await ApiService.getStudentAttendance(userId);
      if (attendanceResult['success'] == true) {
        setState(() {
          attendanceRecords = attendanceResult['attendance'] ?? [];
        });
      }

      // Load calculated results - using userId directly
      final resultsResult =
          await ApiService.getStudentCalculatedResults(userId, 1);
      print("Results API response: $resultsResult");

      if (resultsResult['success'] == true) {
        final subjects = resultsResult['subjects'] ?? [];
        print("Number of subjects: ${subjects.length}");

        List<dynamic> allMarks = [];
        for (var subject in subjects) {
          allMarks.add({
            'subject_name': subject['subject_name'],
            'subject_code': subject['subject_code'],
            'percentage': subject['percentage'],
            'grade': subject['grade'],
            'term': resultsResult['term'] ?? 1,
            'exam_type': 'Final',
            'bot': subject['bot'],
            'mot': subject['mot'],
            'eot': subject['eot'],
          });
        }
        setState(() {
          marksRecords = allMarks;
        });
        print("Loaded ${allMarks.length} subjects into marksRecords");
      } else {
        print("Failed to load results: ${resultsResult['message']}");
      }
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
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: _loadData,
              tooltip: "Refresh",
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
              onPressed: _logout,
              tooltip: "Logout",
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentIndex == 0
              ? _buildProfileTab()
              : _currentIndex == 1
                  ? _buildAttendanceTab()
                  : _buildResultsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.grade), label: 'Results'),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (studentData == null) {
      return const Center(child: Text('No profile data found'));
    }

    String firstName = studentData!['first_name'] ?? '';
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
                    backgroundImage: studentData!['photo'] != null &&
                            studentData!['photo']!.isNotEmpty
                        ? NetworkImage(
                            ImageHelper.getFullImageUrl(studentData!['photo']))
                        : null,
                    child: studentData!['photo'] == null ||
                            studentData!['photo']!.isEmpty
                        ? Text(firstLetter,
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${studentData!['first_name'] ?? ''} ${studentData!['last_name'] ?? ''}',
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
                      studentData!['class_name'] ?? 'No Class Assigned',
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
                  const Text('Personal Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow(Icons.email, 'Email',
                      studentData!['email'] ?? 'Not provided'),
                  _buildInfoRow(Icons.phone, 'Phone',
                      studentData!['phone'] ?? 'Not provided'),
                  _buildInfoRow(Icons.home, 'Address',
                      studentData!['address'] ?? 'Not provided'),
                  _buildInfoRow(Icons.cake, 'Date of Birth',
                      studentData!['date_of_birth'] ?? 'Not provided'),
                  _buildInfoRow(Icons.people, 'Gender',
                      studentData!['gender'] ?? 'Not provided'),
                  _buildInfoRow(Icons.public, 'Nationality',
                      studentData!['nationality'] ?? 'Not provided'),
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
                  const Text('Academic Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow(Icons.numbers, 'Admission Number',
                      studentData!['admission_no'] ?? 'Not assigned'),
                  _buildInfoRow(Icons.school, 'Class',
                      studentData!['class_name'] ?? 'Not enrolled'),
                  _buildInfoRow(Icons.class_, 'Stream',
                      studentData!['stream'] ?? 'Not assigned'),
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
                  const Text('Parent/Guardian Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow(Icons.person, 'Parent Name',
                      studentData!['parent_name'] ?? 'Not provided'),
                  _buildInfoRow(Icons.phone_android, 'Parent Contact',
                      studentData!['parent_contact'] ?? 'Not provided'),
                  _buildInfoRow(Icons.phone, 'Parent Phone',
                      studentData!['parent_phone'] ?? 'Not provided'),
                ],
              ),
            ),
          ),
        ],
      ),
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
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No Attendance Records',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Your attendance will appear here once recorded',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    int present = attendanceRecords
        .where((a) => a['status'] == 'present' || a['status'] == 'Present')
        .length;
    int absent = attendanceRecords
        .where((a) => a['status'] == 'absent' || a['status'] == 'Absent')
        .length;
    int total = attendanceRecords.length;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Present', present.toString(), Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _buildStatCard('Absent', absent.toString(), Colors.red)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Attendance',
                      '${percentage.toStringAsFixed(1)}%', Colors.blue)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              bool isPresent = record['status'] == 'present' ||
                  record['status'] == 'Present';
              String session = record['session'] ?? 'Morning';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isPresent ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(isPresent ? Icons.check : Icons.close,
                        color: isPresent ? Colors.green : Colors.red),
                  ),
                  title: Text(record['date'] ?? 'Unknown date',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Session: $session'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: isPresent ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(record['status']?.toUpperCase() ?? 'ABSENT',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    if (marksRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No Results Found',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Your marks will appear here once recorded by your teacher',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    // Group results by term
    Map<int, List<dynamic>> resultsByTerm = {};
    for (var result in marksRecords) {
      int term = result['term'] ?? 1;
      if (!resultsByTerm.containsKey(term)) {
        resultsByTerm[term] = [];
      }
      resultsByTerm[term]!.add(result);
    }

    List<int> terms = resultsByTerm.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: terms.length,
      itemBuilder: (context, termIndex) {
        int term = terms[termIndex];
        List termResults = resultsByTerm[term]!;

        double totalPercentage = 0;
        for (var result in termResults) {
          totalPercentage += result['percentage'] ?? 0;
        }
        double average =
            termResults.isNotEmpty ? totalPercentage / termResults.length : 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Term $term',
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text('Average: ${average.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: termResults.map((result) {
                    double percentage = result['percentage'] ?? 0;
                    String grade = result['grade'] ?? _getGrade(percentage);
                    Color gradeColor = _getGradeColor(percentage);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: gradeColor.withOpacity(0.2),
                        child: Text(
                            result['subject_code']?.substring(0, 2) ?? '?',
                            style: TextStyle(
                                color: gradeColor,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(result['subject_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(result['exam_type'] ?? 'Final Result'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: gradeColor,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(grade,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGrade(double percentage) {
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
