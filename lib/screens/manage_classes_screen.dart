import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  List classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getClasses();
      if (result['success'] == true) {
        setState(() {
          classes = result['classes'] ?? [];
          isLoading = false;
        });
        print('Loaded ${classes.length} classes');
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading classes: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: loadClasses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No classes found'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.class_,
                              size: 20, color: Colors.green),
                        ),
                        title: Text(
                          '${cls['class_name']} ${cls['stream'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Enrolled Students: ${cls['student_count'] ?? 0}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                        trailing: const Icon(Icons.arrow_forward, size: 18),
                      ),
                    );
                  },
                ),
    );
  }
}
