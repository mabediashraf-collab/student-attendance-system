import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config/app_config.dart';

class AdminResultsView extends StatefulWidget {
  const AdminResultsView({super.key});

  @override
  State<AdminResultsView> createState() => _AdminResultsViewState();
}

class _AdminResultsViewState extends State<AdminResultsView> {
  List results = [];
  List classes = [];
  bool isLoading = false;
  int? selectedClassId;
  int selectedTerm = 1;
  String? level;
  String? className;
  String? stream;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final result = await ApiService.getClasses();
    if (result['success'] == true) {
      setState(() {
        classes = result['classes'] ?? [];
      });
    }
  }

  Future<void> _loadResults() async {
    if (selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select a class');
      return;
    }

    setState(() => isLoading = true);

    final url =
        '${AppConfig.apiBaseUrl}/marks/get_class_results.php?class_id=$selectedClassId&term=$selectedTerm';
    final response = await http.get(Uri.parse(url));
    final result = jsonDecode(response.body);

    if (result['success'] == true) {
      setState(() {
        results = result['results'] ?? [];
        level = result['level'];
        className = result['class_name'];
        stream = result['stream'];
      });
    } else {
      Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to load results');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Results'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResults,
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
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTerm,
                      decoration: const InputDecoration(labelText: 'Term'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Term 1')),
                        DropdownMenuItem(value: 2, child: Text('Term 2')),
                        DropdownMenuItem(value: 3, child: Text('Term 3')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedTerm = value!);
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Load Results'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (selectedClassId == null)
              const Center(child: Text('Please select a class to view results'))
            else if (results.isEmpty)
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Icon(Icons.grade, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No results found for this class'),
                    Text('Please enter marks first',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.green.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Class: $className $stream',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Term: $selectedTerm',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Level: $level',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      border: TableBorder.all(),
                      columns: [
                        const DataColumn(
                            label: Text('Student Name',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(
                            label: Text('Admission',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        if (results.isNotEmpty &&
                            results.first['subjects'] != null)
                          ...results.first['subjects'].map((s) => DataColumn(
                              label: Text(s['subject_name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)))),
                        const DataColumn(
                            label: Text('Average',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(
                            label: Text('Grade',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: results.map((student) {
                        return DataRow(cells: [
                          DataCell(Text(student['student_name'])),
                          DataCell(Text(student['admission_no'] ?? 'N/A')),
                          ...student['subjects'].map((s) => DataCell(
                              Text('${s['total'].toStringAsFixed(1)}%'))),
                          DataCell(Text(
                              '${student['overall_average'].toStringAsFixed(1)}%')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGradeColor(student['overall_average']),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(student['overall_grade'],
                                style: const TextStyle(color: Colors.white)),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
