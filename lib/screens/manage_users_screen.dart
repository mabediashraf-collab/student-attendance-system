import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getUsers();
      if (result['success'] == true) {
        setState(() {
          users = result['users'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading users: $e');
      setState(() => isLoading = false);
    }
  }

  void _addUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
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
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                ],
                onChanged: (value) => selectedRole = value!,
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
              Navigator.pop(context);
              final result = await ApiService.addUser(
                nameController.text,
                emailController.text,
                passwordController.text,
                selectedRole,
                1,
              );
              if (result['success'] == true) {
                Fluttertoast.showToast(msg: 'User added successfully');
                loadUsers();
              } else {
                Fluttertoast.showToast(msg: result['message'] ?? 'Add failed');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['full_name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final admissionController =
        TextEditingController(text: user['admission_no'] ?? '');
    final staffController = TextEditingController(text: user['staff_no'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final addressController =
        TextEditingController(text: user['address'] ?? '');
    final nationalityController =
        TextEditingController(text: user['nationality'] ?? '');
    final parentNameController =
        TextEditingController(text: user['parent_name'] ?? '');
    final parentContactController =
        TextEditingController(text: user['parent_contact'] ?? '');
    final dobController =
        TextEditingController(text: user['date_of_birth'] ?? '');
    String selectedGender = user['gender'] ?? 'Male';
    List classes = [];
    String? selectedClassId = user['class_id']?.toString();

    if (user['role'] == 'student') {
      final classResult = await ApiService.getClasses();
      if (classResult['success'] == true) {
        classes = classResult['classes'] ?? [];
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${user['role']}'),
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
              if (user['role'] == 'student') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: admissionController,
                  decoration:
                      const InputDecoration(labelText: 'Admission Number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dobController,
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1980),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      dobController.text = picked.toString().split(' ')[0];
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: parentNameController,
                  decoration: const InputDecoration(labelText: 'Parent Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: parentContactController,
                  decoration:
                      const InputDecoration(labelText: 'Parent Contact'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Select Class')),
                    ...classes.map((cls) {
                      return DropdownMenuItem<String>(
                        value: cls['class_id'].toString(),
                        child: Text('${cls['class_name']} ${cls['stream']}'),
                      );
                    }),
                  ],
                  onChanged: (value) => selectedClassId = value,
                ),
              ],
              if (user['role'] == 'teacher') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: staffController,
                  decoration: const InputDecoration(labelText: 'Staff Number'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              int? classIdInt;
              if (selectedClassId != null && selectedClassId!.isNotEmpty) {
                classIdInt = int.tryParse(selectedClassId!);
              }

              final updateData = {
                'user_id': user['user_id'],
                'full_name': nameController.text,
                'email': emailController.text,
                'role': user['role'],
                'phone': phoneController.text,
                'address': addressController.text,
                'nationality': nationalityController.text,
                'gender': selectedGender,
                'admission_no': admissionController.text,
                'staff_no': staffController.text,
                'class_id': classIdInt,
                'date_of_birth': dobController.text,
                'parent_name': parentNameController.text,
                'parent_contact': parentContactController.text,
              };

              final updateResult = await ApiService.editUser(updateData);
              if (updateResult['success'] == true) {
                Fluttertoast.showToast(msg: 'User updated successfully');
                Navigator.pop(context);
                await loadUsers();
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user['full_name'] ?? user['email']}?'),
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
      final result = await ApiService.deleteUser(user['user_id']);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: 'User deleted successfully');
        loadUsers();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Delete failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addUser,
            tooltip: 'Add User',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            user['full_name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                            user['full_name'] ?? user['name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'No email'),
                            Text('Role: ${user['role'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 12)),
                            if (user['admission_no'] != null)
                              Text('Admission: ${user['admission_no']}',
                                  style: const TextStyle(fontSize: 12)),
                            if (user['staff_no'] != null)
                              Text('Staff No: ${user['staff_no']}',
                                  style: const TextStyle(fontSize: 12)),
                            if (user['phone'] != null &&
                                user['phone']!.isNotEmpty)
                              Text('Phone: ${user['phone']}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editUser(user),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
