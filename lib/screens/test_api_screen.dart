import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestAPIScreen extends StatefulWidget {
  const TestAPIScreen({super.key});

  @override
  State<TestAPIScreen> createState() => _TestAPIScreenState();
}

class _TestAPIScreenState extends State<TestAPIScreen> {
  String result = "Press button to test API";
  bool loading = false;

  Future<void> testUsersAPI() async {
    setState(() {
      loading = true;
      result = "Testing Users API...";
    });

    try {
      final response = await http
          .get(Uri.parse('http://localhost/sms_api/users/get_users.php'));
      setState(() {
        result =
            "Users API Response:\nStatus: ${response.statusCode}\nBody: ${response.body}";
        loading = false;
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
        loading = false;
      });
    }
  }

  Future<void> testClassesAPI() async {
    setState(() {
      loading = true;
      result = "Testing Classes API...";
    });

    try {
      final response = await http
          .get(Uri.parse('http://localhost/sms_api/classes/get_classes.php'));
      setState(() {
        result =
            "Classes API Response:\nStatus: ${response.statusCode}\nBody: ${response.body}";
        loading = false;
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('API Test'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: testUsersAPI,
                    child: const Text('Test Users API'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: testClassesAPI,
                    child: const Text('Test Classes API'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
