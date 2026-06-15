import 'package:flutter/material.dart';
import 'services/grading_service.dart';

class GradingTab extends StatefulWidget {
  const GradingTab({super.key});

  @override
  State<GradingTab> createState() => _GradingTabState();
}

class _GradingTabState extends State<GradingTab> {
  List<Map<String, dynamic>> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
    });
    
    final grades = await GradingService.getGrades();
    
    setState(() {
      _grades = grades;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_grades.isEmpty) {
      return const Center(
        child: Text('No grade bands found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _grades.length,
      itemBuilder: (context, index) {
        final grade = _grades[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              grade['grade'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${grade['min_mark'] ?? 0}% - ${grade['max_mark'] ?? 0}%',
            ),
            trailing: Chip(
              label: Text(grade['remarks'] ?? 'No remark'),
              backgroundColor: Colors.blue.shade100,
            ),
          ),
        );
      },
    );
  }
}
