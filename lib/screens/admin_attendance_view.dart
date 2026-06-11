import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAttendanceView extends StatefulWidget {
  const AdminAttendanceView({super.key});

  @override
  State<AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends State<AdminAttendanceView> {
  List attendanceRecords = [];
  List teachers = [];
  List classes = [];
  bool isLoading = true;

  int? selectedTeacherId;
  int? selectedClassId;
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTeachers();
    _loadClasses();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await _loadAttendanceRecords();
    setState(() => isLoading = false);
  }

  Future<void> _loadTeachers() async {
    final result = await ApiService.getUsers();
    if (result['success'] == true) {
      List allUsers = result['users'] ?? [];
      setState(() {
        teachers = allUsers.where((u) => u['role'] == 'teacher').map((teacher) {
          return {
            'user_id': teacher['user_id'] is int
                ? teacher['user_id']
                : int.parse(teacher['user_id'].toString()),
            'full_name': teacher['full_name']?.toString() ??
                teacher['email']?.toString().split('@')[0] ??
                'Teacher',
            'email': teacher['email']?.toString() ?? ''
          };
        }).toList();
      });
    }
  }

  Future<void> _loadClasses() async {
    final result = await ApiService.getClasses();
    if (result['success'] == true) {
      List rawClasses = result['classes'] ?? [];
      setState(() {
        classes = rawClasses.map((cls) {
          return {
            'class_id': cls['class_id'] is int
                ? cls['class_id']
                : int.parse(cls['class_id'].toString()),
            'class_name': cls['class_name']?.toString() ?? '',
            'stream': cls['stream']?.toString() ?? ''
          };
        }).toList();
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    final result = await ApiService.getAttendanceRecords(
      teacherId: selectedTeacherId,
      classId: selectedClassId,
      date: selectedDate,
    );

    if (result['success'] == true) {
      setState(() {
        attendanceRecords = result['attendance'] ?? [];
      });
    }
  }

  void _applyFilters() {
    _loadAttendanceRecords();
  }

  void _resetFilters() {
    setState(() {
      selectedTeacherId = null;
      selectedClassId = null;
      selectedDate = null;
    });
    _loadAttendanceRecords();
  }

  // Group records by class and date
  Map<String, List<dynamic>> _groupRecords() {
    Map<String, List<dynamic>> grouped = {};
    for (var record in attendanceRecords) {
      String key =
          '${record['class_name']} ${record['stream']} - ${record['attendance_date']} (${record['attendance_session']})';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Attendance Records'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedTeacherId,
                      decoration:
                          const InputDecoration(labelText: 'Filter by Teacher'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Teachers')),
                        ...teachers.map((teacher) {
                          return DropdownMenuItem<int>(
                            value: teacher['user_id'],
                            child: Text(teacher['full_name']),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => selectedTeacherId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedClassId,
                      decoration:
                          const InputDecoration(labelText: 'Filter by Class'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Classes')),
                        ...classes.map((cls) {
                          return DropdownMenuItem<int>(
                            value: cls['class_id'],
                            child:
                                Text('${cls['class_name']} ${cls['stream']}'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => selectedClassId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Filter by Date',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: selectedDate),
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() =>
                              selectedDate = picked.toString().split(' ')[0]);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
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
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (attendanceRecords.isEmpty)
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Icon(Icons.history, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No attendance records found'),
                    Text('Try changing your filter criteria',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ..._groupRecords().entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      ...entry.value.map((record) {
                        bool isPresent = record['status'] == 'Present';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPresent
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isPresent ? Icons.check : Icons.close,
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            record['student_name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Admission: ${record['admission_no'] ?? 'N/A'}'),
                              if (selectedTeacherId == null)
                                Text('Teacher: ${record['teacher_name']}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record['status']?.toUpperCase() ?? 'ABSENT',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          isThreeLine: true,
                        );
                      }),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
