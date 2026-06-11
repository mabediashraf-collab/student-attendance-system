import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _admissionNoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentContactController = TextEditingController();
  String _selectedGender = 'Male';
  int? _selectedClassId;
  List classes = [];
  bool _isLoading = false;

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

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate() && _selectedClassId != null) {
      setState(() => _isLoading = true);

      final result = await ApiService.addStudentFull(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _selectedGender,
        _nationalityController.text,
        _parentContactController.text,
        _admissionNoController.text,
        _selectedClassId,
        null,
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(msg: 'Student added successfully');
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
            msg: result['message'] ?? 'Failed to add student');
      }

      setState(() => _isLoading = false);
    } else if (_selectedClassId == null) {
      Fluttertoast.showToast(msg: 'Please select a class');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _admissionNoController,
                decoration: const InputDecoration(
                    labelText: 'Admission Number',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                    labelText: 'Nationality', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                    labelText: 'Gender', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedClassId,
                decoration: const InputDecoration(
                    labelText: 'Select Class', border: OutlineInputBorder()),
                items: classes.map((cls) {
                  return DropdownMenuItem<int>(
                    value: cls['class_id'],
                    child: Text('${cls['class_name']} ${cls['stream']}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedClassId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                    labelText: 'Parent Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentContactController,
                decoration: const InputDecoration(
                    labelText: 'Parent Contact', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Student', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
