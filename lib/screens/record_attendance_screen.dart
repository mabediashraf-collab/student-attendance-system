import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class RecordAttendanceScreen extends StatefulWidget {
  const RecordAttendanceScreen({super.key});

  @override
  State<RecordAttendanceScreen> createState() => _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState extends State<RecordAttendanceScreen> {
  List<dynamic> _classes = [];
  int? _selectedClassId;
  List<dynamic> _students = [];
  final Map<int, String> _attendanceStatus = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedDate = DateTime.now().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final session = await ApiService.getUserSession();
    final teacherId = session?['user_id'] ?? 0;
    final result = await ApiService.getTeacherClassesForAttendance(teacherId);
    if (result['success'] == true) {
      setState(() {
        _classes = result['classes'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to load classes');
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    final result =
        await ApiService.getClassStudentsForAttendance(_selectedClassId!);
    if (result['success'] == true) {
      setState(() {
        _students = result['students'] ?? [];
        _attendanceStatus.clear();
        for (var student in _students) {
          _attendanceStatus[student['student_id']] = 'present';
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to load students');
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null) return;
    setState(() => _isSaving = true);
    final result = await ApiService.saveAttendance(
      classId: _selectedClassId!,
      date: _selectedDate,
      attendance: _attendanceStatus,
    );
    if (result['success'] == true) {
      Fluttertoast.showToast(
          msg: result['message'], backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to save',
          backgroundColor: Colors.red);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_students.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveAttendance),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selectedClassId,
                        decoration: const InputDecoration(
                            labelText: 'Select Class',
                            border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('-- Select Class --')),
                          ..._classes.map((cls) => DropdownMenuItem(
                              value: cls['class_id'],
                              child: Text(cls['class_name']))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClassId = value;
                            _students = [];
                          });
                          if (value != null) _loadStudents();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Date: '),
                          Expanded(
                            child: TextFormField(
                              initialValue: _selectedDate,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'Select Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate =
                                      picked.toString().split(' ')[0]);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Text('No students found in this class'))
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final studentId = student['student_id'];
                            final studentName =
                                student['student_name'] ?? 'Unknown';
                            final admissionNo = student['admission_no'] ?? '';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(studentName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(admissionNo,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildStatusButton(
                                            'Present', Colors.green, studentId),
                                        const SizedBox(width: 8),
                                        _buildStatusButton(
                                            'Absent', Colors.red, studentId),
                                        const SizedBox(width: 8),
                                        _buildStatusButton(
                                            'Late', Colors.orange, studentId),
                                      ],
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
      bottomNavigationBar: _students.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50)),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE ATTENDANCE',
                        style: TextStyle(fontSize: 16)),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusButton(String label, Color color, int studentId) {
    final isSelected = _attendanceStatus[studentId] == label.toLowerCase();
    return ElevatedButton(
      onPressed: () =>
          setState(() => _attendanceStatus[studentId] = label.toLowerCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(70, 35),
      ),
      child: Text(label),
    );
  }
}
