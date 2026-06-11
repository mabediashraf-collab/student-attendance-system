import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  List subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getSubjects();
      print('Subjects loaded: $result');
      if (result['success'] == true) {
        subjects = result['subjects'] ?? [];
      }
    } catch (e) {
      print('Error loading subjects: $e');
      Fluttertoast.showToast(msg: 'Error loading subjects');
    }
    setState(() => isLoading = false);
  }

  Future<void> _addSubject() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                    labelText: 'Subject Code', hintText: 'MAT101'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Subject Name', hintText: 'Mathematics'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (codeController.text.isEmpty || nameController.text.isEmpty) {
        Fluttertoast.showToast(msg: 'Subject code and name required');
        return;
      }

      setState(() => isLoading = true);

      final addResult = await ApiService.addNewSubject(
        codeController.text,
        nameController.text,
        '', // description not used
      );

      if (addResult['success'] == true) {
        Fluttertoast.showToast(msg: 'Subject added successfully');
        await loadSubjects();
      } else {
        Fluttertoast.showToast(
            msg: addResult['message'] ?? 'Failed to add subject');
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: _addSubject,
            tooltip: 'Add Subject',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: loadSubjects,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subjects.isEmpty
              ? const Center(child: Text('No subjects found. Tap + to add.'))
              : ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.book,
                              size: 20, color: Colors.blue),
                        ),
                        title: Text(subject['subject_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text('Code: ${subject['subject_code']}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.edit, size: 18),
                      ),
                    );
                  },
                ),
    );
  }
}
