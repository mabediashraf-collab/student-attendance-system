import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  List teachers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    setState(() => isLoading = true);
    final result = await ApiService.getUsers();
    if (result['success'] == true) {
      setState(() {
        teachers =
            result['users']?.where((u) => u['role'] == 'teacher').toList() ??
                [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editTeacher(Map<String, dynamic> teacher) async {
    final nameController =
        TextEditingController(text: teacher['full_name'] ?? '');
    final emailController = TextEditingController(text: teacher['email'] ?? '');
    final staffController =
        TextEditingController(text: teacher['staff_no'] ?? '');
    final phoneController = TextEditingController(text: teacher['phone'] ?? '');
    final addressController =
        TextEditingController(text: teacher['address'] ?? '');
    final nationalityController =
        TextEditingController(text: teacher['nationality'] ?? '');
    String selectedGender = teacher['gender'] ?? 'Male';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Teacher'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: staffController,
                decoration: const InputDecoration(labelText: 'Staff Number'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nationalityController,
                decoration: const InputDecoration(labelText: 'Nationality'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) => selectedGender = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updateData = {
                'user_id': teacher['user_id'],
                'full_name': nameController.text,
                'email': emailController.text,
                'role': 'teacher',
                'staff_no': staffController.text,
                'phone': phoneController.text,
                'address': addressController.text,
                'nationality': nationalityController.text,
                'gender': selectedGender,
              };

              final updateResult = await ApiService.editUser(updateData);
              if (updateResult['success'] == true) {
                Fluttertoast.showToast(msg: 'Teacher updated successfully');
                Navigator.pop(context);
                await loadTeachers();
              } else {
                Fluttertoast.showToast(
                    msg: updateResult['message'] ?? 'Update failed');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text(
            'Are you sure you want to delete ${teacher['full_name'] ?? teacher['email']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteUser(teacher['user_id']);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: 'Teacher deleted successfully');
        loadTeachers();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Delete failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadTeachers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : teachers.isEmpty
              ? const Center(child: Text('No teachers found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            teacher['full_name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(teacher['full_name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacher['email'] ?? 'No email'),
                            Text(
                                'Staff No: ${teacher['staff_no'] ?? 'Not assigned'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editTeacher(teacher),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTeacher(teacher),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-teacher')
              .then((_) => loadTeachers());
        },
        tooltip: 'Add Teacher',
        child: const Icon(Icons.add),
      ),
    );
  }
}

