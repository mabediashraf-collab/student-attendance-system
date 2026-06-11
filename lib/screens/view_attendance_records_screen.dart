import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class ViewAttendanceRecordsScreen extends StatefulWidget {
  const ViewAttendanceRecordsScreen({super.key});

  @override
  State<ViewAttendanceRecordsScreen> createState() =>
      _ViewAttendanceRecordsScreenState();
}

class _ViewAttendanceRecordsScreenState
    extends State<ViewAttendanceRecordsScreen> {
  List classes = [];
  List attendanceRecords = [];
  String? selectedClassId;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    setState(() => isLoading = true);
    final result = await ApiService.getClasses();
    if (result['success'] == true) {
      setState(() {
        classes = result['classes'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadAttendanceRecords() async {
    if (selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Select a class first');
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.getAttendanceList(
      int.parse(selectedClassId!),
      selectedDate.toString().split(' ')[0],
    );

    if (result['success'] == true) {
      setState(() {
        attendanceRecords = result['attendance'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: result['message'] ?? 'No records found');
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Attendance Records'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
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
                      decoration:
                          const InputDecoration(labelText: 'Select Class'),
                      items: classes.map((cls) {
                        return DropdownMenuItem(
                          value: cls['class_id'].toString(),
                          child: Text(
                              '${cls['class_name']} ${cls['stream'] ?? ''}'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedClassId = value),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Select Date'),
                      subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadAttendanceRecords,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('View Records'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Attendance Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceRecords.isEmpty
                      ? const Center(child: Text('No attendance records found'))
                      : ListView.builder(
                          itemCount: attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = attendanceRecords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      getStatusColor(record['status'])
                                          .withOpacity(0.2),
                                  child: Icon(
                                    record['status'] == 'present'
                                        ? Icons.check
                                        : record['status'] == 'late'
                                            ? Icons.access_time
                                            : Icons.close,
                                    color: getStatusColor(record['status']),
                                  ),
                                ),
                                title:
                                    Text(record['student_name'] ?? 'Unknown'),
                                subtitle: Text(
                                    'Admission: ${record['admission_no'] ?? 'N/A'}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(record['status']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    record['status']?.toUpperCase() ??
                                        'UNKNOWN',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
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
