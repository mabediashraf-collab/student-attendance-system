import 'dart:convert';
import 'package:http/http.dart' as http;

class GradingService {
  static const String baseUrl = 'http://localhost/sms_api';
  
  static Future<List<Map<String, dynamic>>> getGrades() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_grades.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['grades'] != null) {
          return List<Map<String, dynamic>>.from(data['grades']);
        }
      }
      return [];
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
