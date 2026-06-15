import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config/app_config.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedReportType = 0;
  List classes = [];
  List teachers = [];
  int? selectedClassId;
  int? selectedTeacherId;
  String? selectedDate;
  List reportData = [];
  bool isLoading = false;

  final List<String> _reportTypes = [
    'Attendance Report',
    'Student Results Report'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadClasses();
    await _loadTeachers();
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
            'class_name': cls['class_name'].toString(),
            'stream': cls['stream'].toString()
          };
        }).toList();
      });
    }
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

  Future<void> _generateReport() async {
    if (_selectedReportType == 0 &&
        selectedClassId == null &&
        selectedTeacherId == null &&
        selectedDate == null) {
      Fluttertoast.showToast(msg: 'Please select at least one filter');
      return;
    }
    if (_selectedReportType == 1 && selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select a class for results report');
      return;
    }

    setState(() => isLoading = true);

    if (_selectedReportType == 0) {
      await _generateAttendanceReport();
    } else {
      await _generateResultsReport();
    }

    setState(() => isLoading = false);
  }

  Future<void> _generateAttendanceReport() async {
    String url =
        '${AppConfig.apiBaseUrl}/attendance/get_attendance_records.php?';
    List<String> params = [];
    if (selectedClassId != null) params.add('class_id=$selectedClassId');
    if (selectedTeacherId != null) params.add('teacher_id=$selectedTeacherId');
    if (selectedDate != null && selectedDate!.isNotEmpty) {
      params.add('date=$selectedDate');
    }
    url += params.join('&');

    final response = await http.get(Uri.parse(url));
    final result = jsonDecode(response.body);

    if (result['success'] == true) {
      setState(() {
        reportData = result['attendance'] ?? [];
      });
    } else {
      Fluttertoast.showToast(msg: 'Failed to load attendance report');
    }
  }

  Future<void> _generateResultsReport() async {
    if (selectedClassId == null) return;

    final response = await http.get(Uri.parse(
        '${AppConfig.apiBaseUrl}/marks/get_class_results.php?class_id=$selectedClassId&term=1'));
    final result = jsonDecode(response.body);

    if (result['success'] == true) {
      setState(() {
        reportData = result['results'] ?? [];
      });
    } else {
      Fluttertoast.showToast(msg: 'Failed to load results report');
    }
  }

  void _showPrintPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _reportTypes[_selectedReportType],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Generated: ${DateTime.now().toString().split(' ')[0]}'),
                      const SizedBox(height: 16),
                      if (reportData.isEmpty)
                        const Text('No data available')
                      else if (_selectedReportType == 0)
                        ...reportData.map((record) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title:
                                    Text(record['student_name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Class: ${record['class_name']} ${record['stream']}'),
                                    Text(
                                        'Date: ${record['attendance_date']} (${record['attendance_session']})'),
                                    Text('Status: ${record['status']}'),
                                    Text('Teacher: ${record['teacher_name']}'),
                                  ],
                                ),
                              ),
                            ))
                      else
                        ...reportData.map((student) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(student['student_name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Admission: ${student['admission_no'] ?? 'N/A'}'),
                                    Text(
                                        'Overall Average: ${student['overall_average']}%'),
                                    Text(
                                        'Overall Grade: ${student['overall_grade']}'),
                                    const SizedBox(height: 8),
                                    const Text('Subjects:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    ...student['subjects'].map((s) => Text(
                                        '  ${s['subject_name']}: ${s['total']}% (${s['grade']})')),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.green.shade700,
        actions: [
          if (reportData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _showPrintPreview,
              tooltip: 'Preview Report',
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
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                            value: 0, label: Text('Attendance Report')),
                        ButtonSegment(value: 1, label: Text('Student Results')),
                      ],
                      selected: {_selectedReportType},
                      onSelectionChanged: (Set<int> selection) {
                        setState(() {
                          _selectedReportType = selection.first;
                          reportData = [];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedReportType == 0) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedClassId,
                        decoration:
                            const InputDecoration(labelText: 'Filter by Class'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Classes')),
                          ...classes.map((cls) => DropdownMenuItem<int>(
                                value: cls['class_id'],
                                child: Text(
                                    '${cls['class_name']} ${cls['stream']}'),
                              )),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedClassId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedTeacherId,
                        decoration: const InputDecoration(
                            labelText: 'Filter by Teacher'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Teachers')),
                          ...teachers.map((teacher) => DropdownMenuItem<int>(
                                value: teacher['user_id'],
                                child: Text(teacher['full_name']),
                              )),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedTeacherId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                            labelText: 'Filter by Date',
                            border: OutlineInputBorder()),
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
                    ],
                    if (_selectedReportType == 1) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedClassId,
                        decoration:
                            const InputDecoration(labelText: 'Select Class'),
                        items: classes
                            .map((cls) => DropdownMenuItem<int>(
                                  value: cls['class_id'],
                                  child: Text(
                                      '${cls['class_name']} ${cls['stream']}'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedClassId = value),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Generate Report'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reportData.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_reportTypes[_selectedReportType],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.print),
                            onPressed: _showPrintPreview,
                            tooltip: 'Preview Report',
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_selectedReportType == 0)
                        ...reportData.map((record) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title:
                                    Text(record['student_name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Class: ${record['class_name']} ${record['stream']}'),
                                    Text(
                                        'Date: ${record['attendance_date']} (${record['attendance_session']})'),
                                    Text('Status: ${record['status']}'),
                                    Text('Teacher: ${record['teacher_name']}'),
                                  ],
                                ),
                              ),
                            ))
                      else
                        ...reportData.map((student) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(student['student_name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Admission: ${student['admission_no'] ?? 'N/A'}'),
                                    Text(
                                        'Overall Average: ${student['overall_average']}%'),
                                    Text(
                                        'Overall Grade: ${student['overall_grade']}'),
                                    const SizedBox(height: 8),
                                    const Text('Subjects:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    ...student['subjects'].map((s) => Text(
                                        '  ${s['subject_name']}: ${s['total']}% (${s['grade']})')),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
