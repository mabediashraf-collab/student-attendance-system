import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class GradingSystemScreen extends StatefulWidget {
  const GradingSystemScreen({super.key});

  @override
  State<GradingSystemScreen> createState() => _GradingSystemScreenState();
}

class _GradingSystemScreenState extends State<GradingSystemScreen> {
  List grades = [];
  bool isLoading = true;
  
  final _formKey = GlobalKey<FormState>();
  final _gradeNameController = TextEditingController();
  final _minScoreController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => isLoading = true);
    final result = await ApiService.getGradingSystem();
    if (result['success'] == true) {
      setState(() {
        grades = result['grades'] ?? [];
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _addGrade() async {
    if (_formKey.currentState!.validate()) {
      final result = await ApiService.addGrade(
        _gradeNameController.text,
        double.parse(_minScoreController.text),
        double.parse(_maxScoreController.text),
        _remarksController.text,
      );
      
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: 'Grade added successfully');
        _gradeNameController.clear();
        _minScoreController.clear();
        _maxScoreController.clear();
        _remarksController.clear();
        _loadGrades();
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Failed to add grade');
      }
    }
  }

  Future<void> _deleteGrade(int gradeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grade'),
        content: const Text('Are you sure you want to delete this grade band?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    
    if (confirm == true) {
      final result = await ApiService.deleteGrade(gradeId);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: 'Grade deleted successfully');
        _loadGrades();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Failed to delete grade');
      }
    }
  }

  void _showAddGradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grade Band'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _gradeNameController,
                  decoration: const InputDecoration(labelText: 'Grade (e.g., A, B+, B)'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minScoreController,
                  decoration: const InputDecoration(labelText: 'Minimum Score (%)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxScoreController,
                  decoration: const InputDecoration(labelText: 'Maximum Score (%)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks (e.g., Excellent, Good)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addGrade, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grading System'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGradeDialog,
            tooltip: 'Add Grade',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGrades,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGradeDialog,
        tooltip: 'Add Grade',
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : grades.isEmpty
              ? const Center(child: Text('No grading bands configured'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grades.length,
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            grade['grade_name'] ?? '?',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ),
                        title: Text('${grade['grade_name']} (${grade['min_score']}% - ${grade['max_score']}%)'),
                        subtitle: Text(grade['remarks'] ?? 'No remarks'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGrade(grade['grade_id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}