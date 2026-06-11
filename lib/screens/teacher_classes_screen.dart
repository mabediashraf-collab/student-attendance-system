import 'package:flutter/material.dart';

class TeacherClassesScreen extends StatelessWidget {
  final int teacherId;
  const TeacherClassesScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Classes'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: const Center(child: Text('Teacher classes coming soon')),
    );
  }
}
