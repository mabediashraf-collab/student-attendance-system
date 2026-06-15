import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _admissionNoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentContactController =
      TextEditingController();

  int? _selectedClassId;
  List<dynamic> _classes = [];
  File? _photoFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost/sms_api/classes/get_classes.php'));
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
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var userRequest = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost/sms_api/users/register.php'),
      );
      userRequest.fields['email'] = _emailController.text;
      userRequest.fields['password'] = _passwordController.text;
      userRequest.fields['role'] = 'student';

      var userResponse = await userRequest.send();
      var userData = jsonDecode(await userResponse.stream.bytesToString());

      if (userData['success'] == true) {
        int userId = userData['user_id'];

        var studentRequest = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost/sms_api/students/add_student.php'),
        );
        studentRequest.fields['user_id'] = userId.toString();
        studentRequest.fields['first_name'] = _firstNameController.text;
        studentRequest.fields['last_name'] = _lastNameController.text;
        studentRequest.fields['admission_no'] = _admissionNoController.text;
        studentRequest.fields['class_id'] = _selectedClassId.toString();
        studentRequest.fields['phone'] = _phoneController.text;
        studentRequest.fields['address'] = _addressController.text;
        studentRequest.fields['gender'] = _genderController.text;
        studentRequest.fields['date_of_birth'] = _dateOfBirthController.text;
        studentRequest.fields['nationality'] = _nationalityController.text;
        studentRequest.fields['parent_name'] = _parentNameController.text;
        studentRequest.fields['parent_phone'] = _parentPhoneController.text;
        studentRequest.fields['parent_contact'] = _parentContactController.text;

        if (_photoFile != null) {
          studentRequest.files.add(
              await http.MultipartFile.fromPath('photo', _photoFile!.path));
        }

        var studentResponse = await studentRequest.send();
        var studentData =
            jsonDecode(await studentResponse.stream.bytesToString());

        if (studentData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student registered successfully!')),
          );
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    studentData['message'] ?? 'Failed to add student details')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(userData['message'] ?? 'Failed to create user account')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _admissionNoController.clear();
    _phoneController.clear();
    _addressController.clear();
    _genderController.clear();
    _dateOfBirthController.clear();
    _nationalityController.clear();
    _parentNameController.clear();
    _parentPhoneController.clear();
    _parentContactController.clear();
    setState(() {
      _selectedClassId = null;
      _photoFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      _photoFile != null ? FileImage(_photoFile!) : null,
                  child: _photoFile == null
                      ? const Icon(Icons.camera_alt,
                          size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Tap to upload photo',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Email required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Password required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                          labelText: 'Last Name', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _admissionNoController,
                decoration: const InputDecoration(
                    labelText: 'Admission Number',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v!.isEmpty ? 'Admission number required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _selectedClassId,
                decoration: const InputDecoration(
                    labelText: 'Select Class', border: OutlineInputBorder()),
                items: _classes.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['class_id'] as int,
                    child: Text('${c['class_name']} ${c['stream']}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedClassId = value),
                validator: (v) => v == null ? 'Class required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(
                    labelText: 'Gender (Male/Female)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                    labelText: 'Nationality', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text('Parent/Guardian Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                    labelText: 'Parent Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _parentPhoneController,
                decoration: const InputDecoration(
                    labelText: 'Parent Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _parentContactController,
                decoration: const InputDecoration(
                    labelText: 'Parent Contact', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register Student',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
