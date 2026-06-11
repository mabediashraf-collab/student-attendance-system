import 'package:flutter/material.dart';

class EnterMarksScreen extends StatelessWidget {
  final int classId;
  final int subjectId;
  final String subjectName;
  const EnterMarksScreen({super.key, required this.classId, required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Marks - $subjectName'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: const Center(child: Text('Enter marks feature coming soon')),
    );
  }
}
