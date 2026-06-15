import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _staffNoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  
  File? _photoFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      var userRequest = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost/sms_api/users/register.php'),
      );
      userRequest.fields['email'] = _emailController.text;
      userRequest.fields['password'] = _passwordController.text;
      userRequest.fields['role'] = 'teacher';
      
      var userResponse = await userRequest.send();
      var userData = jsonDecode(await userResponse.stream.bytesToString());
      
      if (userData['success'] == true) {
        int userId = userData['user_id'];
        
        var teacherRequest = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost/sms_api/teachers/add_teacher.php'),
        );
        teacherRequest.fields['user_id'] = userId.toString();
        teacherRequest.fields['full_name'] = _fullNameController.text;
        teacherRequest.fields['staff_no'] = _staffNoController.text;
        teacherRequest.fields['phone'] = _phoneController.text;
        teacherRequest.fields['address'] = _addressController.text;
        teacherRequest.fields['gender'] = _genderController.text;
        teacherRequest.fields['nationality'] = _nationalityController.text;
        
        if (_photoFile != null) {
          teacherRequest.files.add(await http.MultipartFile.fromPath('photo', _photoFile!.path));
        }
        
        var teacherResponse = await teacherRequest.send();
        var teacherData = jsonDecode(await teacherResponse.stream.bytesToString());
        
        if (teacherData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher registered successfully!')),
          );
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(teacherData['message'] ?? 'Failed to add teacher details')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userData['message'] ?? 'Failed to create user account')),
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
    _fullNameController.clear();
    _staffNoController.clear();
    _phoneController.clear();
    _addressController.clear();
    _genderController.clear();
    _nationalityController.clear();
    setState(() => _photoFile = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher', style: TextStyle(color: Colors.white)),
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
                  backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                  child: _photoFile == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Tap to upload photo', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Email required' : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Password required' : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Full name required' : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _staffNoController,
                decoration: const InputDecoration(labelText: 'Staff Number', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Staff number required' : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: 'Gender (Male/Female)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(labelText: 'Nationality', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register Teacher', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
