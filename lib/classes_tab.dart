import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassesTab extends StatefulWidget {
  const ClassesTab({super.key});

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/sms_api/get_classes.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _classes = data['classes'];
          });
        }
      }
    } catch (e) {
      print('Error loading classes: $e');
    }

    setState(() {
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

    if (_classes.isEmpty) {
      return const Center(
        child: Text('No classes found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classData = _classes[index];
        final studentCount = classData['student_count'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(classData['stream'] ?? '?'),
            ),
            title: Text(
              classData['full_name'] ??
                  '${classData['class_name']} ${classData['stream']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Academic Year: ${classData['academic_year'] ?? 'Not set'} • Students: $studentCount',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _editClass(classData),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteClass(classData),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editClass(Map<String, dynamic> classData) async {
    // Simple edit dialog
    final TextEditingController nameController = TextEditingController(
      text: classData['class_name'],
    );
    final TextEditingController streamController = TextEditingController(
      text: classData['stream'],
    );
    final TextEditingController yearController = TextEditingController(
      text: classData['academic_year'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${classData['full_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Class Name'),
            ),
            TextField(
              controller: streamController,
              decoration: const InputDecoration(labelText: 'Stream'),
            ),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(labelText: 'Academic Year'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse('http://localhost/sms_api/update_class.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'class_id': classData['class_id'],
                  'class_name': nameController.text,
                  'stream': streamController.text,
                  'academic_year': yearController.text,
                }),
              );
              if (response.statusCode == 200) {
                Navigator.pop(context);
                _loadClasses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(Map<String, dynamic> classData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete ${classData['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await http.delete(
        Uri.parse(
            'http://localhost/sms_api/delete_class.php?class_id=${classData['class_id']}'),
      );
      if (response.statusCode == 200) {
        _loadClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      }
    }
  }
}
