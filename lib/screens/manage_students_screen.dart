import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() => isLoading = true);
    final result = await ApiService.getUsers();
    if (result['success'] == true) {
      setState(() {
        students =
            result['users']?.where((u) => u['role'] == 'student').toList() ??
                [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editStudent(Map<String, dynamic> student) async {
    final nameController =
        TextEditingController(text: student['full_name'] ?? '');
    final emailController = TextEditingController(text: student['email'] ?? '');
    final admissionController =
        TextEditingController(text: student['admission_no'] ?? '');
    final phoneController = TextEditingController(text: student['phone'] ?? '');
    final addressController =
        TextEditingController(text: student['address'] ?? '');
    final nationalityController =
        TextEditingController(text: student['nationality'] ?? '');
    final parentNameController =
        TextEditingController(text: student['parent_name'] ?? '');
    final parentContactController =
        TextEditingController(text: student['parent_contact'] ?? '');
    final dobController =
        TextEditingController(text: student['date_of_birth'] ?? '');
    String selectedGender = student['gender'] ?? 'Male';

    List classes = [];
    String? selectedClassId = student['class_id']?.toString();

    final classResult = await ApiService.getClasses();
    if (classResult['success'] == true) {
      classes = classResult['classes'] ?? [];
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
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
                controller: admissionController,
                decoration:
                    const InputDecoration(labelText: 'Admission Number'),
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
                decoration: const InputDecoration(labelText: 'Parent Contact'),
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
                'user_id': student['user_id'],
                'full_name': nameController.text,
                'email': emailController.text,
                'role': 'student',
                'phone': phoneController.text,
                'address': addressController.text,
                'nationality': nationalityController.text,
                'gender': selectedGender,
                'admission_no': admissionController.text,
                'class_id': classIdInt,
                'date_of_birth': dobController.text,
                'parent_name': parentNameController.text,
                'parent_contact': parentContactController.text,
              };

              final updateResult = await ApiService.editUser(updateData);
              if (updateResult['success'] == true) {
                Fluttertoast.showToast(msg: 'Student updated successfully');
                Navigator.pop(context);
                await loadStudents();
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

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
            'Are you sure you want to delete ${student['full_name'] ?? student['email']}?'),
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
      final result = await ApiService.deleteUser(student['user_id']);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: 'Student deleted successfully');
        loadStudents();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Delete failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadStudents,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            student['full_name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(student['full_name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['email'] ?? 'No email'),
                            Text(
                                'Admission: ${student['admission_no'] ?? 'Not assigned'}'),
                            if (student['class_name'] != null)
                              Text(
                                  'Class: ${student['class_name']} ${student['stream'] ?? ''}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editStudent(student),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStudent(student),
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
          Navigator.pushNamed(context, '/add-student')
              .then((_) => loadStudents());
        },
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
    );
  }
}
